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

#import "AppDelegate.h"

#import "RoomsDataSource.h"

#import "DirectoryServerPickerViewController.h"

#import "InviteRecentTableViewCell.h"
#import "RoomIdOrAliasTableViewCell.h"

@interface RoomsViewController ()
{
    RoomsDataSource *roomsDataSource;

    // The animated view displayed at the table view bottom when paginating the room directory
    UIView* footerSpinnerView;
}
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
    
    // Add the (+) button programmatically
    [self addPlusButton];
    
    self.enableStickyHeaders = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];        
    
    if ([self.dataSource isKindOfClass:RoomsDataSource.class])
    {
        BOOL isFirstTime = (roomsDataSource != self.dataSource);

        // Take the lead on the shared data source.
        roomsDataSource = (RoomsDataSource*)self.dataSource;
        roomsDataSource.areSectionsShrinkable = NO;
        
        if (isFirstTime)
        {
            // The first time the screen is displayed, make publicRoomsDirectoryDataSource
            // start loading data
            [roomsDataSource.publicRoomsDirectoryDataSource paginate:nil failure:nil];
        }
    }
}

- (void)dealloc
{
    
}

- (void)destroy
{
    [super destroy];
}

#pragma mark - Override RecentsViewController

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
    if ([actionIdentifier isEqualToString:kRecentsDataSourceTapOnDirectoryServerChange])
    {        
        [self.roomsViewControllerDelegate roomsViewControllerDidSelectDirectoryServerPicker:self];
//        [self performSegueWithIdentifier:@"presentDirectoryServerPicker" sender:self];
    }    
    else if ([actionIdentifier isEqualToString:kInviteRecentTableViewCellJoinButtonPressed])
    {
        // Retrieve the invited room
        MXRoom *invitedRoom = userInfo[kInviteRecentTableViewCellRoomKey];
        
        [self.roomsViewControllerDelegate roomsViewController:self didAcceptRoomInviteWithRoomID:invitedRoom.roomId];
    }
    else if ([actionIdentifier isEqualToString:kInviteRecentTableViewCellDeclineButtonPressed])
    {
        // Retrieve the invited room
        MXRoom *invitedRoom = userInfo[kInviteRecentTableViewCellRoomKey];
        
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

#pragma mark - Navigation

// Tchap: Handle navigation in RoomsCoordinator
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//    [super prepareForSegue:segue sender:sender];
//
//    UIViewController *pushedViewController = [segue destinationViewController];
//
//    if ([[segue identifier] isEqualToString:@"presentDirectoryServerPicker"])
//    {
//        UINavigationController *pushedNavigationViewController = (UINavigationController*)pushedViewController;
//        DirectoryServerPickerViewController* directoryServerPickerViewController = (DirectoryServerPickerViewController*)pushedNavigationViewController.viewControllers.firstObject;
//
//        MXKDirectoryServersDataSource *directoryServersDataSource = [[MXKDirectoryServersDataSource alloc] initWithMatrixSession:roomsDataSource.publicRoomsDirectoryDataSource.mxSession];
//        [directoryServersDataSource finalizeInitialization];
//
//        // Add directory servers from the app settings plist
//        NSArray<NSString*> *roomDirectoryServers = [[NSUserDefaults standardUserDefaults] objectForKey:@"roomDirectoryServers"];
//        directoryServersDataSource.roomDirectoryServers = roomDirectoryServers;
//
//        __weak typeof(self) weakSelf = self;
//
//        [directoryServerPickerViewController displayWithDataSource:directoryServersDataSource onComplete:^(id<MXKDirectoryServerCellDataStoring> cellData) {
//            if (weakSelf && cellData)
//            {
//                typeof(self) self = weakSelf;
//
//                // Use the selected directory server
//                if (cellData.thirdPartyProtocolInstance)
//                {
//                    self->roomsDataSource.publicRoomsDirectoryDataSource.thirdpartyProtocolInstance = cellData.thirdPartyProtocolInstance;
//                }
//                else if (cellData.homeserver)
//                {
//                    self->roomsDataSource.publicRoomsDirectoryDataSource.includeAllNetworks = cellData.includeAllNetworks;
//                    self->roomsDataSource.publicRoomsDirectoryDataSource.homeserver = cellData.homeserver;
//                }
//
//                // Refresh data
//                [self addSpinnerFooterView];
//
//                [self->roomsDataSource.publicRoomsDirectoryDataSource paginate:^(NSUInteger roomsAdded) {
//
//                    if (weakSelf)
//                    {
//                        typeof(self) self = weakSelf;
//
//                        // The table view is automatically filled
//                        [self removeSpinnerFooterView];
//
//                        // Make the directory section appear full-page
//                        [self.recentsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:self->roomsDataSource.directorySection] atScrollPosition:UITableViewScrollPositionTop animated:YES];
//                    }
//
//                } failure:^(NSError *error) {
//
//                    if (weakSelf)
//                    {
//                        typeof(self) self = weakSelf;
//                        [self removeSpinnerFooterView];
//                    }
//                }];
//            }
//        }];
//
//        // Hide back button title
//        pushedViewController.navigationController.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
//    }
//}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == roomsDataSource.directorySection)
    {
        // Let the recents dataSource provide the height of this section header
        return [roomsDataSource heightForHeaderInSection:section];
    }

    return [super tableView:tableView heightForHeaderInSection:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [self.recentsTableView cellForRowAtIndexPath:indexPath];
    
    if (indexPath.section == roomsDataSource.directorySection)
    {
        // Sanity check
        MXPublicRoom *publicRoom = [roomsDataSource.publicRoomsDirectoryDataSource roomAtIndexPath:indexPath];
        if (publicRoom)
        {
            [self.roomsViewControllerDelegate roomsViewController:self didSelectPublicRoom:publicRoom];
//            [self openPublicRoomAtIndexPath:indexPath];
        }
    }
    else if ([cell isKindOfClass:[InviteRecentTableViewCell class]])
    {
        // hide the selection
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    else if (([cell isKindOfClass:[RecentTableViewCell class]]))
    {
        RecentTableViewCell* recentTableViewCell = (RecentTableViewCell*)cell;
        id<MXKRecentCellDataStoring> recentCellData = (id<MXKRecentCellDataStoring>)recentTableViewCell.renderedCellData;
        
        [self.roomsViewControllerDelegate roomsViewController:self didSelectRoomWithID:recentCellData.roomSummary.roomId];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
        // Trigger inconspicuous pagination on directy when user scrolls down
    if ((scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.frame.size.height) < 300)
    {
        [self triggerDirectoryPagination];
    }
    
    [super scrollViewDidScroll:scrollView];
}

#pragma mark - Private methods

// Tchap: Handle navigation in RoomsCoordinator
//- (void)openPublicRoomAtIndexPath:(NSIndexPath *)indexPath
//{
//    MXPublicRoom *publicRoom = [roomsDataSource.publicRoomsDirectoryDataSource roomAtIndexPath:indexPath];
//
//    // Check whether the user has already joined the selected public room
//    if ([roomsDataSource.publicRoomsDirectoryDataSource.mxSession roomWithRoomId:publicRoom.roomId])
//    {
//        // Open the public room
//        [[AppDelegate theDelegate].masterTabBarController selectRoomWithId:publicRoom.roomId andEventId:nil inMatrixSession:roomsDataSource.publicRoomsDirectoryDataSource.mxSession];
//    }
//    else
//    {
//        // Preview the public room
//        if (publicRoom.worldReadable)
//        {
//            RoomPreviewData *roomPreviewData = [[RoomPreviewData alloc] initWithRoomId:publicRoom.roomId andSession:roomsDataSource.publicRoomsDirectoryDataSource.mxSession];
//
//            [self startActivityIndicator];
//
//            // Try to get more information about the room before opening its preview
//            [roomPreviewData peekInRoom:^(BOOL succeeded) {
//
//                [self stopActivityIndicator];
//
//                [[AppDelegate theDelegate].masterTabBarController showRoomPreview:roomPreviewData];
//            }];
//        }
//        else
//        {
//            RoomPreviewData *roomPreviewData = [[RoomPreviewData alloc] initWithPublicRoom:publicRoom andSession:roomsDataSource.publicRoomsDirectoryDataSource.mxSession];
//            [[AppDelegate theDelegate].masterTabBarController showRoomPreview:roomPreviewData];
//        }
//    }
//}

- (void)triggerDirectoryPagination
{
    if (!roomsDataSource
        || roomsDataSource.state == MXKDataSourceStateUnknown
        || roomsDataSource.publicRoomsDirectoryDataSource.hasReachedPaginationEnd
        || footerSpinnerView)
    {
        // We are not yet ready or being killed or we got all public rooms or we are already paginating
        // Do nothing
        return;
    }

    [self addSpinnerFooterView];

    [roomsDataSource.publicRoomsDirectoryDataSource paginate:^(NSUInteger roomsAdded) {

        // The table view is automatically filled
        [self removeSpinnerFooterView];

    } failure:^(NSError *error) {

        [self removeSpinnerFooterView];
    }];
}

- (void)addSpinnerFooterView
{
    if (!footerSpinnerView)
    {
        UIActivityIndicatorView* spinner  = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        spinner.transform = CGAffineTransformMakeScale(0.75f, 0.75f);
        CGRect frame = spinner.frame;
        frame.size.height = 80; // 80 * 0.75 = 60
        spinner.bounds = frame;

        spinner.color = [UIColor darkGrayColor];
        spinner.hidesWhenStopped = NO;
        spinner.backgroundColor = [UIColor clearColor];
        [spinner startAnimating];

        // No need to manage constraints here, iOS defines them
        self.recentsTableView.tableFooterView = footerSpinnerView = spinner;
    }
}

- (void)removeSpinnerFooterView
{
    if (footerSpinnerView)
    {
        footerSpinnerView = nil;

        // Hide line separators of empty cells
        self.recentsTableView.tableFooterView = [[UIView alloc] init];;
    }
}

@end
