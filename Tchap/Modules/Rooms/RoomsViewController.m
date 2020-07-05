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
<SecureBackupSetupCoordinatorBridgePresenterDelegate>
#endif
{
    RoomsDataSource *roomsDataSource;

    // The animated view displayed at the table view bottom when paginating the room directory
    UIView* footerSpinnerView;
}

#ifdef SUPPORT_KEYS_BACKUP
@property (nonatomic, strong) SecureBackupSetupCoordinatorBridgePresenter *secureBackupSetupCoordinatorBridgePresenter;
@property (nonatomic, strong) SecureBackupBannerCell *secureBackupBannerPrototypeCell;
#endif

#ifdef SUPPORT_CROSSSIGNING
@property (nonatomic, strong) CrossSigningSetupBannerCell *keyVerificationSetupBannerPrototypeCell;
@property (nonatomic, strong) AuthenticatedSessionViewControllerFactory *authenticatedSessionViewControllerFactory;
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
    [self.recentsTableView registerNib:SecureBackupBannerCell.nib forCellReuseIdentifier:SecureBackupBannerCell.defaultReuseIdentifier];
    
    // Register key verification banner cells
    [self.recentsTableView registerNib:CrossSigningSetupBannerCell.nib forCellReuseIdentifier:CrossSigningSetupBannerCell.defaultReuseIdentifier];
    
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

- (SecureBackupBannerCell *)secureBackupBannerPrototypeCell
{
    if (!_secureBackupBannerPrototypeCell)
    {
        _secureBackupBannerPrototypeCell = [self.recentsTableView dequeueReusableCellWithIdentifier:SecureBackupBannerCell.defaultReuseIdentifier];
    }
    return _secureBackupBannerPrototypeCell;
}

- (void)presentSecureBackupSetup
{
    SecureBackupSetupCoordinatorBridgePresenter *keyBackupSetupCoordinatorBridgePresenter = [[SecureBackupSetupCoordinatorBridgePresenter alloc] initWithSession:self.mainSession];
    keyBackupSetupCoordinatorBridgePresenter.delegate = self;

    [keyBackupSetupCoordinatorBridgePresenter presentFrom:self animated:YES];

    self.secureBackupSetupCoordinatorBridgePresenter = keyBackupSetupCoordinatorBridgePresenter;
}
#endif

#ifdef SUPPORT_CROSSSIGNING
- (CrossSigningSetupBannerCell *)keyVerificationSetupBannerPrototypeCell
{
    if (!_keyVerificationSetupBannerPrototypeCell)
    {
        _keyVerificationSetupBannerPrototypeCell = [self.recentsTableView dequeueReusableCellWithIdentifier:CrossSigningSetupBannerCell.defaultReuseIdentifier];
    }
    return _keyVerificationSetupBannerPrototypeCell;
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
    if (indexPath.section == recentsDataSource.secureBackupBannerSection)
    {
        switch (recentsDataSource.secureBackupBannerDisplay) {
            case SecureBackupBannerDisplaySetup:
                [self presentSecureBackupSetup];
                break;
            default:
                break;
        }
    }
    else
#endif
#ifdef SUPPORT_CROSSSIGNING
    if (indexPath.section == recentsDataSource.crossSigningBannerSection)
    {
        [self showCrossSigningSetup];
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
#pragma mark - SecureBackupSetupCoordinatorBridgePresenterDelegate

- (void)secureBackupSetupCoordinatorBridgePresenterDelegateDidComplete:(SecureBackupSetupCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [self.secureBackupSetupCoordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.secureBackupSetupCoordinatorBridgePresenter = nil;
}

- (void)secureBackupSetupCoordinatorBridgePresenterDelegateDidCancel:(SecureBackupSetupCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [self.secureBackupSetupCoordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.secureBackupSetupCoordinatorBridgePresenter = nil;
}
#endif

#ifdef SUPPORT_CROSSSIGNING
#pragma mark - Cross-signing setup

- (void)showCrossSigningSetup
{
    [self setupCrossSigningWithTitle:NSLocalizedStringFromTable(@"cross_signing_setup_banner_title", @"Vector", nil) message:NSLocalizedStringFromTable(@"security_settings_user_password_description", @"Vector", nil) success:^{
        
    } failure:^(NSError *error) {
        
    }];
}

- (void)setupCrossSigningWithTitle:(NSString*)title
                           message:(NSString*)message
                           success:(void (^)(void))success
                           failure:(void (^)(NSError *error))failure
{
    __block UIViewController *viewController;
    [self startActivityIndicator];
    self.view.userInteractionEnabled = NO;
    
    void (^animationCompletion)(void) = ^void () {
        [self stopActivityIndicator];
        self.view.userInteractionEnabled = YES;
    };
    
    // Get credentials to set up cross-signing
    NSString *path = [NSString stringWithFormat:@"%@/keys/device_signing/upload", kMXAPIPrefixPathUnstable];
    self.authenticatedSessionViewControllerFactory = [[AuthenticatedSessionViewControllerFactory alloc] initWithSession:self.mainSession];
    [self.authenticatedSessionViewControllerFactory viewControllerForPath:path
                                                           httpMethod:@"POST"
                                                                title:title
                                                              message:message
                                                     onViewController:^(UIViewController * _Nonnull theViewController)
     {
         viewController = theViewController;
         [self presentViewController:viewController animated:YES completion:nil];
         
     } onAuthenticated:^(NSDictionary * _Nonnull authParams) {
         
         [viewController dismissViewControllerAnimated:NO completion:nil];
         viewController = nil;
         
         MXCrossSigning *crossSigning = self.mainSession.crypto.crossSigning;
         if (crossSigning)
         {
             [crossSigning setupWithAuthParams:authParams success:^{
                 animationCompletion();
                 
                 // TODO: Remove this line and refresh key verification setup banner by listening to a local notification cross-signing state change (Add this behavior into the SDK).
                 [self->recentsDataSource setDelegate:self andRecentsDataSourceMode:RecentsDataSourceModeHome];
                 
                 [self refreshRecentsTable];
                 success();
             } failure:^(NSError * _Nonnull error) {
                 animationCompletion();
                 [self refreshRecentsTable];
                 
                 [[AppDelegate theDelegate] showErrorAsAlert:error];
                 failure(error);
             }];
         }
         
     } onCancelled:^{
         animationCompletion();
         
         [viewController dismissViewControllerAnimated:NO completion:nil];
         viewController = nil;
         failure(nil);
     } onFailure:^(NSError * _Nonnull error) {
         
         animationCompletion();
         [[AppDelegate theDelegate] showErrorAsAlert:error];
         
         [viewController dismissViewControllerAnimated:NO completion:nil];
         viewController = nil;
         failure(error);
     }];
}
#endif

@end
