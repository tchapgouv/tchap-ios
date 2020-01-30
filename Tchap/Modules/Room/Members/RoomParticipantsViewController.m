/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 Copyright 2018-2020 New Vector Ltd
 
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

#import "RoomParticipantsViewController.h"

#import "RoomMemberDetailsViewController.h"

#import "GeneratedInterface-Swift.h"

#import "Contact.h"

#import "RageShakeManager.h"

#import "GeneratedInterface-Swift.h"

@interface RoomParticipantsViewController () <Stylable>
{
    // Search result
    NSString *currentSearchText;
    NSMutableArray<Contact*> *filteredActualParticipants;
    NSMutableArray<Contact*> *filteredInvitedParticipants;
    
    // Mask view while processing a request
    UIActivityIndicatorView *pendingMaskSpinnerView;
    
    // The members events listener.
    id membersListener;
    
    // Observe kMXSessionWillLeaveRoomNotification to be notified if the user leaves the current room.
    id leaveRoomNotificationObserver;
    
    // Observe kMXRoomDidFlushDataNotification to take into account the updated room members when the room history is flushed.
    id roomDidFlushDataNotificationObserver;
    
    RoomMemberDetailsViewController *memberDetailsViewController;
    
    // Contacts picker and its resources
    ContactsViewController *contactsPickerViewController;
    ContactsDataSource *contactsDataSource;
    UIBarButtonItem *validateBarButtonItem;
    
    // Tell whether the user is allowed to invite other users
    BOOL isUserAllowedToInvite;
    BOOL isUserAllowedToKick;
    
    // Display a gradient view above the screen.
    CAGradientLayer* tableViewMaskLayer;
    
    // Display a button to invite new member.
    UIImageView* addParticipantButtonImageView;
    NSLayoutConstraint *addParticipantButtonImageViewBottomConstraint;
    
    UIAlertController *currentAlert;
    
    // Observe kRiotDesignValuesDidChangeThemeNotification to handle user interface theme change.
    id kRiotDesignValuesDidChangeThemeNotificationObserver;
}

@property (nonatomic, strong) id<Style> currentStyle;
@property (nonatomic, nullable, strong) UserService *userService;

@end

@implementation RoomParticipantsViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([RoomParticipantsViewController class])
                          bundle:[NSBundle bundleForClass:[RoomParticipantsViewController class]]];
}

+ (instancetype)instantiate
{
    RoomParticipantsViewController *roomParticipantsViewController = [[[self class] alloc] initWithNibName:NSStringFromClass([RoomParticipantsViewController class])
                                          bundle:[NSBundle bundleForClass:[RoomParticipantsViewController class]]];
    roomParticipantsViewController.currentStyle = Variant2Style.shared;
    return roomParticipantsViewController;
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Check whether the view controller has been pushed via storyboard
    if (!self.tableView)
    {
        // Instantiate view controller objects
        [[[self class] nib] instantiateWithOwner:self options:nil];
    }
    
    // Adjust Top and Bottom constraints to take into account potential navBar and tabBar.
    [NSLayoutConstraint deactivateConstraints:@[_searchBarTopConstraint, _tableViewBottomConstraint]];
    
    _searchBarTopConstraint = [NSLayoutConstraint constraintWithItem:self.topLayoutGuide
                                                           attribute:NSLayoutAttributeBottom
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self.searchBarHeader
                                                           attribute:NSLayoutAttributeTop
                                                          multiplier:1.0f
                                                            constant:0.0f];
    
    _tableViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.bottomLayoutGuide
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.tableView
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0f
                                                               constant:0.0f];
    
    [NSLayoutConstraint activateConstraints:@[_searchBarTopConstraint, _tableViewBottomConstraint]];
    
    self.navigationItem.title = NSLocalizedStringFromTable(@"room_participants_title", @"Vector", nil);
    
    _searchBarView.placeholder = NSLocalizedStringFromTable(@"room_participants_filter_room_members", @"Vector", nil);
    _searchBarView.returnKeyType = UIReturnKeyDone;
    _searchBarView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    // Search bar header is hidden when no room is provided
    _searchBarHeader.hidden = (self.mxRoom == nil);
    
    [self setNavBarButtons];
    
    // Hide line separators of empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [self.tableView registerNib:ContactCell.nib forCellReuseIdentifier:ContactCell.defaultReuseIdentifier];
    
    // Enable self-sizing cells.
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 60;
    
    // Add room creation button programmatically
    [self addAddParticipantButton];
    
    // Observe user interface theme change.
    kRiotDesignValuesDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kRiotDesignValuesDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
}

- (void)userInterfaceThemeDidChange
{
    [self updateWithStyle:self.currentStyle];
}

