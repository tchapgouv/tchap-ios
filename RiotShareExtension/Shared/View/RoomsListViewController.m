/*
 Copyright 2017 Vector Creations Ltd
 Copyright 2019 New Vector Ltd
 
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

#import "RoomsListViewController.h"
#import "NSBundle+MatrixKit.h"
#import "RecentCellData.h"
#import "ThemeService.h"
#import "RecentRoomTableViewCell.h"

#import "GeneratedInterface-Swift.h"

@interface RoomsListViewController ()

@property (nonatomic) MXKPieChartHUD *hudView;

// The fake search bar displayed at the top of the recents table. We switch on the actual search bar (self.recentsSearchBar)
// when the user selects it.
@property (nonatomic) UISearchBar *tableSearchBar;

@property (nonatomic) MXSession *session;
@property (nonatomic) MXRoom *selectedRoom;

@property (nonatomic, nullable, strong) UserService *userService;

@end

@implementation RoomsListViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([RoomsListViewController class])
                          bundle:[NSBundle bundleForClass:[RoomsListViewController class]]];
}

+ (instancetype)recentListViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([RoomsListViewController class])
                                          bundle:[NSBundle bundleForClass:[RoomsListViewController class]]];
}

- (void)finalizeInit
{
    [super finalizeInit];
    
    self.enableBarButtonSearch = NO;
    
    // Create the fake search bar
    _tableSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 600, 44)];
    _tableSearchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _tableSearchBar.showsCancelButton = NO;
    _tableSearchBar.searchBarStyle = UISearchBarStyleMinimal;
    _tableSearchBar.placeholder = [VectorL10n searchDefaultPlaceholder];
    _tableSearchBar.delegate = self;
}

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.recentsTableView registerNib:[RecentRoomTableViewCell nib] forCellReuseIdentifier:[RecentRoomTableViewCell defaultReuseIdentifier]];
    
    // Enable self-sizing cells.
    self.recentsTableView.rowHeight = UITableViewAutomaticDimension;
    self.recentsTableView.estimatedRowHeight = 56;
    self.recentsTableView.backgroundColor = ThemeService.shared.theme.backgroundColor;
    
    [self configureSearchBar];
}

- (void)destroy
{
    // Release the room data source
    [self.dataSource destroy];
    
    if (self.session)
    {
        [self.session close];
        self.session = nil;
    }
    self.selectedRoom = nil;
    
    [super destroy];
}

#pragma mark - Views

- (void)configureSearchBar
{
    self.recentsSearchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    self.recentsSearchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.recentsSearchBar.placeholder = [VectorL10n searchDefaultPlaceholder];
    self.recentsSearchBar.tintColor = ThemeService.shared.theme.tintColor;
    self.recentsSearchBar.backgroundColor = ThemeService.shared.theme.baseColor;
    
    _tableSearchBar.tintColor = self.recentsSearchBar.tintColor;
}

#pragma mark - Override MXKRecentListViewController

- (void)refreshRecentsTable
{
    [super refreshRecentsTable];
    
    // Check conditions to display the fake search bar into the table header
    if (self.recentsSearchBar.isHidden && self.recentsTableView.tableHeaderView == nil)
    {
        // Add the search bar by showing it by default.
        self.recentsTableView.tableHeaderView = _tableSearchBar;
    }
}

- (void)hideSearchBar:(BOOL)hidden
{
    [super hideSearchBar:hidden];
    
    if (!hidden)
    {
        // Remove the fake table header view if any
        self.recentsTableView.tableHeaderView = nil;
        self.recentsTableView.contentInset = UIEdgeInsetsZero;
    }
}

- (void)setKeyboardHeight:(CGFloat)keyboardHeight
{
    // Bypass inherited keyboard handling to fix layout when searching.
    // There are no sticky headers to worry about updating.
    return;
}

#pragma mark - Private

/**
 Check whether the current room is a direct chat left by the other member.
 */
- (void)isDirectChatLeftByTheOther:(MXRoom *)room completion:(void (^)(BOOL isEmptyDirect))onComplete
{
    // In the case of a direct chat, we check if the other member has left the room.
    NSString *directUserId = room.directUserId;
    if (directUserId)
    {
        [room members:^(MXRoomMembers *roomMembers) {
            MXRoomMember *directUserMember = [roomMembers memberWithUserId:directUserId];
            if (directUserMember)
            {
                MXMembership directUserMembership = directUserMember.membership;
                if (directUserMembership != MXMembershipJoin && directUserMembership != MXMembershipInvite)
                {
                    onComplete(YES);
                }
                else
                {
                    onComplete(NO);
                }
            }
            else
            {
                NSLog(@"[RoomsListViewController] isDirectChatLeftByTheOther: the direct user has disappeared");
                onComplete(YES);
            }
        } failure:^(NSError *error) {
            NSLog(@"[RoomsListViewController] isDirectChatLeftByTheOther: cannot get all room members");
            onComplete(NO);
        }];
        return;
    }
    
    // This is not a direct chat
    onComplete(NO);
}

