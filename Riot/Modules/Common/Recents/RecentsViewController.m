/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 Copyright 2018 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "RecentsViewController.h"

#import "MXRoom+Riot.h"

#import <MatrixKit/MatrixKit.h>

#import "RoomViewController.h"

#import "RageShakeManager.h"
#import "RiotDesignValues.h"
#import "DesignValues.h"
#import "Analytics.h"
#import "LegacyAppDelegate.h"

#import "GeneratedInterface-Swift.h"

@interface RecentsViewController ()
{
    // Tell whether a recents refresh is pending (suspended during editing mode).
    BOOL isRefreshPending;
    
    // Observe UIApplicationDidEnterBackgroundNotification to cancel editing mode when app leaves the foreground state.
    id UIApplicationDidEnterBackgroundNotificationObserver;
    
    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
    id kAppDelegateDidTapStatusBarNotificationObserver;
    
    // Observe kMXNotificationCenterDidUpdateRules to update missed messages counts.
    id kMXNotificationCenterDidUpdateRulesObserver;
    
    MXHTTPOperation *currentRequest;
    
    // Observe kRiotDesignValuesDidChangeThemeNotification to handle user interface theme change.
    id kRiotDesignValuesDidChangeThemeNotificationObserver;
}

@end

@implementation RecentsViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([RecentsViewController class])
                          bundle:[NSBundle bundleForClass:[RecentsViewController class]]];
}

+ (instancetype)recentListViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([RecentsViewController class])
                                          bundle:[NSBundle bundleForClass:[RecentsViewController class]]];
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    // Set default screen name
    _screenName = @"RecentsScreen";
    
    // Remove the search option from the navigation bar.
    self.enableBarButtonSearch = NO;
    
    _enableDragging = NO;
    
    _enableStickyHeaders = NO;
    _stickyHeaderHeight = 30.0;    
    
    displayedSectionHeaders = [NSMutableArray array];
    
    // Set itself as delegate by default.
    self.delegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.recentsTableView.accessibilityIdentifier = @"RecentsVCTableView";
    
    // Register here the customized cell view class used to render recents
    [self.recentsTableView registerNib:RoomsDiscussionCell.nib forCellReuseIdentifier:RoomsDiscussionCell.defaultReuseIdentifier];
    [self.recentsTableView registerNib:RoomsRoomCell.nib forCellReuseIdentifier:RoomsRoomCell.defaultReuseIdentifier];
    [self.recentsTableView registerNib:RoomsInviteCell.nib forCellReuseIdentifier:RoomsInviteCell.defaultReuseIdentifier];
    
    // Hide line separators of empty cells
    self.recentsTableView.tableFooterView = [[UIView alloc] init];
    
    // Apply dragging settings
    self.enableDragging = _enableDragging;
    
    // Observe UIApplicationDidEnterBackgroundNotification to refresh bubbles when app leaves the foreground state.
    UIApplicationDidEnterBackgroundNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        // Leave potential editing mode
        [self cancelEditionMode:isRefreshPending];
        
    }];
    
    // Observe user interface theme change.
    kRiotDesignValuesDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kRiotDesignValuesDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    self.defaultBarTintColor = kRiotSecondaryBgColor;
    self.barTitleColor = kRiotPrimaryTextColor;
    self.activityIndicator.backgroundColor = kRiotOverlayColor;
    
    // Use the primary bg color for the recents table view in plain style.
    self.recentsTableView.backgroundColor = kRiotPrimaryBgColor;
    topview.backgroundColor = kRiotSecondaryBgColor;
    self.view.backgroundColor = kRiotPrimaryBgColor;
    
    if (self.recentsTableView.dataSource)
    {
        // Force table refresh
        [self cancelEditionMode:YES];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return kVariant1StatusBarStyle;
}