- (void)updateWithStyle:(id<Style>)style
{
    self.currentStyle = style;
    
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    if (navigationBar)
    {
        [style applyStyleOnNavigationBar:navigationBar];
    }
    
    [self refreshSearchBarItemsColor:_searchBarView];
    _searchBarHeaderBorder.backgroundColor = kRiotAuxiliaryColor;
    
    //TODO Design the activvity indicator for Tchap
    self.activityIndicator.backgroundColor = kRiotOverlayColor;
    
    // Update the gradient view above the screen
    CGFloat white = 1.0;
    [style.backgroundColor getWhite:&white alpha:nil];
    CGColorRef opaqueWhiteColor = [UIColor colorWithWhite:white alpha:1.0].CGColor;
    CGColorRef transparentWhiteColor = [UIColor colorWithWhite:white alpha:0].CGColor;
    tableViewMaskLayer.colors = [NSArray arrayWithObjects:(__bridge id)transparentWhiteColor, (__bridge id)transparentWhiteColor, (__bridge id)opaqueWhiteColor, nil];
    
    self.tableView.backgroundColor = style.backgroundColor;
    self.view.backgroundColor = self.tableView.backgroundColor;
    
    if (self.tableView.dataSource)
    {
        [self.tableView reloadData];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.currentStyle.statusBarStyle;
}

// This method is called when the viewcontroller is added or removed from a container view controller.
- (void)didMoveToParentViewController:(nullable UIViewController *)parent
{
    [super didMoveToParentViewController:parent];
    
    [self setNavBarButtons];
}

- (void)destroy
{
    self.userService = nil;
    
    if (kRiotDesignValuesDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kRiotDesignValuesDidChangeThemeNotificationObserver];
        kRiotDesignValuesDidChangeThemeNotificationObserver = nil;
    }
    
    if (leaveRoomNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:leaveRoomNotificationObserver];
        leaveRoomNotificationObserver = nil;
    }
    
    if (roomDidFlushDataNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:roomDidFlushDataNotificationObserver];
        roomDidFlushDataNotificationObserver = nil;
    }
    
    if (membersListener)
    {
        MXWeakify(self);
        [self.mxRoom liveTimeline:^(MXEventTimeline *liveTimeline) {
            MXStrongifyAndReturnIfNil(self);

            [liveTimeline removeListener:self->membersListener];
            self->membersListener = nil;
        }];
    }
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    _mxRoom = nil;
    
    filteredActualParticipants = nil;
    filteredInvitedParticipants = nil;
    
    actualParticipants = nil;
    invitedParticipants = nil;
    
    [self removePendingActionMask];
    
    [super destroy];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Screen tracking
    [[Analytics sharedInstance] trackScreen:@"RoomParticipants"];
    
    if (memberDetailsViewController)
    {
        [memberDetailsViewController destroy];
        memberDetailsViewController = nil;
    }
    
    if (contactsPickerViewController)
    {
        [contactsDataSource destroy];
        contactsDataSource = nil;
        contactsPickerViewController = nil;
    }
    
    [self userInterfaceThemeDidChange];
    
    // Refresh display
    [self refreshTableView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // For unknown reason, we have to force here the UISearchBar search text color again.
    // The value set by [updateWithStyle:] call is ignored.
    [self refreshSearchBarItemsColor:_searchBarView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    // cancel any pending search
    [self searchBarCancelButtonClicked:_searchBarView];
}

- (void)withdrawViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    // Check whether the current view controller is displayed inside a segmented view controller in order to withdraw the right item
    if (self.parentViewController && [self.parentViewController isKindOfClass:SegmentedViewController.class])
    {
        [((SegmentedViewController*)self.parentViewController) withdrawViewControllerAnimated:animated completion:completion];
    }
    else
    {
        [super withdrawViewControllerAnimated:animated completion:completion];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // Sanity check
    if (tableViewMaskLayer)
    {
        CGRect currentBounds = tableViewMaskLayer.bounds;
        CGRect newBounds = CGRectIntegral(self.view.frame);
        
        newBounds.size.height -= self.keyboardHeight;
        
        // Check if there is an update
        if (!CGSizeEqualToSize(currentBounds.size, newBounds.size))
        {
            newBounds.origin = CGPointZero;
            
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 
                                 self->tableViewMaskLayer.bounds = newBounds;
                                 
                             }
                             completion:^(BOOL finished){
                             }];
            
        }
        
        // Hide the addParticipants button on landscape when keyboard is visible
        BOOL isLandscapeOriented = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
        addParticipantButtonImageView.hidden = tableViewMaskLayer.hidden = (!isUserAllowedToInvite || (isLandscapeOriented && self.keyboardHeight));
    }
}

#pragma mark -

- (void)setMxRoom:(MXRoom *)mxRoom
{
    // Cancel any pending search
    [self searchBarCancelButtonClicked:_searchBarView];

    // Make sure we can access synchronously to self.mxRoom and mxRoom data
    // to avoid race conditions
    MXWeakify(self);
    [mxRoom.mxSession preloadRoomsData:_mxRoom ? @[_mxRoom.roomId, mxRoom.roomId] : @[mxRoom.roomId]
                             onComplete:^{
        MXStrongifyAndReturnIfNil(self);

        // Remove previous room registration (if any).
        if (self.mxRoom)
        {
            // Remove the previous listener
            if (self->leaveRoomNotificationObserver)
            {
                [[NSNotificationCenter defaultCenter] removeObserver:self->leaveRoomNotificationObserver];
                self->leaveRoomNotificationObserver = nil;
            }
            if (self->roomDidFlushDataNotificationObserver)
            {
                [[NSNotificationCenter defaultCenter] removeObserver:self->roomDidFlushDataNotificationObserver];
                self->roomDidFlushDataNotificationObserver = nil;
            }
            if (self->membersListener)
            {
                MXWeakify(self);
                [self.mxRoom liveTimeline:^(MXEventTimeline *liveTimeline) {
                    MXStrongifyAndReturnIfNil(self);

                    [liveTimeline removeListener:self->membersListener];
                    self->membersListener = nil;
                }];
            }

            [self removeMatrixSession:self.mxRoom.mxSession];
        }

        self->_mxRoom = mxRoom;

        if (self.mxRoom)
        {
            self.searchBarHeader.hidden = NO;

            // Update the current matrix session.
            [self addMatrixSession:self.mxRoom.mxSession];

            // Observe kMXSessionWillLeaveRoomNotification to be notified if the user leaves the current room.
            self->leaveRoomNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionWillLeaveRoomNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

                // Check whether the user will leave the room related to the displayed participants
                if (notif.object == self.mxRoom.mxSession)
                {
                    NSString *roomId = notif.userInfo[kMXSessionNotificationRoomIdKey];
                    if (roomId && [roomId isEqualToString:self.mxRoom.roomId])
                    {
                        // We remove the current view controller.
                        [self withdrawViewControllerAnimated:YES completion:nil];
                    }
                }
            }];

            // Observe room history flush (sync with limited timeline, or state event redaction)
            self->roomDidFlushDataNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXRoomDidFlushDataNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

                MXRoom *room = notif.object;
                if (self.mxRoom.mxSession == room.mxSession && [self.mxRoom.roomId isEqualToString:room.roomId])
                {
                    // The existing room history has been flushed during server sync. Take into account the updated room members list.
                    [self refreshParticipantsFromRoomMembers:^{
                        [self refreshTableView];
                    }];
                }

            }];

            // Register a listener for events that concern room members
            NSArray *mxMembersEvents = @[kMXEventTypeStringRoomMember, kMXEventTypeStringRoomThirdPartyInvite, kMXEventTypeStringRoomPowerLevels];

            MXWeakify(self);
            [self.mxRoom liveTimeline:^(MXEventTimeline *liveTimeline) {
                MXStrongifyAndReturnIfNil(self);

                self->membersListener = [liveTimeline listenToEventsOfTypes:mxMembersEvents onEvent:^(MXEvent *event, MXTimelineDirection direction, id customObject) {

                    // Consider only live event
                    if (direction == MXTimelineDirectionForwards)
                    {
                        switch (event.eventType)
                        {
                            case MXEventTypeRoomMember:
                            {
                                // Take into account updated member
                                // Ignore here change related to the current user (this change is handled by leaveRoomNotificationObserver)
                                if ([event.stateKey isEqualToString:self.mxRoom.mxSession.myUser.userId] == NO)
                                {
                                    MXRoomMember *mxMember = [liveTimeline.state.members memberWithUserId:event.stateKey];
                                    if (mxMember)
                                    {
                                        // Remove previous occurrence of this member (if any)
                                        [self removeParticipantByKey:mxMember.userId];

                                        // If any, remove 3pid invite corresponding to this room member
                                        if (mxMember.thirdPartyInviteToken)
                                        {
                                            [self removeParticipantByKey:mxMember.thirdPartyInviteToken];
                                        }

                                        [self handleRoomMember:mxMember];

                                        [self finalizeParticipantsList:liveTimeline.state completion:^{
                                            [self refreshTableView];
                                        }];
                                    }
                                }

                                break;
                            }
                            case MXEventTypeRoomThirdPartyInvite:
                            {
                                MXRoomThirdPartyInvite *thirdPartyInvite = [liveTimeline.state thirdPartyInviteWithToken:event.stateKey];
                                if (thirdPartyInvite)
                                {
                                    // Remove previous occurrence of this 3pid invite (if any)
                                    [self removeParticipantByKey:thirdPartyInvite.token];
                                    
                                    [self addRoomThirdPartyInviteToParticipants:thirdPartyInvite roomState:liveTimeline.state];

                                    [self finalizeParticipantsList:liveTimeline.state completion:^{
                                        [self refreshTableView];
                                    }];
                                }
                                break;
                            }
                            case MXEventTypeRoomPowerLevels:
                            {
                                [self refreshParticipantsFromRoomMembers:^{
                                    [self refreshTableView];
                                }];
                                break;
                            }
                            default:
                                break;
                        }
                    }
                }];
            }];
        }
        else
        {
            // Search bar header is hidden when no room is provided
            self.searchBarHeader.hidden = YES;
        }
                                 
        // Refresh the members list.
        [self refreshParticipantsFromRoomMembers:^{
            [self refreshTableView];
        }];
    }];
}

