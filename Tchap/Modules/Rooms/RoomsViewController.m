/*
 Copyright 2017 Vector Creations Ltd
 Copyright 2018 Vector Creations Ltd

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

#import "RoomsViewController.h"

#import "GeneratedInterface-Swift.h"

#import "RoomsDataSource.h"

@interface RoomsViewController ()
#ifdef SUPPORT_KEYS_BACKUP
<KeyBackupSetupCoordinatorBridgePresenterDelegate, KeyBackupRecoverCoordinatorBridgePresenterDelegate>
#endif
{
    RoomsDataSource *roomsDataSource;

    // The animated view displayed at the table view bottom when paginating the room directory
    UIView* footerSpinnerView;
}

#ifdef SUPPORT_KEYS_BACKUP
@property (nonatomic, strong) KeyBackupSetupCoordinatorBridgePresenter *keyBackupSetupCoordinatorBridgePresenter;
@property (nonatomic, strong) KeyBackupRecoverCoordinatorBridgePresenter *keyBackupRecoverCoordinatorBridgePresenter;
#endif

@end

@implementation RoomsViewController

+ (instancetype)instantiate
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    return [storyboard instantiateViewControllerWithIdentifier:@"RoomsViewController"];
}

- (void)finalizeInit
{
    [super finalizeInit];
    
    self.screenName = @"Rooms";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.accessibilityIdentifier = @"RoomsVCView";
    self.recentsTableView.accessibilityIdentifier = @"RoomsVCTableView";        
    
    // Enable self-sizing cells.
    self.recentsTableView.rowHeight = UITableViewAutomaticDimension;
    self.recentsTableView.estimatedRowHeight = 80;
    
    // Register key backup banner cells
    [self.recentsTableView registerNib:KeyBackupBannerCell.nib forCellReuseIdentifier:KeyBackupBannerCell.defaultReuseIdentifier];
    
    self.enableStickyHeaders = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [roomsDataSource registerKeyBackupStateDidChangeNotification];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [roomsDataSource unregisterKeyBackupStateDidChangeNotification];
}

- (void)dealloc
{
    
}

- (void)destroy
{
    [super destroy];
}

#ifdef SUPPORT_KEYS_BACKUP

#pragma mark - Key backup

- (void)presentKeyBackupSetup
{
    KeyBackupSetupCoordinatorBridgePresenter *keyBackupSetupCoordinatorBridgePresenter = [[KeyBackupSetupCoordinatorBridgePresenter alloc] initWithSession:self.mainSession];
    keyBackupSetupCoordinatorBridgePresenter.delegate = self;
    
    [keyBackupSetupCoordinatorBridgePresenter presentFrom:self animated:YES];
    
    self.keyBackupSetupCoordinatorBridgePresenter = keyBackupSetupCoordinatorBridgePresenter;
}

- (void)presentKeyBackupRecover
{
    MXKeyBackupVersion *keyBackupVersion = self.mainSession.crypto.backup.keyBackupVersion;
    if (keyBackupVersion)
    {
        KeyBackupRecoverCoordinatorBridgePresenter *keyBackupRecoverCoordinatorBridgePresenter = [[KeyBackupRecoverCoordinatorBridgePresenter alloc] initWithSession:self.mainSession keyBackupVersion:keyBackupVersion];
        keyBackupRecoverCoordinatorBridgePresenter.delegate = self;
        
        [keyBackupRecoverCoordinatorBridgePresenter presentFrom:self animated:YES];
        
        self.keyBackupRecoverCoordinatorBridgePresenter = keyBackupRecoverCoordinatorBridgePresenter;
    }
}

#endif

#pragma mark - Override RecentsViewController

- (void)displayList:(MXKRecentsDataSource *)listDataSource
{
    [super displayList:listDataSource];
    
    if ([self.dataSource isKindOfClass:RoomsDataSource.class])
    {
        roomsDataSource = (RoomsDataSource*)self.dataSource;
        roomsDataSource.areSectionsShrinkable = NO;
        
    }
}

- (void)refreshCurrentSelectedCell:(BOOL)forceVisible
{
    [super refreshCurrentSelectedCell:forceVisible];
}

- (UIView *)tableView:(UITableView *)tableView viewForStickyHeaderInSection:(NSInteger)section
{
    CGRect frame = [tableView rectForHeaderInSection:section];
    frame.size.height = self.stickyHeaderHeight;
    
    return [roomsDataSource viewForHeaderInSection:section withFrame:frame];
}

- (void)dataSource:(MXKDataSource *)dataSource didRecognizeAction:(NSString *)actionIdentifier inCell:(id<MXKCellRendering>)cell userInfo:(NSDictionary *)userInfo
{
    if ([actionIdentifier isEqualToString:RoomsInviteCell.actionJoinInvite])
    {
        // Retrieve the invited room
        MXRoom *invitedRoom = userInfo[RoomsInviteCell.keyRoom];
        
        [self.roomsViewControllerDelegate roomsViewController:self didAcceptRoomInviteWithRoomID:invitedRoom.roomId];
    }
    else if ([actionIdentifier isEqualToString:RoomsInviteCell.actionDeclineInvite])
    {
        // Retrieve the invited room
        MXRoom *invitedRoom = userInfo[RoomsInviteCell.keyRoom];
        
        [self cancelEditionModeAndForceTableViewRefreshIfNeeded];
        
        // Decline the invitation
        [invitedRoom leave:^{
            
            [self.recentsTableView reloadData];
            
        } failure:^(NSError *error) {
            
            NSLog(@"[RoomsViewController] Failed to reject an invited room (%@)", invitedRoom.roomId);
            
        }];
    }
}

#pragma mark - 

- (void)scrollToNextRoomWithMissedNotifications
{
    [self scrollToTheTopTheNextRoomWithMissedNotificationsInSection:roomsDataSource.conversationSection];
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [roomsDataSource heightForHeaderInSection:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
#ifdef SUPPORT_KEYS_BACKUP
    if (indexPath.section == roomsDataSource.keyBackupBannerSection)
    {
        switch (roomsDataSource.keyBackupBanner) {
            case KeyBackupBannerSetup:
                [self presentKeyBackupSetup];
                break;
            case KeyBackupBannerRecover:
                [self presentKeyBackupRecover];
                break;
            default:
                break;
        }
    }
    else
#endif
    {
        UITableViewCell* cell = [self.recentsTableView cellForRowAtIndexPath:indexPath];
        
        if ([cell isKindOfClass:[RoomsInviteCell class]])
        {
            // hide the selection
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
        else if (([cell isKindOfClass:[RoomsCell class]]))
        {
            RoomsCell* tableViewCell = (RoomsCell*)cell;
            
            [self.roomsViewControllerDelegate roomsViewController:self didSelectRoomWithID:tableViewCell.roomCellData.roomSummary.roomId];
        }
    }
}

#ifdef SUPPORT_KEYS_BACKUP

#pragma mark - KeyBackupSetupCoordinatorBridgePresenterDelegate

- (void)keyBackupSetupCoordinatorBridgePresenterDelegateDidCancel:(KeyBackupSetupCoordinatorBridgePresenter * _Nonnull)keyBackupSetupCoordinatorBridgePresenter
{
    [keyBackupSetupCoordinatorBridgePresenter dismissWithAnimated:YES];
    self.keyBackupSetupCoordinatorBridgePresenter = nil;
}

- (void)keyBackupSetupCoordinatorBridgePresenterDelegateDidSetupRecoveryKey:(KeyBackupSetupCoordinatorBridgePresenter * _Nonnull)keyBackupSetupCoordinatorBridgePresenter
{
    [keyBackupSetupCoordinatorBridgePresenter dismissWithAnimated:YES];
    self.keyBackupSetupCoordinatorBridgePresenter = nil;
}

- (void)keyBackupRecoverCoordinatorBridgePresenterDidCancel:(KeyBackupRecoverCoordinatorBridgePresenter * _Nonnull)keyBackupRecoverCoordinatorBridgePresenter {
    [keyBackupRecoverCoordinatorBridgePresenter dismissWithAnimated:YES];
    self.keyBackupRecoverCoordinatorBridgePresenter = nil;
}

- (void)keyBackupRecoverCoordinatorBridgePresenterDidRecover:(KeyBackupRecoverCoordinatorBridgePresenter * _Nonnull)keyBackupRecoverCoordinatorBridgePresenter {
    [keyBackupRecoverCoordinatorBridgePresenter dismissWithAnimated:YES];
    self.keyBackupRecoverCoordinatorBridgePresenter = nil;
}

#endif

@end