/**
 Check whether the current room is a direct chat left by the other member.
 In this case, this method will invite again the left member.
 */
- (void)restoreDiscussionIfNeed:(MXRoom *)room completion:(void (^)(BOOL success))onComplete
{
    [self isDirectChatLeftByTheOther: room completion:^(BOOL isEmptyDirect) {
        if (isEmptyDirect)
        {
            NSString *directUserId = room.directUserId;
            
            // Check whether the left member has deactivated his account
            self.userService = [[UserService alloc] initWithSession:self.session];
            MXHTTPOperation * operation;
            MXWeakify(self);
            NSLog(@"[RoomsListViewController] restoreDiscussionIfNeed: check left member %@", directUserId);
            operation = [self.userService isAccountDeactivatedFor:directUserId success:^(BOOL isDeactivated) {
                MXStrongifyAndReturnIfNil(self);
                if (isDeactivated)
                {
                    NSLog(@"[RoomsListViewController] restoreDiscussionIfNeed: the left member has deactivated his account");
                    onComplete(NO);
                }
                else
                {
                    // Invite again the direct user
                    NSLog(@"[RoomsListViewController] restoreDiscussionIfNeed: invite again %@", directUserId);
                    [room inviteUser:directUserId success:^{
                        // Delay the completion in order to display the invite before the local echo of the new message.
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            onComplete(YES);
                        });
                    } failure:^(NSError *error) {
                        NSLog(@"[RoomsListViewController] restoreDiscussionIfNeed: invite failed");
                        onComplete(NO);
                    }];
                }
                self.userService = nil;
            } failure:^(NSError *error) {
                NSLog(@"[RoomsListViewController] restoreDiscussionIfNeed: check member status failed");
                onComplete(NO);
                self.userService = nil;
            }];
        }
        else
        {
            // Nothing to do
            onComplete(YES);
        }
    }];
}

- (void)showFailureAlert:(NSString *)title
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title.length ? title : [VectorL10n roomEventFailedToSend] message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:[VectorL10n ok] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (self.failureBlock)
        {
            self.failureBlock();
        }
    }];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *roomIdentifier = [self.dataSource cellDataAtIndexPath:indexPath].roomSummary.roomId;
    
    ShareDataSource *dataSource = (ShareDataSource *)self.dataSource;
    if ([dataSource.selectedRoomIdentifiers containsObject:roomIdentifier]) {
        [dataSource deselectRoomWithIdentifier:roomIdentifier animated:YES];
    } else {
        [dataSource selectRoomWithIdentifier:roomIdentifier animated:YES];
    }
    
    [self.recentsTableView reloadData];
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    if ([cellData isKindOfClass:[RecentCellData class]])
    {
        return [RecentRoomTableViewCell class];
    }
    return nil;
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    if ([cellData isKindOfClass:[MXKRecentCellData class]])
    {
        return [RecentRoomTableViewCell defaultReuseIdentifier];
    }
    return nil;
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSArray *patterns = nil;
    if (searchText.length)
    {
        patterns = @[searchText];
    }
    [self.dataSource searchWithPatterns:patterns];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    if (searchBar == _tableSearchBar)
    {
        [self hideSearchBar:NO];
        [self.recentsSearchBar becomeFirstResponder];
        return NO;
    }
    
    return YES;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.recentsSearchBar setShowsCancelButton:YES animated:NO];
    });
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self.recentsSearchBar setShowsCancelButton:NO animated:NO];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
    
    if (scrollView == self.recentsTableView)
    {
        if (!self.recentsSearchBar.isHidden)
        {
            if (!self.recentsSearchBar.text.length && (scrollView.contentOffset.y + scrollView.adjustedContentInset.top > self.recentsSearchBar.frame.size.height))
            {
                // Hide the search bar
                [self hideSearchBar:YES];
                
                // Refresh display
                [self refreshRecentsTable];
            }
            
            // Dismiss the keyboard when scrolling to match the behaviour of the main app.
            if (self.recentsSearchBar.isFirstResponder)
            {
                [self.recentsSearchBar resignFirstResponder];
            }
        }
    }
}

@end