- (void)setEnableMention:(BOOL)enableMention
{
    if (_enableMention != enableMention)
    {
        _enableMention = enableMention;
        
        if (memberDetailsViewController)
        {
            memberDetailsViewController.enableMention = enableMention;
        }
    }
}

- (void)startActivityIndicator
{
    // Check whether the current view controller is displayed inside a segmented view controller in order to run the right activity view
    if (self.parentViewController && [self.parentViewController isKindOfClass:SegmentedViewController.class])
    {
        [((SegmentedViewController*)self.parentViewController) startActivityIndicator];
        
        // Force stop the activity view of the view controller
        [self.activityIndicator stopAnimating];
    }
    else
    {
        [super startActivityIndicator];
    }
}

- (void)stopActivityIndicator
{
    // Check whether the current view controller is displayed inside a segmented view controller in order to stop the right activity view
    if (self.parentViewController && [self.parentViewController isKindOfClass:SegmentedViewController.class])
    {
        [((SegmentedViewController*)self.parentViewController) stopActivityIndicator];
        
        // Force stop the activity view of the view controller
        [self.activityIndicator stopAnimating];
    }
    else
    {
        [super stopActivityIndicator];
    }
}

- (void)setKeyboardHeight:(CGFloat)keyboardHeight
{
    super.keyboardHeight = keyboardHeight;
    
    // Update addParticipants button position with animation
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         
                         self->addParticipantButtonImageViewBottomConstraint.constant = keyboardHeight + 9;
                         
                         // Force to render the view
                         [self.view layoutIfNeeded];
                         
                     }
                     completion:^(BOOL finished){
                     }];
}

#pragma mark - Internals

- (void)refreshTableView
{
    [self.tableView reloadData];
}

- (void)setNavBarButtons
{
    // Check whether the view controller is currently displayed inside a segmented view controller or not.
    UIViewController* topViewController = ((self.parentViewController) ? self.parentViewController : self);
    topViewController.navigationItem.rightBarButtonItem = nil;
    topViewController.navigationItem.leftBarButtonItem = nil;
}

- (void)addAddParticipantButton
{
    // Add blur mask programmatically
    tableViewMaskLayer = [CAGradientLayer layer];
    
    // Consider the grayscale components of the kRiotPrimaryBgColor.
    CGFloat white = 1.0;
    [kRiotPrimaryBgColor getWhite:&white alpha:nil];
    
    CGColorRef opaqueWhiteColor = [UIColor colorWithWhite:white alpha:1.0].CGColor;
    CGColorRef transparentWhiteColor = [UIColor colorWithWhite:white alpha:0].CGColor;
    
    tableViewMaskLayer.colors = [NSArray arrayWithObjects:(__bridge id)transparentWhiteColor, (__bridge id)transparentWhiteColor, (__bridge id)opaqueWhiteColor, nil];
    
    // display a gradient to the rencents bottom (20% of the bottom of the screen)
    tableViewMaskLayer.locations = [NSArray arrayWithObjects:
                                    [NSNumber numberWithFloat:0],
                                    [NSNumber numberWithFloat:0.85],
                                    [NSNumber numberWithFloat:1.0], nil];
    
    tableViewMaskLayer.bounds = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    tableViewMaskLayer.anchorPoint = CGPointZero;
    
    // CAConstraint is not supported on IOS.
    // it seems only being supported on Mac OS.
    // so viewDidLayoutSubviews will refresh the layout bounds.
    [self.view.layer addSublayer:tableViewMaskLayer];
    
    // Add + button
    addParticipantButtonImageView = [[UIImageView alloc] init];
    [addParticipantButtonImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:addParticipantButtonImageView];
    
    addParticipantButtonImageView.backgroundColor = [UIColor clearColor];
    addParticipantButtonImageView.contentMode = UIViewContentModeCenter;
    addParticipantButtonImageView.image = [UIImage imageNamed:@"add_participant"];
    
    CGFloat side = 78.0f;
    NSLayoutConstraint* widthConstraint = [NSLayoutConstraint constraintWithItem:addParticipantButtonImageView
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:1
                                                                        constant:side];
    
    NSLayoutConstraint* heightConstraint = [NSLayoutConstraint constraintWithItem:addParticipantButtonImageView
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1
                                                                         constant:side];
    
    NSLayoutConstraint* centerXConstraint = [NSLayoutConstraint constraintWithItem:addParticipantButtonImageView
                                                                         attribute:NSLayoutAttributeCenterX
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.view
                                                                         attribute:NSLayoutAttributeCenterX
                                                                        multiplier:1
                                                                          constant:0];
    
    addParticipantButtonImageViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.view
                                                                                 attribute:NSLayoutAttributeBottom
                                                                                 relatedBy:NSLayoutRelationEqual
                                                                                    toItem:addParticipantButtonImageView
                                                                                 attribute:NSLayoutAttributeBottom
                                                                                multiplier:1
                                                                                  constant:self.keyboardHeight + 9];
    
    // Available on iOS 8 and later
    [NSLayoutConstraint activateConstraints:@[widthConstraint, heightConstraint, centerXConstraint, addParticipantButtonImageViewBottomConstraint]];
    
    addParticipantButtonImageView.userInteractionEnabled = YES;
    
    // Handle tap gesture
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onAddParticipantButtonPressed)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [addParticipantButtonImageView addGestureRecognizer:tap];
    
    addParticipantButtonImageView.hidden = tableViewMaskLayer.hidden = !isUserAllowedToInvite;
}