- (void)destroy
{
    [super destroy];
    
    if (currentRequest)
    {
        [currentRequest cancel];
        currentRequest = nil;
    }
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    if (UIApplicationDidEnterBackgroundNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationDidEnterBackgroundNotificationObserver];
        UIApplicationDidEnterBackgroundNotificationObserver = nil;
    }
    
    if (kRiotDesignValuesDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kRiotDesignValuesDidChangeThemeNotificationObserver];
        kRiotDesignValuesDidChangeThemeNotificationObserver = nil;
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    self.recentsTableView.editing = editing;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Screen tracking
    [[Analytics sharedInstance] trackScreen:_screenName];

    // Reset back user interactions
    self.userInteractionEnabled = YES;
    
    // Deselect the current selected row, it will be restored on viewDidAppear (if any)
    NSIndexPath *indexPath = [self.recentsTableView indexPathForSelectedRow];
    if (indexPath)
    {
        [self.recentsTableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    
    // Observe kAppDelegateDidTapStatusBarNotificationObserver.
    kAppDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self scrollToTop:YES];
        
    }];
    
    // Observe kMXNotificationCenterDidUpdateRules to refresh missed messages counts
    kMXNotificationCenterDidUpdateRulesObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXNotificationCenterDidUpdateRules object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        [self refreshRecentsTable];
        
    }];
    
    // Apply the current theme
    [self userInterfaceThemeDidChange];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Leave potential editing mode
    [self cancelEditionMode:NO];
    
    if (kAppDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateDidTapStatusBarNotificationObserver];
        kAppDelegateDidTapStatusBarNotificationObserver = nil;
    }
    
    if (kMXNotificationCenterDidUpdateRulesObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kMXNotificationCenterDidUpdateRulesObserver];
        kMXNotificationCenterDidUpdateRulesObserver = nil;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self refreshCurrentSelectedCell:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self refreshStickyHeadersContainersHeight];
        
    });
}

#pragma mark - Override MXKRecentListViewController

- (void)refreshRecentsTable
{
    isRefreshPending = NO;
    
    if (editedRoomId)
    {
        // Check whether the user didn't leave the room
        MXRoom *room = [self.mainSession roomWithRoomId:editedRoomId];
        if (room)
        {
            isRefreshPending = YES;
            return;
        }
        else
        {
            // Cancel the editing mode, a new refresh will be triggered.
            [self cancelEditionMode:YES];
            return;
        }
    }
    
    // Force reset existing sticky headers if any
    [self resetStickyHeaders];
    
    [self.recentsTableView reloadData];
    
    if (_shouldScrollToTopOnRefresh)
    {
        [self scrollToTop:NO];
        _shouldScrollToTopOnRefresh = NO;
    }
    
    [self prepareStickyHeaders];
    
    // In case of split view controller where the primary and secondary view controllers are displayed side-by-side on screen,
    // the selected room (if any) is updated.
    if (!self.splitViewController.isCollapsed)
    {
        [self refreshCurrentSelectedCell:NO];
    }
}

#pragma mark -

