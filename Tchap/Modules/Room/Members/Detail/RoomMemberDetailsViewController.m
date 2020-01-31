/*
 Copyright 2016 OpenMarket Ltd
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

#import "RoomMemberDetailsViewController.h"

#import "RiotDesignValues.h"
#import "Analytics.h"

#import "AvatarGenerator.h"
#import "Tools.h"

#import "TableViewCellWithButton.h"

#import "EncryptionInfoView.h"

#import "GeneratedInterface-Swift.h"

#define TABLEVIEW_ROW_CELL_HEIGHT         46
#define TABLEVIEW_SECTION_HEADER_HEIGHT   28
#define TABLEVIEW_SECTION_HEADER_HEIGHT_WHEN_HIDDEN 0.01f

@interface RoomMemberDetailsViewController () <Stylable>
{
    RoomTitleView* memberTitleView;
    
    /**
     List of the admin actions on this member.
     */
    NSMutableArray<NSNumber*> *adminActionsArray;
    NSInteger adminToolsIndex;
    
    /**
     List of the basic actions on this member.
     */
    NSMutableArray<NSNumber*> *otherActionsArray;
    NSInteger otherActionsIndex;
    
    NSInteger filesIndex;
    
//    /**
//     Devices
//     */
//    NSArray<MXDeviceInfo *> *devicesArray;
//    NSInteger devicesIndex;
//    EncryptionInfoView *encryptionInfoView;
    
    /**
     Observe kRiotDesignValuesDidChangeThemeNotification to handle user interface theme change.
     */
    id kRiotDesignValuesDidChangeThemeNotificationObserver;
    
    /**
     The current visibility of the status bar in this view controller.
     */
    BOOL isStatusBarHidden;
    
    // Files list presenter and its resources
    RoomFilesViewController *filesViewController;
}

@property (nonatomic, strong) id<Style> currentStyle;

@end

@implementation RoomMemberDetailsViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass(self.class)
                          bundle:[NSBundle bundleForClass:self.class]];
}

+ (instancetype)instantiate
{
    RoomMemberDetailsViewController *roomMemberDetailsViewController = [[[self class] alloc] initWithNibName:NSStringFromClass(self.class)
                                          bundle:[NSBundle bundleForClass:self.class]];
    
    roomMemberDetailsViewController.currentStyle = Variant2Style.shared;
    return roomMemberDetailsViewController;
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    adminActionsArray = [[NSMutableArray alloc] init];
    otherActionsArray = [[NSMutableArray alloc] init];
    
    // Keep visible the status bar by default.
    isStatusBarHidden = NO;
}