- (void)onAddParticipantButtonPressed
{
    // Push the contacts picker.
    contactsPickerViewController = [ContactsViewController instantiateWithStyle:Variant2Style.shared showSearchBar:YES enableMultipleSelection:YES];
    contactsPickerViewController.title = NSLocalizedStringFromTable(@"contacts_picker_title", @"Tchap", nil);
    
    // Set delegate to handle action on member (start chat, mention)
    contactsPickerViewController.delegate = self;
    
    validateBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"action_validate", @"Tchap", nil) style:UIBarButtonItemStylePlain target:self action:@selector(inviteSelectedContacts)];
    validateBarButtonItem.enabled = NO;
    contactsPickerViewController.navigationItem.rightBarButtonItem = validateBarButtonItem;
    
    NSString *roomAccessRule = [self.mxRoom.summary tc_roomAccessRuleIdentifier];
    BOOL isFederated = [self.mxRoom.summary tc_isFederated];
    
    // Prepare its data source
    contactsDataSource = [[ContactsDataSource alloc] initWithMatrixSession:self.mxRoom.mxSession];
    [contactsDataSource finalizeInitialization];
    contactsDataSource.areSectionsShrinkable = YES;
    contactsDataSource.showAddEmailButton = YES;
    if (isFederated)
    {
        if ([roomAccessRule isEqualToString:RoomService.roomAccessRuleRestricted])
        {
            contactsDataSource.contactsFilter = ContactsDataSourceTchapFilterAllWithoutExternals;
        }
        else
        {
            contactsDataSource.contactsFilter = ContactsDataSourceTchapFilterAll;
        }
    }
    else
    {
        contactsDataSource.contactsFilter = ContactsDataSourceTchapFilterAllWithoutFederation;
    }
    
    // List all the participants matrix user id to ignore them during the contacts search.
    for (Contact *contact in actualParticipants)
    {
        [contactsDataSource.ignoredContactsByMatrixId setObject:contact forKey:contact.mxMember.userId];
    }
    for (Contact *contact in invitedParticipants)
    {
        if (contact.mxMember)
        {
            [contactsDataSource.ignoredContactsByMatrixId setObject:contact forKey:contact.mxMember.userId];
        }
    }
    
    // Apply the search pattern if any
    if (currentSearchText)
    {
        [contactsDataSource searchWithPattern:currentSearchText forceReset:YES];
    }
    
    [contactsPickerViewController displayList:contactsDataSource];
    
    [self pushViewController:contactsPickerViewController];
}

- (void)refreshParticipantsFromRoomMembers:(void (^)(void))completion
{
    actualParticipants = [NSMutableArray array];
    invitedParticipants = [NSMutableArray array];
    
    if (self.mxRoom)
    {
        // Retrieve the current members from the room state
        MXWeakify(self);
        [self.mxRoom state:^(MXRoomState *roomState) {
            MXStrongifyAndReturnIfNil(self);

            NSArray *members = [roomState.members membersWithoutConferenceUser];
            NSString *userId = self.mxRoom.mxSession.myUser.userId;
            NSArray *roomThirdPartyInvites = roomState.thirdPartyInvites;

            for (MXRoomMember *mxMember in members)
            {
                [self handleRoomMember:mxMember];
            }

            for (MXRoomThirdPartyInvite *roomThirdPartyInvite in roomThirdPartyInvites)
            {
                [self addRoomThirdPartyInviteToParticipants:roomThirdPartyInvite roomState:roomState];
            }
            
            // Check whether the current user is allowed to invite
            MXRoomPowerLevels *powerLevels = [roomState powerLevels];
            self->isUserAllowedToInvite = ([powerLevels powerLevelOfUserWithUserID:userId] >= powerLevels.invite);
            self->isUserAllowedToKick = ([powerLevels powerLevelOfUserWithUserID:userId] >= powerLevels.kick);
            self->addParticipantButtonImageView.hidden = self->tableViewMaskLayer.hidden = !self->isUserAllowedToInvite;
            
            [self finalizeParticipantsList:roomState completion:completion];
        }];
    }
    else if (completion)
    {
        completion();
    }
}

- (void)handleRoomMember:(MXRoomMember*)mxMember
{
    // Add this member after checking his status
    if (mxMember.membership == MXMembershipJoin || mxMember.membership == MXMembershipInvite)
    {
        // Create the contact related to this member.
        // If the display name is unknown, build a temporary name from the user id.
        NSString *displayName = mxMember.displayname;
        if (!displayName.length && mxMember.userId)
        {
            UserService *userService = [[UserService alloc] initWithSession:self.mxRoom.mxSession];
            displayName = [userService displayNameFrom:mxMember.userId];
        }
        Contact *contact = [[Contact alloc] initMatrixContactWithDisplayName:displayName andMatrixID:mxMember.userId];
        contact.mxMember = mxMember;
        
        if (mxMember.membership == MXMembershipInvite)
        {
            [invitedParticipants addObject:contact];
        }
        else
        {
            [actualParticipants addObject:contact];
        }
    }
}

- (void)reloadSearchResult
{
    if (currentSearchText.length)
    {
        NSString *searchText = currentSearchText;
        currentSearchText = nil;
        
        [self searchBar:_searchBarView textDidChange:searchText];
    }
}

- (void)addRoomThirdPartyInviteToParticipants:(MXRoomThirdPartyInvite*)roomThirdPartyInvite roomState:(MXRoomState*)roomState
{
    // If the homeserver has converted the 3pid invite into a room member, do no show it.
    // If the invite has been revoked (null display name), do not show it too.
    if (![roomState memberWithThirdPartyInviteToken:roomThirdPartyInvite.token]
        && roomThirdPartyInvite.displayname)
    {
        Contact *contact = [[Contact alloc] initMatrixContactWithDisplayName:roomThirdPartyInvite.displayname andMatrixID:nil];
        contact.isThirdPartyInvite = YES;
        contact.mxThirdPartyInvite = roomThirdPartyInvite;
        
        [invitedParticipants addObject:contact];
    }
}

// key is a room member user id or a room 3pid invite token
- (void)removeParticipantByKey:(NSString*)key
{
    NSUInteger index;
    
    if (actualParticipants.count)
    {
        for (index = 0; index < actualParticipants.count; index++)
        {
            Contact *contact = actualParticipants[index];
            
            if (contact.mxMember && [contact.mxMember.userId isEqualToString:key])
            {
                [actualParticipants removeObjectAtIndex:index];
                return;
            }
        }
    }
    
    if (invitedParticipants.count)
    {
        for (index = 0; index < invitedParticipants.count; index++)
        {
            Contact *contact = invitedParticipants[index];
            
            if (contact.mxMember && [contact.mxMember.userId isEqualToString:key])
            {
                [invitedParticipants removeObjectAtIndex:index];
                return;
            }
            
            if (contact.mxThirdPartyInvite && [contact.mxThirdPartyInvite.token isEqualToString:key])
            {
                [invitedParticipants removeObjectAtIndex:index];
                return;
            }
        }
    }
}