- (void)refreshCurrentSelectedCell:(BOOL)forceVisible
{
    NSIndexPath *indexPath = [self.recentsTableView indexPathForSelectedRow];
    if (indexPath)
    {
        [self.recentsTableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (void)cancelEditionMode:(BOOL)forceRefresh
{
    if (self.recentsTableView.isEditing || self.isEditing)
    {
        // Leave editing mode first
        isRefreshPending = forceRefresh;
        [self setEditing:NO];
    }
    else
    {
        // Clean
        editedRoomId = nil;
        
        if (forceRefresh)
        {
            [self refreshRecentsTable];
        }
    }
}

- (void)cancelEditionModeAndForceTableViewRefreshIfNeeded
{
    [self cancelEditionMode:isRefreshPending];
}

#pragma mark - Sticky Headers

- (void)setEnableStickyHeaders:(BOOL)enableStickyHeaders
{
    _enableStickyHeaders = enableStickyHeaders;
    
    // Refresh the table display if it is already rendered.
    if (self.recentsTableView.contentSize.height)
    {
        [self refreshRecentsTable];
    }
}

- (void)setStickyHeaderHeight:(CGFloat)stickyHeaderHeight
{
    if (_stickyHeaderHeight != stickyHeaderHeight)
    {
        _stickyHeaderHeight = stickyHeaderHeight;
        
        // Force a sticky headers refresh
        self.enableStickyHeaders = _enableStickyHeaders;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForStickyHeaderInSection:(NSInteger)section
{
    // Return the section header by default.
    return [self tableView:tableView viewForHeaderInSection:section];
}

- (void)resetStickyHeaders
{
    // Release sticky header
    _stickyHeadersTopContainerHeightConstraint.constant = 0;
    _stickyHeadersBottomContainerHeightConstraint.constant = 0;
    
    for (UIView *view in _stickyHeadersTopContainer.subviews)
    {
        [view removeFromSuperview];
    }
    for (UIView *view in _stickyHeadersBottomContainer.subviews)
    {
        [view removeFromSuperview];
    }
    
    [displayedSectionHeaders removeAllObjects];
    
    self.recentsTableView.contentInset = UIEdgeInsetsZero;
}

- (void)prepareStickyHeaders
{
    // We suppose here [resetStickyHeaders] has been already called if need.
    
    NSInteger sectionsCount = self.recentsTableView.numberOfSections;
    
    if (self.enableStickyHeaders && sectionsCount)
    {
        NSUInteger topContainerOffset = 0;
        NSUInteger bottomContainerOffset = 0;
        CGRect frame;
        
        UIView *stickyHeader = [self viewForStickyHeaderInSection:0 withSwipeGestureRecognizerInDirection:UISwipeGestureRecognizerDirectionDown];
        frame = stickyHeader.frame;
        frame.origin.y = topContainerOffset;
        stickyHeader.frame = frame;
        [self.stickyHeadersTopContainer addSubview:stickyHeader];
        topContainerOffset = stickyHeader.frame.size.height;
        
        for (NSUInteger index = 1; index < sectionsCount; index++)
        {
            stickyHeader = [self viewForStickyHeaderInSection:index withSwipeGestureRecognizerInDirection:UISwipeGestureRecognizerDirectionDown];
            frame = stickyHeader.frame;
            frame.origin.y = topContainerOffset;
            stickyHeader.frame = frame;
            [self.stickyHeadersTopContainer addSubview:stickyHeader];
            topContainerOffset += frame.size.height;
            
            stickyHeader = [self viewForStickyHeaderInSection:index withSwipeGestureRecognizerInDirection:UISwipeGestureRecognizerDirectionUp];
            frame = stickyHeader.frame;
            frame.origin.y = bottomContainerOffset;
            stickyHeader.frame = frame;
            [self.stickyHeadersBottomContainer addSubview:stickyHeader];
            bottomContainerOffset += frame.size.height;
        }
        
        [self refreshStickyHeadersContainersHeight];
    }
}

- (UIView *)viewForStickyHeaderInSection:(NSInteger)section withSwipeGestureRecognizerInDirection:(UISwipeGestureRecognizerDirection)swipeDirection
{
    UIView *stickyHeader = [self tableView:self.recentsTableView viewForStickyHeaderInSection:section];
    stickyHeader.tag = section;
    stickyHeader.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    // Remove existing gesture recognizers
    while (stickyHeader.gestureRecognizers.count)
    {
        UIGestureRecognizer *gestureRecognizer = stickyHeader.gestureRecognizers.lastObject;
        [stickyHeader removeGestureRecognizer:gestureRecognizer];
    }
    
    // Handle tap gesture, the section is moved up on the tap.
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnSectionHeader:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [stickyHeader addGestureRecognizer:tap];
    
    // Handle vertical swipe gesture with the provided direction, by default the section will be moved up on this swipe.
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeOnSectionHeader:)];
    [swipe setNumberOfTouchesRequired:1];
    [swipe setDirection:swipeDirection];
    [stickyHeader addGestureRecognizer:swipe];
    
    return stickyHeader;
}

- (void)didTapOnSectionHeader:(UIGestureRecognizer*)gestureRecognizer
{
    UIView *view = gestureRecognizer.view;
    NSInteger section = view.tag;
    
    // Scroll to the top of this section
    if ([self.recentsTableView numberOfRowsInSection:section] > 0)
    {
        [self.recentsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (void)didSwipeOnSectionHeader:(UISwipeGestureRecognizer*)gestureRecognizer
{
    UIView *view = gestureRecognizer.view;
    NSInteger section = view.tag;
    
    if ([self.recentsTableView numberOfRowsInSection:section] > 0)
    {
        // Check whether the first cell of this section is already visible.
        UITableViewCell *firstSectionCell = [self.recentsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
        if (firstSectionCell)
        {
            // Scroll to the top of the previous section (if any)
            if (section && [self.recentsTableView numberOfRowsInSection:(section - 1)] > 0)
            {
                [self.recentsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:(section - 1)] atScrollPosition:UITableViewScrollPositionTop animated:YES];
            }
        }
        else
        {
            // Scroll to the top of this section
            [self.recentsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    }
}

- (void)refreshStickyHeadersContainersHeight
{
    if (_enableStickyHeaders)
    {
        NSUInteger lowestSectionInBottomStickyHeader = NSNotFound;
        CGFloat containerHeight;
        
        // Retrieve the first header actually visible in the recents table view.
        // Caution: In some cases like the screen rotation, some displayed section headers are temporarily not visible.
        UIView *firstDisplayedSectionHeader;
        for (UIView *header in displayedSectionHeaders)
        {
            if (header.frame.origin.y + header.frame.size.height > self.recentsTableView.contentOffset.y)
            {
                firstDisplayedSectionHeader = header;
                break;
            }
        }
        
        if (firstDisplayedSectionHeader)
        {
            // Initialize the top container height by considering the headers which are before the first visible section header.
            containerHeight = 0;
            for (UIView *header in _stickyHeadersTopContainer.subviews)
            {
                if (header.tag < firstDisplayedSectionHeader.tag)
                {
                    containerHeight += self.stickyHeaderHeight;
                }
            }
            
            // Check whether the first visible section header is partially hidden.
            if (firstDisplayedSectionHeader.frame.origin.y < self.recentsTableView.contentOffset.y)
            {
                // Compute the height of the hidden part.
                CGFloat delta = self.recentsTableView.contentOffset.y - firstDisplayedSectionHeader.frame.origin.y;
                
                if (delta < self.stickyHeaderHeight)
                {
                    containerHeight += delta;
                }
                else
                {
                    containerHeight += self.stickyHeaderHeight;
                }
            }
            
            if (containerHeight)
            {
                self.stickyHeadersTopContainerHeightConstraint.constant = containerHeight;
                self.recentsTableView.contentInset = UIEdgeInsetsMake(-self.stickyHeaderHeight, 0, 0, 0);
            }
            else
            {
                self.stickyHeadersTopContainerHeightConstraint.constant = 0;
                self.recentsTableView.contentInset = UIEdgeInsetsZero;
            }
            
            // Look for the lowest section index visible in the bottom sticky headers.
            CGFloat maxVisiblePosY = self.recentsTableView.contentOffset.y + self.recentsTableView.frame.size.height - self.recentsTableView.mxk_adjustedContentInset.bottom;
            UIView *lastDisplayedSectionHeader = displayedSectionHeaders.lastObject;
            
            for (UIView *header in _stickyHeadersBottomContainer.subviews)
            {
                if (header.tag > lastDisplayedSectionHeader.tag)
                {
                    maxVisiblePosY -= self.stickyHeaderHeight;
                }
            }
            
            for (NSInteger index = displayedSectionHeaders.count; index > 0;)
            {
                lastDisplayedSectionHeader = displayedSectionHeaders[--index];
                if (lastDisplayedSectionHeader.frame.origin.y + self.stickyHeaderHeight > maxVisiblePosY)
                {
                    maxVisiblePosY -= self.stickyHeaderHeight;
                }
                else
                {
                    lowestSectionInBottomStickyHeader = lastDisplayedSectionHeader.tag + 1;
                    break;
                }
            }
        }
        else
        {
            // Handle here the case where no section header is currently displayed in the table.
            // No more than one section is then displayed, we retrieve this section by checking the first visible cell.
            NSIndexPath *firstCellIndexPath = [self.recentsTableView indexPathForRowAtPoint:CGPointMake(0, self.recentsTableView.contentOffset.y)];
            if (firstCellIndexPath)
            {
                NSInteger section = firstCellIndexPath.section;
                
                // Refresh top container of the sticky headers
                CGFloat containerHeight = 0;
                for (UIView *header in _stickyHeadersTopContainer.subviews)
                {
                    if (header.tag <= section)
                    {
                        containerHeight += header.frame.size.height;
                    }
                }
                
                self.stickyHeadersTopContainerHeightConstraint.constant = containerHeight;
                if (containerHeight)
                {
                    self.recentsTableView.contentInset = UIEdgeInsetsMake(-self.stickyHeaderHeight, 0, 0, 0);
                }
                else
                {
                    self.recentsTableView.contentInset = UIEdgeInsetsZero;
                }
                
                // Set the lowest section index visible in the bottom sticky headers.
                lowestSectionInBottomStickyHeader = section + 1;
            }
        }
        
        // Update here the height of the bottom container of the sticky headers thanks to lowestSectionInBottomStickyHeader.
        containerHeight = 0;
        CGRect bounds = _stickyHeadersBottomContainer.frame;
        bounds.origin.y = 0;
        
        for (UIView *header in _stickyHeadersBottomContainer.subviews)
        {
            if (header.tag > lowestSectionInBottomStickyHeader)
            {
                containerHeight += self.stickyHeaderHeight;
            }
            else if (header.tag == lowestSectionInBottomStickyHeader)
            {
                containerHeight += self.stickyHeaderHeight;
                bounds.origin.y = header.frame.origin.y;
            }
        }
        
        if (self.stickyHeadersBottomContainerHeightConstraint.constant != containerHeight)
        {
            self.stickyHeadersBottomContainerHeightConstraint.constant = containerHeight;
            self.stickyHeadersBottomContainer.bounds = bounds;
        }
    }
}

#pragma mark - Internal methods

// Disable UI interactions in this screen while we are going to open another screen.
// Interactions on reset on viewWillAppear.
- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled
{
    self.view.userInteractionEnabled = userInteractionEnabled;
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    id<MXKRecentCellDataStoring> cellDataStoring = (id<MXKRecentCellDataStoring> )cellData;
    
    if (cellDataStoring.roomSummary.room.summary.membership == MXMembershipInvite)
    {
        return RoomsInviteCell.class;
    }
    else if (cellDataStoring.roomSummary.isDirect)
    {
        return RoomsDiscussionCell.class;
    }
    else
    {
        return RoomsRoomCell.class;
    }
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    Class class = [self cellViewClassForCellData:cellData];
    
    if ([class respondsToSelector:@selector(defaultReuseIdentifier)])
    {
        return [class defaultReuseIdentifier];
    }
    
    return nil;
}

#pragma mark - Swipe actions

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray* actions = [[NSMutableArray alloc] init];
    MXRoom* room = [self.dataSource getRoomAtIndexPath:indexPath];
    
    if (room)
    {
        // Display no action for the invited room
        if (room.summary.membership == MXMembershipInvite)
        {
            return actions;
        }
        
        // Store the identifier of the room related to the edited cell.
        editedRoomId = room.roomId;
        
        NSString* title = @"      ";
        
        // Notification toggle
        BOOL isMuted = room.isMute || room.isMentionsOnly;
        
        UITableViewRowAction *muteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:title handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
            
            [self muteEditedRoomNotifications:!isMuted];
            
        }];
        
        UIImage *actionIcon = isMuted ? [UIImage imageNamed:@"notifications"] : [UIImage imageNamed:@"notificationsOff"];
        muteAction.backgroundColor = [MXKTools convertImageToPatternColor:isMuted ? @"notifications" : @"notificationsOff" backgroundColor:kRiotSecondaryBgColor patternSize:CGSizeMake(74, 74) resourceSize:actionIcon.size];
        [actions insertObject:muteAction atIndex:0];
        
        // Favorites management
        MXRoomTag* currentTag = nil;
        
        // Get the room tag (use only the first one).
        if (room.accountData.tags)
        {
            NSArray<MXRoomTag*>* tags = room.accountData.tags.allValues;
            if (tags.count)
            {
                currentTag = [tags objectAtIndex:0];
            }
        }
        
        if (currentTag && [kMXRoomTagFavourite isEqualToString:currentTag.name])
        {
            UITableViewRowAction* action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:title handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
                
                [self updateEditedRoomTag:nil];
                
            }];
            
            actionIcon = [UIImage imageNamed:@"unpin"];
            action.backgroundColor = [MXKTools convertImageToPatternColor:@"unpin" backgroundColor:kRiotSecondaryBgColor patternSize:CGSizeMake(74, 74) resourceSize:actionIcon.size];
            [actions insertObject:action atIndex:0];
        }
        else
        {
            UITableViewRowAction* action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:title handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
                
                [self updateEditedRoomTag:kMXRoomTagFavourite];
                
            }];
            
            actionIcon = [UIImage imageNamed:@"pin"];
            action.backgroundColor = [MXKTools convertImageToPatternColor:@"pin" backgroundColor:kRiotSecondaryBgColor patternSize:CGSizeMake(74, 74) resourceSize:actionIcon.size];
            [actions insertObject:action atIndex:0];
        }
        
        UITableViewRowAction *leaveAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:title  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
            
            [self leaveEditedRoom];
            
        }];
        
        actionIcon = [UIImage imageNamed:@"leave"];
        leaveAction.backgroundColor = [MXKTools convertImageToPatternColor:@"leave" backgroundColor:kRiotSecondaryBgColor patternSize:CGSizeMake(74, 74) resourceSize:actionIcon.size];
        
        [actions insertObject:leaveAction atIndex:0];
    }
    
    return actions;
}