- (void)setupTitleView {
    
    if (!memberTitleView) {
        RoomTitleView *titleView = [RoomTitleView instantiateWithStyle:Variant2Style.shared];
        self.navigationItem.titleView = titleView;
        memberTitleView = titleView;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Define directly the navigation titleView with the custom title view instance.
    [self setupTitleView];
    
    // Add tap to show the room member avatar in fullscreen
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.roomMemberAvatarMask addGestureRecognizer:tap];
    self.roomMemberAvatarMask.userInteractionEnabled = YES;
    
    // Register collection view cell class
    [self.tableView registerClass:TableViewCellWithButton.class forCellReuseIdentifier:[TableViewCellWithButton defaultReuseIdentifier]];
    //[self.tableView registerClass:DeviceTableViewCell.class forCellReuseIdentifier:[DeviceTableViewCell defaultReuseIdentifier]];
    
    // Hide line separators of empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    // Observe user interface theme change.
    kRiotDesignValuesDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kRiotDesignValuesDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
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
    
    //TODO Design the activvity indicator for Tchap
    self.activityIndicator.backgroundColor = kRiotOverlayColor;
    
    self.memberHeaderView.backgroundColor = style.backgroundColor;
    self.roomMemberStatusLabel.textColor = style.primaryTextColor;
    
    self.tableView.backgroundColor = style.secondaryBackgroundColor;
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

- (BOOL)prefersStatusBarHidden
{
    // Return the current status bar visibility.
    return isStatusBarHidden;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Screen tracking
    [[Analytics sharedInstance] trackScreen:@"RoomMemberDetails"];
    
    if (filesViewController)
    {
        [filesViewController destroy];
        filesViewController = nil;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)destroy
{
    [super destroy];
    
    adminActionsArray = nil;
    otherActionsArray = nil;
    //devicesArray = nil;
    
    if (kRiotDesignValuesDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kRiotDesignValuesDidChangeThemeNotificationObserver];
        kRiotDesignValuesDidChangeThemeNotificationObserver = nil;
    }
    
    [memberTitleView removeFromSuperview];
    memberTitleView = nil;
}

//- (void)viewDidLayoutSubviews
//{
//    [super viewDidLayoutSubviews];
//
//    // Check here whether a subview has been added or removed
//    if (encryptionInfoView)
//    {
//        if (!encryptionInfoView.superview)
//        {
//            // Reset
//            encryptionInfoView = nil;
//
//            // Reload the full table to take into account a potential change on a device status.
//            [self updateMemberInfo];
//        }
//    }
//}

#pragma mark -

- (UIImage*)picturePlaceholder
{
    if (self.mxRoomMember)
    {
        // Use the vector style placeholder
        return [AvatarGenerator generateAvatarForMatrixItem:self.mxRoomMember.userId withDisplayName:self.mxRoomMember.displayname];
    }
    
    return [UIImage imageNamed:@"placeholder"];
}

- (void)updateMemberInfo
{
    if (self.mxRoomMember)
    {
        NSString *memberUserId = self.mxRoomMember.userId;
        if (memberUserId)
        {
            NSString *memberDisplayName = self.mxRoomMember.displayname;
            if (!memberDisplayName.length)
            {
                UserService *userService = [[UserService alloc] initWithSession:self.mainSession];
                User *user = [userService getUserFromLocalSessionWith:memberUserId];
                if (user)
                {
                    memberDisplayName = user.displayName;
                }
                else
                {
                    // If the display name is unknown, build a temporary name from the user id.
                    memberDisplayName = [userService displayNameFrom:memberUserId];
                }
            }
            User *user = [[User alloc] initWithUserId:memberUserId displayName:memberDisplayName avatarStringURL:self.mxRoomMember.avatarUrl];
            RoomTitleViewModelBuilder *titleViewModelBuilder = [[RoomTitleViewModelBuilder alloc] initWithSession:self.mainSession];
            RoomTitleViewModel *titleViewModel = [titleViewModelBuilder buildWithoutAvatarFromUser:user];
            [memberTitleView fillWithRoomTitleViewModel:titleViewModel];
        }
        
        // Update member badge
        MXWeakify(self);
        [self.mxRoom state:^(MXRoomState *roomState) {
            MXStrongifyAndReturnIfNil(self);

            MXRoomPowerLevels *powerLevels = [roomState powerLevels];
            NSInteger powerLevel = [powerLevels powerLevelOfUserWithUserID:self.mxRoomMember.userId];
            if (powerLevel >= RoomPowerLevelAdmin)
            {
                self.memberBadge.image = [UIImage imageNamed:@"admin_icon"];
                self.memberBadge.hidden = NO;
            }
            else if (powerLevel >= RoomPowerLevelModerator)
            {
                self.memberBadge.image = [UIImage imageNamed:@"mod_icon"];
                self.memberBadge.hidden = NO;
            }
            else
            {
                self.memberBadge.hidden = YES;
            }
        }];
        
        NSString* presenceText;
        
//        if (self.mxRoomMember.userId)
//        {
//            MXUser *user = [self.mxRoom.mxSession userWithUserId:self.mxRoomMember.userId];
//            presenceText = [Tools presenceText:user];
//        }
        
        self.roomMemberStatusLabel.text = presenceText;
        
//        // Retrieve member's devices
//        NSString *userId = self.mxRoomMember.userId;
//        __weak typeof(self) weakSelf = self;
//
//        [self.mxRoom.mxSession.crypto downloadKeys:@[userId] forceDownload:NO success:^(MXUsersDevicesMap<MXDeviceInfo *> *usersDevicesInfoMap) {
//
//            if (weakSelf)
//            {
//                // Restore the status bar
//                typeof(self) self = weakSelf;
//                self->devicesArray = usersDevicesInfoMap.map[userId].allValues;
//                // Reload the full table to take into account a potential change on a device status.
//                [super updateMemberInfo];
//            }
//
//        } failure:^(NSError *error) {
//
//            NSLog(@"[RoomMemberDetailsVC] Crypto failed to download device info for user: %@", userId);
//            if (weakSelf)
//            {
//                // Restore the status bar
//                typeof(self) self = weakSelf;
//                // Notify the end user
//                NSString *myUserId = self.mainSession.myUser.userId;
//                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
//            }
//            
//        }];
    }
    
    // Complete data update and reload table view
    [super updateMemberInfo];
}

#pragma mark - TableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sectionCount = 0;
    NSString *myUserId = self.mainSession.myUser.userId;
    NSString *roomMemberId = self.mxRoomMember.userId;
    BOOL showFilesAccess = NO;
    
    // Sanity check
    if (!myUserId || !roomMemberId) {
        return sectionCount;
    }
    
    // Check user's power level before allowing an action (kick, ban, ...)
    MXRoomPowerLevels *powerLevels = [self.mxRoom.dangerousSyncState powerLevels];
    NSInteger memberPowerLevel = [powerLevels powerLevelOfUserWithUserID:roomMemberId];
    NSInteger oneSelfPowerLevel = [powerLevels powerLevelOfUserWithUserID:myUserId];
    
    [adminActionsArray removeAllObjects];
    [otherActionsArray removeAllObjects];
    
    // Consider the case of the user himself
    if ([roomMemberId isEqualToString:myUserId])
    {
        [otherActionsArray addObject:@(MXKRoomMemberDetailsActionLeave)];
        
        if (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomPowerLevels])
        {
            // Check whether the user is admin (in this case he may reduce his power level to become moderator or less, EXCEPT if he is the only admin).
            if (oneSelfPowerLevel >= RoomPowerLevelAdmin)
            {
                NSArray *levelValues = powerLevels.users.allValues;
                NSUInteger adminCount = 0;
                for (NSNumber *valueNumber in levelValues)
                {
                    if ([valueNumber unsignedIntegerValue] >= RoomPowerLevelAdmin)
                    {
                        adminCount ++;
                    }
                }
                
                if (adminCount > 1)
                {
                    [adminActionsArray addObject:@(MXKRoomMemberDetailsActionSetModerator)];
                    [adminActionsArray addObject:@(MXKRoomMemberDetailsActionSetDefaultPowerLevel)];
                }
            }
            // Check whether the user is moderator (in this case he may reduce his power level to become normal user).
            else if (oneSelfPowerLevel >= RoomPowerLevelModerator)
            {
                [adminActionsArray addObject:@(MXKRoomMemberDetailsActionSetDefaultPowerLevel)];
            }
        }
    }
    else if (self.mxRoom.isDirect)
    {
        // In case of a discussion (direct chat) only 2 options are displayed
        // We hack here the historic room member details view controller
        // TODO rewrite this screen in Swift with the actual design
        
        showFilesAccess = YES;
        
        // Check whether the option Ignore may be presented
        if (self.mxRoomMember.membership == MXMembershipJoin)
        {
            // is he already ignored ?
            if (![self.mainSession isUserIgnored:roomMemberId])
            {
                [otherActionsArray addObject:@(MXKRoomMemberDetailsActionIgnore)];
            }
            else
            {
                [otherActionsArray addObject:@(MXKRoomMemberDetailsActionUnignore)];
            }
        }
    }
    else
    {
        UserService *userService = [[UserService alloc] initWithSession:self.mainSession];
        
        // Enumerate admin actions
        switch (self.mxRoomMember.membership)
        {
            case MXMembershipInvite:
            case MXMembershipJoin:
            {
                // update power level
                if (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomPowerLevels] && oneSelfPowerLevel > memberPowerLevel)
                {
                    // Check whether user is admin
                    if (oneSelfPowerLevel >= RoomPowerLevelAdmin)
                    {
                        [adminActionsArray addObject:@(MXKRoomMemberDetailsActionSetAdmin)];
                    }
                    
                    // Check whether the member may become moderator
                    if (oneSelfPowerLevel >= RoomPowerLevelModerator && memberPowerLevel < RoomPowerLevelModerator)
                    {
                        [adminActionsArray addObject:@(MXKRoomMemberDetailsActionSetModerator)];
                    }
                    
                    if (memberPowerLevel >= RoomPowerLevelModerator)
                    {
                        [adminActionsArray addObject:@(MXKRoomMemberDetailsActionSetDefaultPowerLevel)];
                    }
                }
                
                // Check conditions to be able to kick someone
                if (oneSelfPowerLevel >= [powerLevels kick] && oneSelfPowerLevel > memberPowerLevel)
                {
                    [adminActionsArray addObject:@(MXKRoomMemberDetailsActionKick)];
                }
                // Check conditions to be able to ban someone
                if (oneSelfPowerLevel >= [powerLevels ban] && oneSelfPowerLevel > memberPowerLevel)
                {
                    [adminActionsArray addObject:@(MXKRoomMemberDetailsActionBan)];
                }
                
                break;
            }
            case MXMembershipLeave:
            {
                // Check conditions to be able to invite someone
                if (oneSelfPowerLevel >= [powerLevels invite])
                {
                    [adminActionsArray addObject:@(MXKRoomMemberDetailsActionInvite)];
                }
                // Check conditions to be able to ban someone
                if (oneSelfPowerLevel >= [powerLevels ban] && oneSelfPowerLevel > memberPowerLevel)
                {
                    [adminActionsArray addObject:@(MXKRoomMemberDetailsActionBan)];
                }
                break;
            }
            case MXMembershipBan:
            {
                // Check conditions to be able to unban someone
                if (oneSelfPowerLevel >= [powerLevels ban] && oneSelfPowerLevel > memberPowerLevel)
                {
                    [adminActionsArray addObject:@(MXKRoomMemberDetailsActionUnban)];
                }
                break;
            }
            default:
            {
                break;
            }
        }
        
        // Note the external users are not allowed to start chat with another external user.
        // Hide the option "envoyer un message" for the external users when the current user is external too.
        if (![userService isExternalUserFor:myUserId] || ![userService isExternalUserFor:roomMemberId])
        {
            // Use the action startChat to open the current discussion with this member.
            [otherActionsArray addObject:@(MXKRoomMemberDetailsActionStartChat)];
        }
        
        // List the other actions
        if (self.enableVoipCall)
        {
            // Offer voip call options
            [otherActionsArray addObject:@(MXKRoomMemberDetailsActionStartVoiceCall)];
            [otherActionsArray addObject:@(MXKRoomMemberDetailsActionStartVideoCall)];
        }
        
        // Check whether the option Ignore may be presented
        if (self.mxRoomMember.membership == MXMembershipJoin)
        {
            // is he already ignored ?
            if (![self.mainSession isUserIgnored:roomMemberId])
            {
                [otherActionsArray addObject:@(MXKRoomMemberDetailsActionIgnore)];
            }
            else
            {
                [otherActionsArray addObject:@(MXKRoomMemberDetailsActionUnignore)];
            }
        }
        
        if (self.enableMention)
        {
            // Add mention option
            [otherActionsArray addObject:@(MXKRoomMemberDetailsActionMention)];
        }
    }
    
    adminToolsIndex = otherActionsIndex = filesIndex = -1;
    //devicesIndex = -1;
    
    if (showFilesAccess)
    {
        filesIndex = sectionCount++;
    }
    if (otherActionsArray.count)
    {
        otherActionsIndex = sectionCount++;
    }
    if (adminActionsArray.count)
    {
        adminToolsIndex = sectionCount++;
    }
    