- (void)checkExpiredAccounts:(void (^)(void))completion
{
    dispatch_group_t requestsGroup = dispatch_group_create();
    self.userService = [[UserService alloc] initWithSession:self.mxRoom.mxSession];
    MXHTTPOperation *op;
    for (Contact *contact in actualParticipants)
    {
        if (contact.mxMember.userId)
        {
            dispatch_group_enter(requestsGroup);
            op = [self.userService isAccountExpiredFor:contact.mxMember.userId
                                          success:^(BOOL isExpired) {
                                              contact.isExpired = isExpired;
                                              dispatch_group_leave(requestsGroup);
                                          } failure:^(NSError * _Nonnull error) {
                                              contact.isExpired = false;
                                              dispatch_group_leave(requestsGroup);
                                          }];
        }
    }
    for (Contact *contact in invitedParticipants)
    {
        if (contact.mxMember.userId)
        {
            dispatch_group_enter(requestsGroup);
            op = [self.userService isAccountExpiredFor:contact.mxMember.userId
                                          success:^(BOOL isExpired) {
                                              contact.isExpired = isExpired;
                                              dispatch_group_leave(requestsGroup);
                                          } failure:^(NSError * _Nonnull error) {
                                              contact.isExpired = false;
                                              dispatch_group_leave(requestsGroup);
                                          }];
        }
    }
    
    dispatch_group_notify(requestsGroup, dispatch_get_main_queue(), ^{
        self.userService = nil;
        if (completion)
        {
            completion();
        }
    });
}

- (void)finalizeParticipantsList:(MXRoomState*)roomState completion:(void (^)(void))completion
{
    // Sort contacts by power
    // ...and then alphabetically.
    // Move at the end expired accounts...
    // We could tiebreak instead by "last recently spoken in this room" if we wanted to.
    NSComparator comparator = ^NSComparisonResult(Contact *contactA, Contact *contactB) {
        
        NSString *userIdA = contactA.mxMember.userId;
        NSString *userIdB = contactB.mxMember.userId;
        
        if (!userIdA && !userIdB)
        {
            return [contactA.sortingDisplayName compare:contactB.sortingDisplayName options:NSCaseInsensitiveSearch];
        }
        if (userIdA && !userIdB)
        {
            return contactA.isExpired ? NSOrderedDescending : NSOrderedAscending;
        }
        if (!userIdA && userIdB)
        {
            return contactB.isExpired ? NSOrderedAscending : NSOrderedDescending;
        }
        if (contactA.isExpired)
        {
            if (!contactB.isExpired)
            {
                return NSOrderedDescending;
            }
        }
        else if (contactB.isExpired)
        {
            return NSOrderedAscending;
        }
        
        // Order first by power levels (admins then moderators then others)
        MXRoomPowerLevels *powerLevels = [roomState powerLevels];
        NSInteger powerLevelA = [powerLevels powerLevelOfUserWithUserID:userIdA];
        NSInteger powerLevelB = [powerLevels powerLevelOfUserWithUserID:userIdB];
        
        if (powerLevelA == powerLevelB)
        {
            // Then order by name
            if (contactA.sortingDisplayName.length && contactB.sortingDisplayName.length)
            {
                return [contactA.sortingDisplayName compare:contactB.sortingDisplayName options:NSCaseInsensitiveSearch];
            }
            else if (contactA.sortingDisplayName.length)
            {
                return NSOrderedAscending;
            }
            else if (contactB.sortingDisplayName.length)
            {
                return NSOrderedDescending;
            }
            return [contactA.displayName compare:contactB.displayName options:NSCaseInsensitiveSearch];
        }
        else
        {
            return powerLevelB - powerLevelA;
        }
    };
    
    // Check whether some accounts have expired
    MXWeakify(self);
    [self checkExpiredAccounts:^{
        MXStrongifyAndReturnIfNil(self);
        // Sort each participants list in alphabetical order
        [self->actualParticipants sortUsingComparator:comparator];
        [self->invitedParticipants sortUsingComparator:comparator];
        
        // Reload search result if any
        [self reloadSearchResult];
        
        if (completion)
        {
            completion();
        }
    }];
}

- (Contact*)getContactAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger section = indexPath.section;
    NSUInteger row = indexPath.row;
    
    if (section == participantsSection || section == invitedSection)
    {
        NSMutableArray *participants;
        
        if (section == participantsSection)
        {
            if (currentSearchText.length)
            {
                participants = filteredActualParticipants;
            }
            else
            {
                participants = actualParticipants;
            }
        }
        else
        {
            if (currentSearchText.length)
            {
                participants = filteredInvitedParticipants;
            }
            else
            {
                participants = invitedParticipants;
            }
        }
        
        if (row < participants.count)
        {
            return participants[row];
        }
    }
    
    return nil;
}

- (void)addPendingActionMask
{
    // Remove potential existing mask
    [self removePendingActionMask];
    
    // Add a spinner above the tableview to avoid that the user tap on any other button
    pendingMaskSpinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    pendingMaskSpinnerView.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.5];
    pendingMaskSpinnerView.frame = self.tableView.frame;
    pendingMaskSpinnerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
    
    // append it
    [self.tableView.superview addSubview:pendingMaskSpinnerView];
    
    // animate it
    [pendingMaskSpinnerView startAnimating];
    
    // Show the spinner after a delay so that if it is removed in a short future,
    // it is not displayed to the end user.
    pendingMaskSpinnerView.alpha = 0;
    [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        
        self->pendingMaskSpinnerView.alpha = 1;
        
    } completion:^(BOOL finished) {
    }];
}

- (void)removePendingActionMask
{
    if (pendingMaskSpinnerView)
    {
        [pendingMaskSpinnerView removeFromSuperview];
        pendingMaskSpinnerView = nil;
    }
}