- (void)tableView:(UITableView*)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self cancelEditionMode:isRefreshPending];
}

- (void)leaveEditedRoom
{
    if (editedRoomId)
    {
        MXRoom *room = [self.mainSession roomWithRoomId:editedRoomId];
        if (!room)
        {
            return;
        }
        
        NSString *currentRoomId = editedRoomId;
        
        [self startActivityIndicator];
        MXWeakify(self);
        
        [room tc_isCurrentUserLastAdministrator:^(BOOL isLastAdmin) {
            MXStrongifyAndReturnIfNil(self);
            [self stopActivityIndicator];
            
            // confirm leave
            NSString *promptMessage = NSLocalizedStringFromTable(@"room_participants_leave_prompt_msg", @"Vector", nil);
            if (isLastAdmin)
            {
                promptMessage = NSLocalizedStringFromTable(@"tchap_room_admin_leave_prompt_msg", @"Tchap", nil);
            }
            
            MXWeakify(self);
            self->currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"room_participants_leave_prompt_title", @"Vector", nil)
                                                                     message:promptMessage
                                                              preferredStyle:UIAlertControllerStyleAlert];
            
            [self->currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                                   style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction * action) {
                                                                     
                                                                     MXStrongifyAndReturnIfNil(self);
                                                                     self->currentAlert = nil;
                                                                     
                                                                 }]];
            
            [self->currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"leave", @"Vector", nil)
                                                                   style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                       
                                                                       MXStrongifyAndReturnIfNil(self);
                                                                       self->currentAlert = nil;
                                                                       
                                                                       // Check whether the user didn't leave the room yet
                                                                       // TODO: Handle multi-account
                                                                       MXRoom *room = [self.mainSession roomWithRoomId:currentRoomId];
                                                                       if (room)
                                                                       {
                                                                           [self startActivityIndicator];
                                                                           
                                                                           // cancel pending uploads/downloads
                                                                           // they are useless by now
                                                                           [MXMediaManager cancelDownloadsInCacheFolder:room.roomId];
                                                                           
                                                                           // TODO GFO cancel pending uploads related to this room
                                                                           
                                                                           NSLog(@"[RecentsViewController] Leave room (%@)", room.roomId);
                                                                           
                                                                           MXWeakify(self);
                                                                           [room leave:^{
                                                                               
                                                                               MXStrongifyAndReturnIfNil(self);
                                                                               [self stopActivityIndicator];
                                                                               // Force table refresh
                                                                               [self cancelEditionMode:YES];
                                                                               
                                                                           } failure:^(NSError *error) {
                                                                               
                                                                               NSLog(@"[RecentsViewController] Failed to leave room");
                                                                               MXStrongifyAndReturnIfNil(self);
                                                                               // Notify the end user
                                                                               NSString *userId = room.mxSession.myUser.userId;
                                                                               [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification
                                                                                                                                   object:error
                                                                                                                                 userInfo:userId ? @{kMXKErrorUserIdKey: userId} : nil];
                                                                               
                                                                               [self stopActivityIndicator];
                                                                               
                                                                               // Leave editing mode
                                                                               [self cancelEditionMode:self->isRefreshPending];
                                                                               
                                                                           }];
                                                                       }
                                                                       else
                                                                       {
                                                                           // Leave editing mode
                                                                           [self cancelEditionMode:self->isRefreshPending];
                                                                       }
                                                                       
                                                                   }]];
            
            [self->currentAlert mxk_setAccessibilityIdentifier:@"LeaveEditedRoomAlert"];
            [self presentViewController:self->currentAlert animated:YES completion:nil];
        }];
    }
}