//    if (devicesArray.count)
//    {
//        devicesIndex = sectionCount++;
//    }
    
    return sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == adminToolsIndex)
    {
        return adminActionsArray.count;
    }
    else if (section == otherActionsIndex)
    {
        return otherActionsArray.count;
    }
    else if (section == filesIndex)
    {
        return 1;
    }
//    else if (section == devicesIndex)
//    {
//        return (devicesArray.count);
//    }
    
    return 0;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == adminToolsIndex)
    {
        return NSLocalizedStringFromTable(@"room_participants_action_section_admin_tools", @"Vector", nil);
    }
//    else if (section == devicesIndex)
//    {
//        return NSLocalizedStringFromTable(@"room_participants_action_section_devices", @"Vector", nil);
//    }
    
    return nil;
}

- (NSString*)actionButtonTitle:(MXKRoomMemberDetailsAction)action
{
    NSString *title;
    
    switch (action)
    {
        case MXKRoomMemberDetailsActionInvite:
            title = NSLocalizedStringFromTable(@"room_participants_action_invite", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionLeave:
            title = NSLocalizedStringFromTable(@"room_participants_action_leave", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionKick:
            title = NSLocalizedStringFromTable(@"room_participants_action_remove", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionBan:
            title = NSLocalizedStringFromTable(@"room_participants_action_ban", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionUnban:
            title = NSLocalizedStringFromTable(@"room_participants_action_unban", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionIgnore:
            title = NSLocalizedStringFromTable(@"room_participants_action_ignore", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionUnignore:
            title = NSLocalizedStringFromTable(@"room_participants_action_unignore", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionSetDefaultPowerLevel:
            title = NSLocalizedStringFromTable(@"room_participants_action_set_default_power_level", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionSetModerator:
            title = NSLocalizedStringFromTable(@"room_participants_action_set_moderator", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionSetAdmin:
            title = NSLocalizedStringFromTable(@"room_participants_action_set_admin", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionStartChat:
            title = NSLocalizedStringFromTable(@"room_member_details_action_chat", @"Tchap", nil);
            break;
        case MXKRoomMemberDetailsActionStartVoiceCall:
            title = NSLocalizedStringFromTable(@"room_participants_action_start_voice_call", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionStartVideoCall:
            title = NSLocalizedStringFromTable(@"room_participants_action_start_video_call", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionMention:
            title = NSLocalizedStringFromTable(@"room_participants_action_mention", @"Vector", nil);
            break;
        default:
            break;
    }
    
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (indexPath.section == adminToolsIndex || indexPath.section == otherActionsIndex)
    {
        TableViewCellWithButton *cellWithButton = [tableView dequeueReusableCellWithIdentifier:[TableViewCellWithButton defaultReuseIdentifier] forIndexPath:indexPath];
        
        NSNumber *actionNumber;
        if (indexPath.section == adminToolsIndex && indexPath.row < adminActionsArray.count)
        {
            actionNumber = [adminActionsArray objectAtIndex:indexPath.row];
        }
        else if (indexPath.section == otherActionsIndex && indexPath.row < otherActionsArray.count)
        {
            actionNumber = [otherActionsArray objectAtIndex:indexPath.row];
        }
        
        if (actionNumber)
        {
            NSString *title = [self actionButtonTitle:actionNumber.unsignedIntegerValue];
            
            [cellWithButton.mxkButton setTitle:title forState:UIControlStateNormal];
            [cellWithButton.mxkButton setTitle:title forState:UIControlStateHighlighted];
            
            if (actionNumber.unsignedIntegerValue == MXKRoomMemberDetailsActionKick)
            {
                [cellWithButton.mxkButton setTitleColor:kRiotColorPinkRed forState:UIControlStateNormal];
                [cellWithButton.mxkButton setTitleColor:kRiotColorPinkRed forState:UIControlStateHighlighted];
            }
            else
            {
                [cellWithButton.mxkButton setTitleColor:kRiotPrimaryTextColor forState:UIControlStateNormal];
                [cellWithButton.mxkButton setTitleColor:kRiotPrimaryTextColor forState:UIControlStateHighlighted];
            }
            
            [cellWithButton.mxkButton addTarget:self action:@selector(onActionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            
            cellWithButton.mxkButton.tag = actionNumber.unsignedIntegerValue;
        }
        
        cell = cellWithButton;
    }
    else if (indexPath.section == filesIndex)
    {
        TableViewCellWithButton *cellWithButton = [tableView dequeueReusableCellWithIdentifier:[TableViewCellWithButton defaultReuseIdentifier] forIndexPath:indexPath];
        
        NSString *title = NSLocalizedStringFromTable(@"room_member_details_files", @"Tchap", nil);
        
        [cellWithButton.mxkButton setTitle:title forState:UIControlStateNormal];
        [cellWithButton.mxkButton setTitle:title forState:UIControlStateHighlighted];
        [cellWithButton.mxkButton setTitleColor:kRiotPrimaryTextColor forState:UIControlStateNormal];
        [cellWithButton.mxkButton setTitleColor:kRiotPrimaryTextColor forState:UIControlStateHighlighted];
        
        [cellWithButton.mxkButton addTarget:self action:@selector(onFilesButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        cell = cellWithButton;
    }
//    else if (indexPath.section == devicesIndex)
//    {
//        DeviceTableViewCell *deviceCell = [tableView dequeueReusableCellWithIdentifier:[DeviceTableViewCell defaultReuseIdentifier] forIndexPath:indexPath];
//        deviceCell.selectionStyle = UITableViewCellSelectionStyleNone;
//
//        if (indexPath.row < devicesArray.count)
//        {
//            MXDeviceInfo *deviceInfo = devicesArray[indexPath.row];
//            [deviceCell render:deviceInfo];
//            deviceCell.delegate = self;
//
//            // Display here the Verify and Block buttons except if the device is the current one.
//            deviceCell.verifyButton.hidden = deviceCell.blockButton.hidden = [deviceInfo.deviceId isEqualToString:self.mxRoom.mxSession.matrixRestClient.credentials.deviceId];
//        }
//        cell = deviceCell;
//    }
    else
    {
        // Create a fake cell to prevent app from crashing
        cell = [[UITableViewCell alloc] init];
    }
    
    return cell;
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    if (indexPath.section == devicesIndex)
//    {
//        if (indexPath.row < devicesArray.count)
//        {
//            return [DeviceTableViewCell cellHeightWithDeviceInfo:devicesArray[indexPath.row] andCellWidth:self.tableView.frame.size.width];
//        }
//    }
    
    return TABLEVIEW_ROW_CELL_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == otherActionsIndex || section == filesIndex)
    {
        return TABLEVIEW_SECTION_HEADER_HEIGHT_WHEN_HIDDEN;
    }
    
    return TABLEVIEW_SECTION_HEADER_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == filesIndex)
    {
        return TABLEVIEW_SECTION_HEADER_HEIGHT_WHEN_HIDDEN;
    }
    
    return TABLEVIEW_SECTION_HEADER_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    if (indexPath.section == filesIndex)
    {
        [self onFilesButtonPressed:nil];
    }
    else
    {
        UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
        if (selectedCell && [selectedCell isKindOfClass:TableViewCellWithButton.class])
        {
            TableViewCellWithButton *cell = (TableViewCellWithButton*)selectedCell;
            
            [self onActionButtonPressed:cell.mxkButton];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Action

- (void)onActionButtonPressed:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        // already a pending action
        if ([self hasPendingAction])
        {
            return;
        }
        
        UIButton *button = (UIButton*)sender;
        
        switch (button.tag)
        {
            case MXKRoomMemberDetailsActionSetDefaultPowerLevel:
            {
                [self.mxRoom state:^(MXRoomState *roomState) {
                    [self setPowerLevel:roomState.powerLevels.usersDefault promptUser:YES];
                }];
                break;
            }
            case MXKRoomMemberDetailsActionSetModerator:
            {
                [self setPowerLevel:RoomPowerLevelModerator promptUser:YES];
                break;
            }
            case MXKRoomMemberDetailsActionSetAdmin:
            {
                [self setPowerLevel:RoomPowerLevelAdmin promptUser:YES];
                break;
            }
            case MXKRoomMemberDetailsActionBan:
            {
                __weak typeof(self) weakSelf = self;
                
                // Ban
                currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"room_event_action_ban_prompt_reason", @"Vector", nil)
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
                
                [currentAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                    textField.secureTextEntry = NO;
                    textField.placeholder = nil;
                    textField.keyboardType = UIKeyboardTypeDefault;
                }];
                
                [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       self->currentAlert = nil;
                                                                   }
                                                                   
                                                               }]];
                
                [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ban"]
                                                                 style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                     
                                                                     if (weakSelf)
                                                                     {
                                                                         typeof(self) self = weakSelf;
                                                                         self->currentAlert = nil;
                                                                         
                                                                         [self startActivityIndicator];
                                                                         
                                                                         // kick user
                                                                         UITextField *textField = [self->currentAlert textFields].firstObject;
                                                                         [self.mxRoom banUser:self.mxRoomMember.userId reason:textField.text success:^{
                                                                             
                                                                             __strong __typeof(weakSelf)self = weakSelf;
                                                                             [self stopActivityIndicator];
                                                                             
                                                                         } failure:^(NSError *error) {
                                                                             
                                                                             __strong __typeof(weakSelf)self = weakSelf;
                                                                             [self stopActivityIndicator];
                                                                             
                                                                             NSLog(@"[RoomMemberDetailVC] Ban user (%@) failed", self.mxRoomMember.userId);
                                                                             //Alert user
                                                                             [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                             
                                                                         }];
                                                                     }
                                                                     
                                                                 }]];
                
                [currentAlert mxk_setAccessibilityIdentifier:@"RoomMemberDetailsVCBanAlert"];
                [self presentViewController:currentAlert animated:YES completion:nil];
                break;
            }
            case MXKRoomMemberDetailsActionKick:
            {
                __weak typeof(self) weakSelf = self;
                
                // Kick
                currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"room_event_action_kick_prompt_reason", @"Vector", nil)
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
                
                [currentAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                    textField.secureTextEntry = NO;
                    textField.placeholder = nil;
                    textField.keyboardType = UIKeyboardTypeDefault;
                }];
                
                [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       self->currentAlert = nil;
                                                                   }
                                                                   
                                                               }]];
                
                [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"remove", @"Vector", nil)
                                                                 style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       self->currentAlert = nil;
                                                                       
                                                                       [self startActivityIndicator];
                                                                       
                                                                       // kick user
                                                                       UITextField *textField = [self->currentAlert textFields].firstObject;
                                                                       [self.mxRoom kickUser:self.mxRoomMember.userId reason:textField.text success:^{
                                                                           
                                                                           __strong __typeof(weakSelf)self = weakSelf;
                                                                           [self stopActivityIndicator];
                                                                           
                                                                       } failure:^(NSError *error) {
                                                                           
                                                                           __strong __typeof(weakSelf)self = weakSelf;
                                                                           [self stopActivityIndicator];
                                                                           
                                                                           NSLog(@"[RoomMemberDetailVC] Removing user (%@) failed", self.mxRoomMember.userId);
                                                                           //Alert user
                                                                           [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                           
                                                                       }];
                                                                   }
                                                                   
                                                               }]];
                
                [currentAlert mxk_setAccessibilityIdentifier:@"RoomMemberDetailsVCKickAlert"];
                [self presentViewController:currentAlert animated:YES completion:nil];
                break;
            }
            default:
            {
                [super onActionButtonPressed:sender];
            }
        }
    }
}

- (void)onFilesButtonPressed:(id)sender
{
    // Push the files list presenter.
    filesViewController = [RoomFilesViewController instantiate];
    
    MXWeakify(self);
    [MXKRoomDataSource loadRoomDataSourceWithRoomId:self.mxRoom.roomId andMatrixSession:self.mainSession onComplete:^(id roomDataSource) {
        MXStrongifyAndReturnIfNil(self);
        if ([roomDataSource isKindOfClass:[MXKRoomDataSource class]])
        {
            MXKRoomDataSource *filesDataSource = (MXKRoomDataSource*)roomDataSource;
            filesDataSource.filterMessagesWithURL = true;
            // Give the data source ownership to the room files view controller.
            self->filesViewController.hasRoomDataSourceOwnership = true;
            [self->filesViewController displayRoom:filesDataSource];
        }
    }];
    
    // Hide back button title
    self.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    [self.navigationController pushViewController:filesViewController animated:YES];
}

- (void)handleTapGesture:(UITapGestureRecognizer*)tapGestureRecognizer
{
    UIView *view = tapGestureRecognizer.view;
    
    if (view == self.roomMemberAvatarMask)
    {
        MXWeakify(self);
        
        // Show the avatar in full screen
        __block MXKImageView * avatarFullScreenView = [[MXKImageView alloc] initWithFrame:CGRectZero];
        avatarFullScreenView.stretchable = YES;

        [avatarFullScreenView setRightButtonTitle:[NSBundle mxk_localizedStringForKey:@"ok"] handler:^(MXKImageView* imageView, NSString* buttonTitle) {
             MXStrongifyAndReturnIfNil(self);
             
             [avatarFullScreenView dismissSelection];
             [avatarFullScreenView removeFromSuperview];
             
             avatarFullScreenView = nil;
             
             // Restore the status bar
             self->isStatusBarHidden = NO;
             [self setNeedsStatusBarAppearanceUpdate];
        }];

        [avatarFullScreenView setImageURI:self.mxRoomMember.avatarUrl
                                 withType:nil
                      andImageOrientation:UIImageOrientationUp
                             previewImage:self.memberThumbnail.image
                             mediaManager:self.mainSession.mediaManager];

        [avatarFullScreenView showFullScreen];
        
        // Hide the status bar
        isStatusBarHidden = YES;
        // Trigger status bar update
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

//#pragma mark - DeviceTableViewCellDelegate
//
//- (void)deviceTableViewCell:(DeviceTableViewCell*)deviceTableViewCell updateDeviceVerification:(MXDeviceVerification)verificationStatus
//{
//    if (verificationStatus == MXDeviceVerified)
//    {
//        // Prompt the user before marking as verified the device.
//        encryptionInfoView = [[EncryptionInfoView alloc] initWithDeviceInfo:deviceTableViewCell.deviceInfo andMatrixSession:self.mxRoom.mxSession];
//        [encryptionInfoView onButtonPressed:encryptionInfoView.verifyButton];
//
//        // Add shadow on added view
//        encryptionInfoView.layer.cornerRadius = 5;
//        encryptionInfoView.layer.shadowOffset = CGSizeMake(0, 1);
//        encryptionInfoView.layer.shadowOpacity = 0.5f;
//
//        // Add the view and define edge constraints
//        [self.view addSubview:encryptionInfoView];
//
//        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:encryptionInfoView
//                                                              attribute:NSLayoutAttributeTop
//                                                              relatedBy:NSLayoutRelationEqual
//                                                                 toItem:self.tableView
//                                                              attribute:NSLayoutAttributeTop
//                                                             multiplier:1.0f
//                                                               constant:10.0f]];
//
//        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:encryptionInfoView
//                                                              attribute:NSLayoutAttributeBottom
//                                                              relatedBy:NSLayoutRelationEqual
//                                                                 toItem:self.tableView
//                                                              attribute:NSLayoutAttributeBottom
//                                                             multiplier:1.0f
//                                                               constant:-10.0f]];
//
//        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
//                                                              attribute:NSLayoutAttributeLeading
//                                                              relatedBy:NSLayoutRelationEqual
//                                                                 toItem:encryptionInfoView
//                                                              attribute:NSLayoutAttributeLeading
//                                                             multiplier:1.0f
//                                                               constant:-10.0f]];
//
//        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
//                                                              attribute:NSLayoutAttributeTrailing
//                                                              relatedBy:NSLayoutRelationEqual
//                                                                 toItem:encryptionInfoView
//                                                              attribute:NSLayoutAttributeTrailing
//                                                             multiplier:1.0f
//                                                               constant:10.0f]];
//        [self.view setNeedsUpdateConstraints];
//    }
//    else
//    {
//        [self.mxRoom.mxSession.crypto setDeviceVerification:verificationStatus
//                                                  forDevice:deviceTableViewCell.deviceInfo.deviceId
//                                                     ofUser:self.mxRoomMember.userId
//                                                    success:^{
//                                                        [self updateMemberInfo];
//                                                    } failure:nil];
//    }
//}

@end