- (void)pushViewController:(UIViewController*)viewController
{
    // Check whether the view controller is displayed inside a segmented one.
    if (self.parentViewController.navigationController)
    {
        // Hide back button title
        self.parentViewController.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
        
        [self.parentViewController.navigationController pushViewController:viewController animated:YES];
    }
    else
    {
        // Hide back button title
        self.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
        
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

- (void)popViewControllerAnimated:(BOOL)animated
{
    // Check whether the view controller is displayed inside a segmented one.
    if (self.parentViewController.navigationController)
    {
        [self.parentViewController.navigationController popViewControllerAnimated:animated];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:animated];
    }
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
    
    participantsSection = invitedSection = -1;
    
    if (currentSearchText.length)
    {
        if (filteredActualParticipants.count)
        {
            participantsSection = count++;
        }
        
        if (filteredInvitedParticipants.count)
        {
            invitedSection = count++;
        }
    }
    else
    {
        if (actualParticipants.count)
        {
            participantsSection = count++;
        }
        
        if (invitedParticipants.count)
        {
            invitedSection = count++;
        }
    }
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    if (section == participantsSection)
    {
        if (currentSearchText.length)
        {
            count = filteredActualParticipants.count;
        }
        else
        {
            count = actualParticipants.count;
        }
    }
    else if (section == invitedSection)
    {
        if (currentSearchText.length)
        {
            count = filteredInvitedParticipants.count;
        }
        else
        {
            count = invitedParticipants.count;
        }
    }
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (indexPath.section == participantsSection || indexPath.section == invitedSection)
    {
        ContactCell* participantCell = [tableView dequeueReusableCellWithIdentifier:ContactCell.defaultReuseIdentifier forIndexPath:indexPath];
        participantCell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        Contact *contact = [self getContactAtIndexPath:indexPath];
        if (contact)
        {
            [participantCell render:contact];
            
            participantCell.thumbnailBadgeView.hidden = YES;
            if (contact.mxMember)
            {
                MXRoomState *roomState = self.mxRoom.dangerousSyncState;
                
                // Update member badge
                MXRoomPowerLevels *powerLevels = [roomState powerLevels];
                NSInteger powerLevel = [powerLevels powerLevelOfUserWithUserID:contact.mxMember.userId];
                if (powerLevel >= RoomPowerLevelAdmin)
                {
                    participantCell.thumbnailBadgeView.image = [UIImage imageNamed:@"admin_icon"];
                    participantCell.thumbnailBadgeView.hidden = NO;
                }
                else if (powerLevel >= RoomPowerLevelModerator)
                {
                    participantCell.thumbnailBadgeView.image = [UIImage imageNamed:@"mod_icon"];
                    participantCell.thumbnailBadgeView.hidden = NO;
                }
            }
        }
        
        cell = participantCell;
    }
    else
    {
        // Return a fake cell to prevent app from crashing.
        cell = [[UITableViewCell alloc] init];
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canEdit = isUserAllowedToKick;
    
    // Check whether the selected row corresponds to an actual member
    Contact *contact = [self getContactAtIndexPath:indexPath];
    if (contact.mxMember)
    {
        // Check whether the selected row corresponds to the current user.
        NSString *userId = self.mxRoom.mxSession.myUser.userId;
        if ([userId isEqualToString:contact.mxMember.userId])
        {
            canEdit = YES;
        }
        else if (canEdit)
        {
            // Compare the power level between the selected member and the current user.
            MXRoomState *roomState = self.mxRoom.dangerousSyncState;
            MXRoomPowerLevels *powerLevels = [roomState powerLevels];
            canEdit = ([powerLevels powerLevelOfUserWithUserID:userId] > [powerLevels powerLevelOfUserWithUserID:contact.mxMember.userId]);
        }
    }
    return canEdit;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    // iOS8 requires this method to enable editing (see editActionsForRowAtIndexPath).
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
    CGFloat height = 0.0;
    
    if (section == invitedSection)
    {
        height = 30.0;
    }
    
    return height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView* sectionHeader;
    
    if (section == invitedSection)
    {
        sectionHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 30)];
        sectionHeader.backgroundColor = kRiotSecondaryBgColor;
        
        CGRect frame = sectionHeader.frame;
        frame.origin.x = 20;
        frame.origin.y = 5;
        frame.size.width = sectionHeader.frame.size.width - 10;
        frame.size.height -= 10;
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:frame];
        headerLabel.textColor = kRiotPrimaryTextColor;
        headerLabel.font = [UIFont boldSystemFontOfSize:15.0];
        headerLabel.backgroundColor = [UIColor clearColor];
        
        headerLabel.text = NSLocalizedStringFromTable(@"room_participants_invited_section", @"Vector", nil);
        
        [sectionHeader addSubview:headerLabel];
    }
    
    return sectionHeader;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Sanity check
    if (!self.mxRoom)
    {
        return;
    }
    
    Contact *contact = [self getContactAtIndexPath:indexPath];
    if (contact.mxMember)
    {
        memberDetailsViewController = [RoomMemberDetailsViewController instantiate];
        
        // Set delegate to handle action on member (start chat, mention)
        memberDetailsViewController.delegate = self;
        memberDetailsViewController.enableMention = _enableMention;
        memberDetailsViewController.enableVoipCall = NO;
        
        [memberDetailsViewController displayRoomMember:contact.mxMember withMatrixRoom:self.mxRoom];
        
        [self pushViewController:memberDetailsViewController];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray* actions;
    
    // add the swipe to delete only on participants sections
    if (indexPath.section == participantsSection || indexPath.section == invitedSection)
    {
        actions = [[NSMutableArray alloc] init];
        
        // Patch: Force the width of the button by adding whitespace characters into the title string.
        UITableViewRowAction *leaveAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"        "  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
            
            [self onDeleteAt:indexPath];
            
        }];
        
        leaveAction.backgroundColor = [MXKTools convertImageToPatternColor:@"remove_icon" backgroundColor:kRiotSecondaryBgColor patternSize:CGSizeMake(74, 74) resourceSize:CGSizeMake(24, 24)];
        [actions insertObject:leaveAction atIndex:0];
    }
    
    return actions;
}

#pragma mark - MXKRoomMemberDetailsViewControllerDelegate

- (void)roomMemberDetailsViewController:(MXKRoomMemberDetailsViewController *)roomMemberDetailsViewController startChatWithMemberId:(NSString *)matrixId completion:(void (^)(void))completion
{
    [self.delegate roomParticipantsViewController:self startChatWithMemberId:matrixId completion:completion];
}

- (void)roomMemberDetailsViewController:(MXKRoomMemberDetailsViewController *)roomMemberDetailsViewController mention:(MXRoomMember*)member
{
    if (_delegate)
    {
        id<RoomParticipantsViewControllerDelegate> delegate = _delegate;
        
        // Withdraw the current view controller, and let the delegate mention the member
        [self withdrawViewControllerAnimated:YES completion:^{
            
            [delegate roomParticipantsViewController:self mention:member];
            
        }];
    }
}

#pragma mark - ContactsViewControllerDelegate

- (void)contactsViewController:(ContactsViewController *)contactsViewController didSelectContact:(MXKContact*)contact
{
    validateBarButtonItem.enabled = contactsDataSource.selectedContactByIdentifier.count;
}