- (void)updateEditedRoomTag:(NSString*)tag
{
    if (editedRoomId)
    {
        // Check whether the user didn't leave the room
        MXRoom *room = [self.mainSession roomWithRoomId:editedRoomId];
        if (room)
        {
            [self startActivityIndicator];
            
            [room setRoomTag:tag completion:^{
                
                [self stopActivityIndicator];
                
                // Force table refresh
                [self cancelEditionMode:YES];
                
            }];
        }
        else
        {
            // Leave editing mode
            [self cancelEditionMode:isRefreshPending];
        }
    }
}

- (void)muteEditedRoomNotifications:(BOOL)mute
{
    if (editedRoomId)
    {
        // Check whether the user didn't leave the room
        MXRoom *room = [self.mainSession roomWithRoomId:editedRoomId];
        if (room)
        {
            [self startActivityIndicator];
            
            if (mute)
            {
                [room mentionsOnly:^{
                    
                    [self stopActivityIndicator];
                    
                    // Leave editing mode
                    [self cancelEditionMode:isRefreshPending];
                    
                }];
            }
            else
            {
                [room allMessages:^{
                    
                    [self stopActivityIndicator];
                    
                    // Leave editing mode
                    [self cancelEditionMode:isRefreshPending];
                    
                }];
            }
        }
        else
        {
            // Leave editing mode
            [self cancelEditionMode:isRefreshPending];
        }
    }
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    cell.backgroundColor = kRiotPrimaryBgColor;
    
    // Update the selected background view
    if (kRiotSelectedBgColor)
    {
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = kRiotSelectedBgColor;
    }
    else
    {
        if (tableView.style == UITableViewStylePlain)
        {
            cell.selectedBackgroundView = nil;
        }
        else
        {
            cell.selectedBackgroundView.backgroundColor = nil;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *sectionHeader = [super tableView:tableView viewForHeaderInSection:section];
    sectionHeader.tag = section;
    
    while (sectionHeader.gestureRecognizers.count)
    {
        UIGestureRecognizer *gestureRecognizer = sectionHeader.gestureRecognizers.lastObject;
        [sectionHeader removeGestureRecognizer:gestureRecognizer];
    }
    
    // Handle tap gesture
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnSectionHeader:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [sectionHeader addGestureRecognizer:tap];
    
    return sectionHeader;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if (_enableStickyHeaders)
    {
        view.tag = section;
        
        UIView *firstDisplayedSectionHeader = displayedSectionHeaders.firstObject;
        
        if (!firstDisplayedSectionHeader || section < firstDisplayedSectionHeader.tag)
        {
            [displayedSectionHeaders insertObject:view atIndex:0];
        }
        else
        {
            [displayedSectionHeaders addObject:view];
        }
        
        [self refreshStickyHeadersContainersHeight];
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if (_enableStickyHeaders)
    {
        UIView *firstDisplayedSectionHeader = displayedSectionHeaders.firstObject;
        if (firstDisplayedSectionHeader)
        {
            if (section == firstDisplayedSectionHeader.tag)
            {
                [displayedSectionHeaders removeObjectAtIndex:0];
                
                [self refreshStickyHeadersContainersHeight];
            }
            else
            {
                // This section header is the last displayed one.
                // Add a sanity check in case of the header has been already removed.
                UIView *lastDisplayedSectionHeader = displayedSectionHeaders.lastObject;
                if (section == lastDisplayedSectionHeader.tag)
                {
                    [displayedSectionHeaders removeLastObject];
                    
                    [self refreshStickyHeadersContainersHeight];
                }
            }
        }
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self refreshStickyHeadersContainersHeight];
        
    });
    
    [super scrollViewDidScroll:scrollView];
}

#pragma mark - Table view scrolling

- (void)scrollToTop:(BOOL)animated
{
    [self.recentsTableView setContentOffset:CGPointMake(-self.recentsTableView.mxk_adjustedContentInset.left, -self.recentsTableView.mxk_adjustedContentInset.top) animated:animated];
}

- (void)scrollToTheTopTheNextRoomWithMissedNotificationsInSection:(NSInteger)section
{
    UITableViewCell *firstVisibleCell;
    NSIndexPath *firstVisibleCellIndexPath;
    
    UIView *firstSectionHeader = displayedSectionHeaders.firstObject;
    
    if (firstSectionHeader && firstSectionHeader.frame.origin.y <= self.recentsTableView.contentOffset.y)
    {
        // Compute the height of the hidden part of the section header.
        CGFloat hiddenPart = self.recentsTableView.contentOffset.y - firstSectionHeader.frame.origin.y;
        CGFloat firstVisibleCellPosY = self.recentsTableView.contentOffset.y + (firstSectionHeader.frame.size.height - hiddenPart);
        firstVisibleCellIndexPath = [self.recentsTableView indexPathForRowAtPoint:CGPointMake(0, firstVisibleCellPosY)];
        firstVisibleCell = [self.recentsTableView cellForRowAtIndexPath:firstVisibleCellIndexPath];
    }
    else
    {
        firstVisibleCell = self.recentsTableView.visibleCells.firstObject;
        firstVisibleCellIndexPath = [self.recentsTableView indexPathForCell:firstVisibleCell];
    }
    
    if (firstVisibleCell)
    {
        NSInteger nextCellRow = (firstVisibleCellIndexPath.section == section) ? firstVisibleCellIndexPath.row + 1 : 0;
        
        // Look for the next room with missed notifications.
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:nextCellRow inSection:section];
        nextCellRow++;
        id<MXKRecentCellDataStoring> cellData = [self.dataSource cellDataAtIndexPath:nextIndexPath];
        
        while (cellData)
        {
            if (cellData.notificationCount)
            {
                [self.recentsTableView scrollToRowAtIndexPath:nextIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
                break;
            }
            nextIndexPath = [NSIndexPath indexPathForRow:nextCellRow inSection:section];
            nextCellRow++;
            cellData = [self.dataSource cellDataAtIndexPath:nextIndexPath];
        }
        
        if (!cellData && [self.recentsTableView numberOfRowsInSection:section] > 0)
        {
            // Scroll back to the top.
            [self.recentsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    }
}

#pragma mark - MXKRecentListViewControllerDelegate

- (void)recentListViewController:(MXKRecentListViewController *)recentListViewController didSelectRoom:(NSString *)roomId inMatrixSession:(MXSession *)matrixSession
{
}

@end