- (void)contactsViewController:(nonnull ContactsViewController *)contactsViewController askPermissionToSelect:(nonnull NSString*)email completion:(void (^_Nonnull)(BOOL granted, NSString * _Nullable reason))completion
{
    // Use the value of the filter defined at the data source level
    self.userService = [[UserService alloc] initWithSession:self.mxRoom.mxSession];
    
    switch (contactsDataSource.contactsFilter) {
        case ContactsDataSourceTchapFilterAll:
        case ContactsDataSourceTchapFilterAllWithoutTchapUsers:
        {
            // Check whether the registration is allowed for this email.
            [self.userService isEmailAuthorized:email success:^(BOOL isAuthorized) {
                self.userService = nil;
                NSString *reason = isAuthorized ? nil : [NSString stringWithFormat:NSLocalizedStringFromTable(@"invite_not_sent_for_unauthorized_email", @"Tchap", nil), email];
                completion(isAuthorized, reason);
            } failure:^(NSError * _Nonnull error) {
                self.userService = nil;
                // We allow the selection when we failed to get the informmation (We let the server reject the invite or not).
                completion(true, nil);
            }];
            break;
        }
        case ContactsDataSourceTchapFilterAllWithoutExternals:
        {
            // Check whether this email is bound to the external instance.
            [self.userService isEmailBoundToTheExternalHost:email success:^(BOOL isExternal) {
                self.userService = nil;
                NSString *reason = isExternal ? NSLocalizedStringFromTable(@"contacts_picker_unauthorized_email_message_restricted_room", @"Tchap", nil) : nil;
                completion(!isExternal, reason);
            } failure:^(NSError * _Nonnull error) {
                self.userService = nil;
                // We allow the selection when we failed to get the informmation (We let the server reject the invite or not).
                completion(true, nil);
            }];
            break;
        }
        case ContactsDataSourceTchapFilterAllWithoutFederation:
        {
            // Check whether this email belongs to the same host as the current user.
            NSString *myUserId = self.mxRoom.mxSession.myUser.userId;
            if (myUserId)
            {
                NSString *hostName = [self.userService hostNameFor:myUserId];
                [self.userService isEmailBound:email to:hostName success:^(BOOL isBoundToTheSameHost) {
                    NSString *reason = isBoundToTheSameHost ? nil : [NSString stringWithFormat:NSLocalizedStringFromTable(@"contacts_picker_unauthorized_email_message_unfederated_room", @"Tchap", nil), [self.userService hostDisplayNameFor:myUserId]];
                    self.userService = nil;
                    completion(isBoundToTheSameHost, reason);
                } failure:^(NSError * _Nonnull error) {
                    self.userService = nil;
                    // We allow the selection when we failed to get the informmation (We let the server reject the invite or not).
                    completion(true, nil);
                }];
            }
            else
            {
                // We allow the selection when we failed to get the informmation (We let the server reject the invite or not).
                completion(true, nil);
            }
            break;
        }
        default:
            completion(false, nil);
            break;
    }
}

#pragma mark - Actions

- (void)onDeleteAt:(NSIndexPath*)path
{
    Contact *contact = [self getContactAtIndexPath:path];
    if (contact.mxMember)
    {
        if ([contact.mxMember.userId isEqualToString:self.mxRoom.mxSession.myUser.userId])
        {
            [self leaveRoom];
        }
        else
        {
            [self kickRoomMember:contact.mxMember withDisplayName:contact.displayName];
        }
    }
    else if (contact.mxThirdPartyInvite)
    {
        [self revokeThirdPartyInvite:contact.mxThirdPartyInvite];
    }
}

#pragma mark -

- (void)leaveRoom
{
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    // Leave ?
    [self startActivityIndicator];
    MXWeakify(self);
    [self.mxRoom tc_isCurrentUserLastAdministrator:^(BOOL isLastAdmin) {
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
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action) {
                                                                 
                                                                 MXStrongifyAndReturnIfNil(self);
                                                                 self->currentAlert = nil;
                                                                 
                                                                 [self addPendingActionMask];
                                                                 MXWeakify(self);
                                                                 [self.mxRoom leave:^{
                                                                     
                                                                     MXStrongifyAndReturnIfNil(self);
                                                                     [self withdrawViewControllerAnimated:YES completion:nil];
                                                                     
                                                                 } failure:^(NSError *error) {
                                                                     
                                                                     MXStrongifyAndReturnIfNil(self);
                                                                     [self removePendingActionMask];
                                                                     NSLog(@"[RoomParticipantsVC] Leave room %@ failed", self.mxRoom.roomId);
                                                                     // Alert user
                                                                     [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                     
                                                                 }];
                                                                 
                                                             }]];
        
        [self->currentAlert mxk_setAccessibilityIdentifier:@"RoomParticipantsVCLeaveAlert"];
        [self presentViewController:self->currentAlert animated:YES completion:nil];
    }];
}

- (void)kickRoomMember:(MXRoomMember*)member withDisplayName:(NSString*)displayName
{
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    // Kick?
    MXWeakify(self);
    NSString *promptMsg = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_members_remove_prompt_msg", @"Tchap", nil), displayName];
    currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"room_participants_remove_prompt_title", @"Vector", nil)
                                                       message:promptMsg
                                                preferredStyle:UIAlertControllerStyleAlert];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       MXStrongifyAndReturnIfNil(self);
                                                       self->currentAlert = nil;
                                                       
                                                   }]];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"action_remove", @"Tchap", nil)
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       MXStrongifyAndReturnIfNil(self);
                                                       self->currentAlert = nil;
                                                       
                                                       [self addPendingActionMask];
                                                       MXWeakify(self);
                                                       [self.mxRoom kickUser:member.userId
                                                                      reason:nil
                                                                     success:^{
                                                                         
                                                                         MXStrongifyAndReturnIfNil(self);
                                                                         [self removePendingActionMask];
                                                                         
                                                                         // Let the room member events listener remove this member
                                                                         
                                                                     } failure:^(NSError *error) {
                                                                         
                                                                         MXStrongifyAndReturnIfNil(self);
                                                                         [self removePendingActionMask];
                                                                         NSLog(@"[RoomParticipantsVC] Kick %@ failed", member.userId);
                                                                         // Alert user
                                                                         [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                         
                                                                     }];
                                                       
                                                   }]];
    
    [currentAlert mxk_setAccessibilityIdentifier:@"RoomParticipantsVCKickAlert"];
    [self presentViewController:currentAlert animated:YES completion:nil];
}

- (void)revokeThirdPartyInvite:(MXRoomThirdPartyInvite*)thirdPartyInvite
{
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    // This is a third-party invite
    MXWeakify(self);
    currentAlert = [UIAlertController alertControllerWithTitle:nil
                                                       message:NSLocalizedStringFromTable(@"room_participants_remove_third_party_invite_prompt_msg", @"Vector", nil)
                                                preferredStyle:UIAlertControllerStyleAlert];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       MXStrongifyAndReturnIfNil(self);
                                                       self->currentAlert = nil;
                                                       
                                                   }]];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"action_remove", @"Tchap", nil)
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       MXStrongifyAndReturnIfNil(self);
                                                       self->currentAlert = nil;
                                                       
                                                       [self addPendingActionMask];
                                                       MXWeakify(self);
                                                       [self.mxRoom sendStateEventOfType:kMXEventTypeStringRoomThirdPartyInvite
                                                                                 content:@{} stateKey:thirdPartyInvite.token success:^(NSString *eventId) {
                                                                                     
                                                                                     MXStrongifyAndReturnIfNil(self);
                                                                                     [self removePendingActionMask];
                                                                                     
                                                                                     // Let the room member events listener remove this invite
                                                                                     
                                                                                 } failure:^(NSError *error) {
                                                                                     
                                                                                     MXStrongifyAndReturnIfNil(self);
                                                                                     [self removePendingActionMask];
                                                                                     NSLog(@"[RoomParticipantsVC] Revoke 3pid invite failed");
                                                                                     // Alert user
                                                                                     [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                                     
                                                                                 }];
                                                       
                                                   }]];
    
    [currentAlert mxk_setAccessibilityIdentifier:@"RoomParticipantsVCRevokeAlert"];
    [self presentViewController:currentAlert animated:YES completion:nil];
}

- (void)inviteSelectedContacts
{
    // Retrieve the selected identifiers (2 types of ids are supported: Matrix ids and email addresses)
    NSMutableArray *selectedIdentifiers = [NSMutableArray arrayWithArray:contactsDataSource.selectedContactByIdentifier.allKeys];
    
    // Remove contacts picker
    [self popViewControllerAnimated:YES];
    [contactsDataSource destroy];
    contactsDataSource = nil;
    contactsPickerViewController = nil;
    
    // Invite one by one selected userIds
    [self addPendingActionMask];
    [self inviteOneByOneSelectedIdentifiers:selectedIdentifiers];
}

- (void)inviteOneByOneSelectedIdentifiers:(NSMutableArray*)selectedIdentifiers
{
    NSString *identifier = selectedIdentifiers.lastObject;
    if (identifier)
    {
        [selectedIdentifiers removeLastObject];
        
        MXWeakify(self);
        void (^success)(void)= ^{
            
            MXStrongifyAndReturnIfNil(self);
            [self inviteOneByOneSelectedIdentifiers:selectedIdentifiers];
            
        };
        void (^failure)(NSError *error) = ^(NSError *error) {
            
            MXStrongifyAndReturnIfNil(self);
            
            // Stop invite process
            [self removePendingActionMask];
            NSLog(@"[RoomParticipantsVC] Invite failed (%tu)", selectedIdentifiers.count);
            
            // Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        };
        
        // Check whether this is a Matrix id or an email address
        if ([MXTools isMatrixUserIdentifier:identifier])
        {
            [self.mxRoom inviteUser:identifier success:success failure:failure];
        }
        else if ([MXTools isEmailAddress:identifier])
        {
            [self.mxRoom inviteUserByEmail:identifier success:success failure:failure];
        }
    }
    else
    {
        // All invites have been sent
        [self removePendingActionMask];
        // Refresh display
        [self.tableView reloadData];
    }
}

#pragma mark - UISearchBar delegate

- (void)refreshSearchBarItemsColor:(UISearchBar *)searchBar
{
    // bar tint color
    searchBar.barTintColor = searchBar.tintColor = self.currentStyle.barSubTitleColor;
    
    // FIXME: this all seems incredibly fragile and tied to gutwrenching the current UISearchBar internals.
    
    // text color
    UITextField *searchBarTextField = [searchBar valueForKey:@"_searchField"];
    searchBarTextField.textColor = self.currentStyle.barSubTitleColor;
    
    // Magnifying glass icon.
    UIImageView *leftImageView = (UIImageView *)searchBarTextField.leftView;
    leftImageView.image = [leftImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    leftImageView.tintColor = self.currentStyle.buttonBorderedBackgroundColor;
    
    // remove the gray background color
    UIView *effectBackgroundTop =  [searchBarTextField valueForKey:@"_effectBackgroundTop"];
    UIView *effectBackgroundBottom =  [searchBarTextField valueForKey:@"_effectBackgroundBottom"];
    effectBackgroundTop.hidden = YES;
    effectBackgroundBottom.hidden = YES;
    
    // place holder
    searchBarTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:searchBarTextField.placeholder
                                                                               attributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                                                                                            NSUnderlineColorAttributeName: self.currentStyle.barSubTitleColor,
                                                                                            NSForegroundColorAttributeName: self.currentStyle.barSubTitleColor}];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // Update search results.
    NSUInteger index;
    MXKContact *contact;
    
    searchText = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (!currentSearchText.length || [searchText hasPrefix:currentSearchText] == NO)
    {
        // Copy participants and invited participants
        filteredActualParticipants = [NSMutableArray arrayWithArray:actualParticipants];
        filteredInvitedParticipants = [NSMutableArray arrayWithArray:invitedParticipants];
        
        // Add the current user if he belongs to the room members.
        if (userParticipant)
        {
            [filteredActualParticipants addObject:userParticipant];
        }
    }
    
    currentSearchText = searchText;
    
    // Filter room participants
    if (currentSearchText.length)
    {
        for (index = 0; index < filteredActualParticipants.count;)
        {
            contact = filteredActualParticipants[index];
            if (![contact matchedWithPatterns:@[currentSearchText]])
            {
                [filteredActualParticipants removeObjectAtIndex:index];
            }
            else
            {
                index++;
            }
        }
        
        for (index = 0; index < filteredInvitedParticipants.count;)
        {
            contact = filteredInvitedParticipants[index];
            if (![contact matchedWithPatterns:@[currentSearchText]])
            {
                [filteredInvitedParticipants removeObjectAtIndex:index];
            }
            else
            {
                index++;
            }
        }
    }
    else
    {
        filteredActualParticipants = nil;
        filteredInvitedParticipants = nil;
    }
    
    // Refresh display
    [self refreshTableView];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = YES;
    
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = NO;
    
    return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // "Done" key has been pressed.
    
    // Dismiss keyboard
    [_searchBarView resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    if (currentSearchText)
    {
        currentSearchText = nil;
        filteredActualParticipants = nil;
        filteredInvitedParticipants = nil;
        
        [self refreshTableView];
    }
    
    searchBar.text = nil;
    // Leave search
    [searchBar resignFirstResponder];
}

@end
