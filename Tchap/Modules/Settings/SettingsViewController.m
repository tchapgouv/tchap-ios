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

#import "SettingsViewController.h"

#import <MatrixKit/MatrixKit.h>

#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <OLMKit/OLMKit.h>
#import <Photos/Photos.h>

#import "AvatarGenerator.h"

#import "BugReportViewController.h"

#import "WebViewViewController.h"

#import "CountryPickerViewController.h"
#import "LanguagePickerViewController.h"
#import "DeactivateAccountViewController.h"

#import "NBPhoneNumberUtil.h"
#import "RageShakeManager.h"
#import "RiotDesignValues.h"
#import "TableViewCellWithPhoneNumberTextField.h"

#import "GBDeviceInfo_iOS.h"

#import "DeviceView.h"
#import "MediaPickerViewController.h"

#import "GeneratedInterface-Swift.h"

NSString* const kSettingsViewControllerPhoneBookCountryCellId = @"kSettingsViewControllerPhoneBookCountryCellId";

enum
{
    SETTINGS_SECTION_SIGN_OUT_INDEX = 0,
    SETTINGS_SECTION_USER_SETTINGS_INDEX,
    SETTINGS_SECTION_NOTIFICATIONS_SETTINGS_INDEX,
    //SETTINGS_SECTION_CALLS_INDEX, // Tchap: voip call are disabled for the moment.
    SETTINGS_SECTION_IGNORED_USERS_INDEX,
    SETTINGS_SECTION_CONTACTS_INDEX,
    SETTINGS_SECTION_OTHER_INDEX,
    SETTINGS_SECTION_CRYPTOGRAPHY_INDEX,
    SETTINGS_SECTION_DEVICES_INDEX,
    SETTINGS_SECTION_DEACTIVATE_ACCOUNT_INDEX,
    SETTINGS_SECTION_COUNT
};

enum
{
    NOTIFICATION_SETTINGS_ENABLE_PUSH_INDEX = 0,
    NOTIFICATION_SETTINGS_SHOW_DECODED_CONTENT,
    NOTIFICATION_SETTINGS_GLOBAL_SETTINGS_INDEX,
    //NOTIFICATION_SETTINGS_CONTAINING_MY_USER_NAME_INDEX,
    //NOTIFICATION_SETTINGS_CONTAINING_MY_DISPLAY_NAME_INDEX,
    //NOTIFICATION_SETTINGS_SENT_TO_ME_INDEX,
    //NOTIFICATION_SETTINGS_INVITED_TO_ROOM_INDEX,
    //NOTIFICATION_SETTINGS_PEOPLE_LEAVE_JOIN_INDEX,
    //NOTIFICATION_SETTINGS_CALL_INVITATION_INDEX,
    NOTIFICATION_SETTINGS_COUNT
};

enum
{
    CALLS_ENABLE_CALLKIT_INDEX = 0,
    CALLS_DESCRIPTION_INDEX,
    CALLS_COUNT
};

enum
{
    OTHER_VERSION_INDEX = 0,
    OTHER_TERM_CONDITIONS_INDEX,
    OTHER_THIRD_PARTY_INDEX,
    //OTHER_CRASH_REPORT_INDEX,
    //OTHER_ENABLE_RAGESHAKE_INDEX,
    OTHER_MARK_ALL_AS_READ_INDEX,
    OTHER_CLEAR_CACHE_INDEX,
    OTHER_REPORT_BUG_INDEX,
    OTHER_COUNT
};

enum {
    CRYPTOGRAPHY_INFO_INDEX = 0,
    CRYPTOGRAPHY_EXPORT_INDEX,
    CRYPTOGRAPHY_COUNT
};

#define SECTION_TITLE_PADDING_WHEN_HIDDEN 0.01f

typedef void (^blockSettingsViewController_onReadyToDestroy)(void);


@interface SettingsViewController () <UITextFieldDelegate, MediaPickerViewControllerDelegate, MXKDeviceViewDelegate, UIDocumentInteractionControllerDelegate, MXKCountryPickerViewControllerDelegate, MXKLanguagePickerViewControllerDelegate, DeactivateAccountViewControllerDelegate, Stylable>
{
    // Current alert (if any).
    UIAlertController *currentAlert;
    
    // picker
    MediaPickerViewController* mediaPicker;
    
    // profile updates
    // avatar
    UIImage* newAvatarImage;
    // the avatar image has been uploaded
    NSString* uploadedAvatarURL;
    
    // password update
    UITextField* currentPasswordTextField;
    UITextField* newPasswordTextField1;
    UITextField* newPasswordTextField2;
    UIAlertAction* savePasswordAction;
    
    // Dynamic rows in the user settings section
    NSInteger userSettingsProfilePictureIndex;
    NSInteger userSettingsDisplayNameIndex;
    NSInteger userSettingsFirstNameIndex;
    NSInteger userSettingsSurnameIndex;
    NSInteger userSettingsEmailStartIndex;  // The user can have several linked emails. Hence, the dynamic section items count
    NSInteger userSettingsPhoneStartIndex;  // The user can have several linked phone numbers. Hence, the dynamic section items count
    NSInteger userSettingsChangePasswordIndex;
    NSInteger userSettingsNightModeSepIndex;
    NSInteger userSettingsNightModeIndex;
    NSInteger userSettingsHideFromUsersDirIndex;
    
    // Dynamic rows in the local contacts section
    NSInteger localContactsSyncIndex;
    NSInteger localContactsPhoneBookCountryIndex;
    
    // Devices
    NSMutableArray<MXDevice *> *devicesArray;
    DeviceView *deviceView;
    
    //
    UIAlertController *resetPwdAlertController;

    // The view used to export e2e keys
    MXKEncryptionKeysExportView *exportView;

    // The document interaction Controller used to export e2e keys
    UIDocumentInteractionController *documentInteractionController;
    NSURL *keyExportsFile;
    NSTimer *keyExportsFileDeletionTimer;
}

@property (weak, nonatomic) DeactivateAccountViewController *deactivateAccountViewController;
@property (strong, nonatomic) id<Style> currentStyle;

// Observer
@property (nonatomic, weak) id riotDesignValuesDidChangeThemeNotificationObserver;
@property (nonatomic, weak) id removedAccountObserver;
@property (nonatomic, weak) id accountUserInfoObserver;
@property (nonatomic, weak) id pushInfoUpdateObserver;
@property (nonatomic, weak) id appDelegateDidTapStatusBarNotificationObserver;
@property (nonatomic, weak) id sessionAccountDataDidChangeNotificationObserver;

@end

@implementation SettingsViewController

+ (instancetype)instantiate
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    SettingsViewController *settingsViewController = [storyboard instantiateViewControllerWithIdentifier:@"SettingsViewController"];
    settingsViewController.currentStyle = Variant1Style.shared;
    return settingsViewController;
}

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
    
    self.navigationItem.title = NSLocalizedStringFromTable(@"settings_title", @"Vector", nil);
    
    // Remove back bar button title when pushing a view controller
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    [self.tableView registerClass:MXKTableViewCellWithLabelAndTextField.class forCellReuseIdentifier:[MXKTableViewCellWithLabelAndTextField defaultReuseIdentifier]];
    [self.tableView registerClass:MXKTableViewCellWithLabelAndSwitch.class forCellReuseIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier]];
    [self.tableView registerClass:MXKTableViewCellWithLabelAndMXKImageView.class forCellReuseIdentifier:[MXKTableViewCellWithLabelAndMXKImageView defaultReuseIdentifier]];
    [self.tableView registerClass:TableViewCellWithPhoneNumberTextField.class forCellReuseIdentifier:[TableViewCellWithPhoneNumberTextField defaultReuseIdentifier]];
    [self.tableView registerNib:MXKTableViewCellWithTextView.nib forCellReuseIdentifier:[MXKTableViewCellWithTextView defaultReuseIdentifier]];
    
    // Enable self sizing cells
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 50;
    
    // Add each matrix session, to update the view controller appearance according to mx sessions state
    NSArray *sessions = [AppDelegate theDelegate].mxSessions;
    for (MXSession *mxSession in sessions)
    {
        [self addMatrixSession:mxSession];
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(onSave:)];
    self.navigationItem.rightBarButtonItem.accessibilityIdentifier=@"SettingsVCNavBarSaveButton";

    
    // Observe user interface theme change.
    MXWeakify(self);
    _riotDesignValuesDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kRiotDesignValuesDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
    
    
    // Add observer to handle removed accounts
    _removedAccountObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountManagerDidRemoveAccountNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        if ([MXKAccountManager sharedManager].accounts.count)
        {
            // Refresh table to remove this account
            [self refreshSettings];
        }
        
    }];
    
    // Add observer to handle accounts update
    _accountUserInfoObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountUserInfoDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        [self stopActivityIndicator];
        
        [self refreshSettings];
        
    }];
    
    // Add observer to push settings
    _pushInfoUpdateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountPushKitActivityDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        [self stopActivityIndicator];
        
        [self refreshSettings];
        
    }];
}

- (void)userInterfaceThemeDidChange
{
    [self updateWithStyle:self.currentStyle];
    
    if (self.tableView.dataSource)
    {
        [self refreshSettings];
    }
}

- (void)updateWithStyle:(id<Style>)style
{
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    
    if (navigationBar)
    {
        [style applyStyleOnNavigationBar:navigationBar];
    }
    
    // @TODO Design the activvity indicator for Tchap
    self.activityIndicator.backgroundColor = kRiotOverlayColor;
    
    // Check the table view style to select its bg color.
    self.tableView.backgroundColor = ((self.tableView.style == UITableViewStylePlain) ? style.backgroundColor : style.secondaryBackgroundColor);
    self.view.backgroundColor = self.tableView.backgroundColor;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.currentStyle.statusBarStyle;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    if (documentInteractionController)
    {
        [documentInteractionController dismissPreviewAnimated:NO];
        [documentInteractionController dismissMenuAnimated:NO];
        documentInteractionController = nil;
    }
    
    if (_riotDesignValuesDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_riotDesignValuesDidChangeThemeNotificationObserver];
    }
    
    if (_removedAccountObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_removedAccountObserver];
    }
    
    if (_accountUserInfoObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_accountUserInfoObserver];
    }
    
    if (_pushInfoUpdateObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_pushInfoUpdateObserver];
    }
    
    if (_appDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_appDelegateDidTapStatusBarNotificationObserver];
    }
    
    if (_sessionAccountDataDidChangeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_sessionAccountDataDidChangeNotificationObserver];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (deviceView)
    {
        [deviceView removeFromSuperview];
        deviceView = nil;
    }
}

- (void)onMatrixSessionStateDidChange:(NSNotification *)notif
{
    MXSession *mxSession = notif.object;
    
    // Check whether the concerned session is a new one which is not already associated with this view controller.
    if (mxSession.state == MXSessionStateInitialised && [self.mxSessions indexOfObject:mxSession] != NSNotFound)
    {
        // Store this new session
        [self addMatrixSession:mxSession];
    }
    else
    {
        [super onMatrixSessionStateDidChange:notif];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Screen tracking
    [[Analytics sharedInstance] trackScreen:@"Settings"];
    
    // Release the potential media picker
    [self dismissMediaPicker];
    
    // Refresh display
    [self refreshSettings];

    // Refresh linked emails and phone numbers in parallel
    [self loadAccount3PIDs];
    
    // Refresh the current device information in parallel
    [self loadCurrentDeviceInformation];
    
    // Refresh devices in parallel
    [self loadDevices];
    
    // Observe kAppDelegateDidTapStatusBarNotification.
    MXWeakify(self);
    _appDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        [self.tableView setContentOffset:CGPointMake(-self.tableView.mxk_adjustedContentInset.left, -self.tableView.mxk_adjustedContentInset.top) animated:YES];
        
    }];
    
    _sessionAccountDataDidChangeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionAccountDataDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

        MXStrongifyAndReturnIfNil(self);
        [self refreshSettings];

    }];
    
    // Apply the current theme
    [self userInterfaceThemeDidChange];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    if (resetPwdAlertController)
    {
        [resetPwdAlertController dismissViewControllerAnimated:NO completion:nil];
        resetPwdAlertController = nil;
    }
    
    if (_appDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_appDelegateDidTapStatusBarNotificationObserver];
    }
    
    if (_sessionAccountDataDidChangeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_sessionAccountDataDidChangeNotificationObserver];
    }
}

#pragma mark - Internal methods

- (void)pushViewController:(UIViewController*)viewController
{
    // Hide back button title
    self.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)dismissKeyboard
{
    [currentPasswordTextField resignFirstResponder];
    [newPasswordTextField1 resignFirstResponder];
    [newPasswordTextField2 resignFirstResponder];
}

- (void)loadAccount3PIDs
{
    // Refresh the account 3PIDs list
    MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    [account load3PIDs:^{

        // Refresh all the table (A slide down animation is observed when we limit the refresh to the concerned section).
        // Note: The use of 'reloadData' handles the case where the account has been logged out.
        [self refreshSettings];

    } failure:^(NSError *error) {
        
        // Display the data that has been loaded last time
        // Note: The use of 'reloadData' handles the case where the account has been logged out.
        [self refreshSettings];
        
    }];
}

- (void)loadCurrentDeviceInformation
{
    // Refresh the current device information
    MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    [account loadDeviceInformation:^{
        
        // Refresh all the table (A slide down animation is observed when we limit the refresh to the concerned section).
        // Note: The use of 'reloadData' handles the case where the account has been logged out.
        [self refreshSettings];
        
    } failure:nil];
}

- (NSAttributedString*)cryptographyInformation
{
    // TODO Handle multi accounts
    MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    
    // Crypto information
    NSMutableAttributedString *cryptoInformationString = [[NSMutableAttributedString alloc]
                                                          initWithString:NSLocalizedStringFromTable(@"settings_crypto_device_name", @"Vector", nil)
                                                          attributes:@{NSForegroundColorAttributeName : self.currentStyle.primaryTextColor,
                                                                       NSFontAttributeName: [UIFont systemFontOfSize:17]}];
    [cryptoInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                     initWithString:account.device.displayName ? account.device.displayName : @""
                                                     attributes:@{NSForegroundColorAttributeName : self.currentStyle.primaryTextColor,
                                                                  NSFontAttributeName: [UIFont systemFontOfSize:17]}]];
    
    [cryptoInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                     initWithString:NSLocalizedStringFromTable(@"settings_crypto_device_id", @"Vector", nil)
                                                     attributes:@{NSForegroundColorAttributeName : self.currentStyle.primaryTextColor,
                                                                  NSFontAttributeName: [UIFont systemFontOfSize:17]}]];
    [cryptoInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                     initWithString:account.device.deviceId ? account.device.deviceId : @""
                                                     attributes:@{NSForegroundColorAttributeName : self.currentStyle.primaryTextColor,
                                                                  NSFontAttributeName: [UIFont systemFontOfSize:17]}]];
    
    [cryptoInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                     initWithString:NSLocalizedStringFromTable(@"settings_crypto_device_key", @"Vector", nil)
                                                     attributes:@{NSForegroundColorAttributeName : self.currentStyle.primaryTextColor,
                                                                  NSFontAttributeName: [UIFont systemFontOfSize:17]}]];
    NSString *fingerprint = account.mxSession.crypto.deviceEd25519Key;
    [cryptoInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                     initWithString:fingerprint ? fingerprint : @""
                                                     attributes:@{NSForegroundColorAttributeName : self.currentStyle.primaryTextColor,
                                                                  NSFontAttributeName: [UIFont boldSystemFontOfSize:17]}]];
    
    return cryptoInformationString;
}

- (void)loadDevices
{
    // Refresh the account devices list
    MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    [account.mxRestClient devices:^(NSArray<MXDevice *> *devices) {
        
        if (devices)
        {
            devicesArray = [NSMutableArray arrayWithArray:devices];
            
            // Sort devices according to the last seen date.
            NSComparator comparator = ^NSComparisonResult(MXDevice *deviceA, MXDevice *deviceB) {
                
                if (deviceA.lastSeenTs > deviceB.lastSeenTs)
                {
                    return NSOrderedAscending;
                }
                if (deviceA.lastSeenTs < deviceB.lastSeenTs)
                {
                    return NSOrderedDescending;
                }
                
                return NSOrderedSame;
            };
            
            // Sort devices list
            [devicesArray sortUsingComparator:comparator];
        }
        else
        {
            devicesArray = nil;

        }
        
        // Refresh all the table (A slide down animation is observed when we limit the refresh to the concerned section).
        // Note: The use of 'reloadData' handles the case where the account has been logged out.
        [self refreshSettings];
        
    } failure:^(NSError *error) {
        
        // Display the data that has been loaded last time
        // Note: The use of 'reloadData' handles the case where the account has been logged out.
        [self refreshSettings];
        
    }];
}

- (void)showDeviceDetails:(MXDevice *)device
{
    [self dismissKeyboard];
    
    deviceView = [[DeviceView alloc] initWithDevice:device andMatrixSession:self.mainSession];
    deviceView.delegate = self;

    // Add the view and define edge constraints
    [self.tableView.superview addSubview:deviceView];
    [self.tableView.superview bringSubviewToFront:deviceView];
    
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:deviceView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.tableView
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0f
                                                                      constant:0.0f];
    
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:deviceView
                                                                      attribute:NSLayoutAttributeLeft
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.tableView
                                                                      attribute:NSLayoutAttributeLeft
                                                                     multiplier:1.0f
                                                                       constant:0.0f];
    
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:deviceView
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.tableView
                                                                       attribute:NSLayoutAttributeWidth
                                                                      multiplier:1.0f
                                                                        constant:0.0f];
    
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:deviceView
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.tableView
                                                                        attribute:NSLayoutAttributeHeight
                                                                       multiplier:1.0f
                                                                         constant:0.0f];
    
    [NSLayoutConstraint activateConstraints:@[topConstraint, leftConstraint, widthConstraint, heightConstraint]];
}

- (void)deviceView:(DeviceView*)theDeviceView presentAlertController:(UIAlertController *)alert
{
    [self dismissKeyboard];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)dismissDeviceView:(MXKDeviceView *)theDeviceView didUpdate:(BOOL)isUpdated
{
    [deviceView removeFromSuperview];
    deviceView = nil;
    
    if (isUpdated)
    {
        [self loadDevices];
    }
}

- (void)refreshSettings
{
    // Trigger a full table reloadData
    [self.tableView reloadData];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Keep ref on destinationViewController
    [super prepareForSegue:segue sender:sender];
    
    // FIXME add night mode
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // update the save button if there is an update
    [self updateSaveButtonStatus];
    
    return SETTINGS_SECTION_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    if (section == SETTINGS_SECTION_SIGN_OUT_INDEX)
    {
        count = 1;
    }
    else if (section == SETTINGS_SECTION_USER_SETTINGS_INDEX)
    {
        MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
        MXSession* session = [account mxSession];
        
        if (session)
        {
            userSettingsProfilePictureIndex = count++;
            userSettingsDisplayNameIndex = count++;
            userSettingsChangePasswordIndex = count++;
            
            
            // Presently all Tchap users are allowed to hide themselves from the users directory search
            userSettingsHideFromUsersDirIndex = count++;
            
            userSettingsEmailStartIndex = count;
            userSettingsPhoneStartIndex = userSettingsEmailStartIndex + account.linkedEmails.count;
            
            // Hide some unsupported account settings
            userSettingsFirstNameIndex = -1;
            userSettingsSurnameIndex = -1;
            userSettingsNightModeSepIndex = -1;
            userSettingsNightModeIndex = -1;
            
            count = userSettingsPhoneStartIndex + account.linkedPhoneNumbers.count;
        }
    }
    else if (section == SETTINGS_SECTION_NOTIFICATIONS_SETTINGS_INDEX)
    {
        count = NOTIFICATION_SETTINGS_COUNT;
    }
//    else if (section == SETTINGS_SECTION_CALLS_INDEX)
//    {
//        if ([MXCallKitAdapter callKitAvailable])
//        {
//            count = CALLS_COUNT;
//        }
//    }
    else if (section == SETTINGS_SECTION_IGNORED_USERS_INDEX)
    {
        MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
        MXSession* session = [account mxSession];
        
        if (session)
        {
            count = session.ignoredUsers.count;
        }
        else
        {
            count = 0;
        }
    }
    else if (section == SETTINGS_SECTION_CONTACTS_INDEX)
    {
        localContactsSyncIndex = count++;
        
        if ([MXKAppSettings standardAppSettings].syncLocalContacts)
        {
            localContactsPhoneBookCountryIndex = count++;
        }
        else
        {
            localContactsPhoneBookCountryIndex = -1;
        }
    }
    else if (section == SETTINGS_SECTION_OTHER_INDEX)
    {
        count = OTHER_COUNT;
    }
    else if (section == SETTINGS_SECTION_DEVICES_INDEX)
    {
        count = devicesArray.count;
    }
    else if (section == SETTINGS_SECTION_CRYPTOGRAPHY_INDEX)
    {
        // Check whether this section is visible.
        if (self.mainSession.crypto)
        {
            count = CRYPTOGRAPHY_COUNT;
        }
    }
    else if (section == SETTINGS_SECTION_DEACTIVATE_ACCOUNT_INDEX)
    {
        count = 1;
    }
    return count;
}

- (MXKTableViewCellWithLabelAndTextField*)getLabelAndTextFieldCell:(UITableView*)tableview forIndexPath:(NSIndexPath *)indexPath
{
    MXKTableViewCellWithLabelAndTextField *cell = [tableview dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndTextField defaultReuseIdentifier] forIndexPath:indexPath];
    
    cell.mxkLabelLeadingConstraint.constant = cell.separatorInset.left;
    cell.mxkTextFieldLeadingConstraint.constant = 16;
    cell.mxkTextFieldTrailingConstraint.constant = 15;
    
    cell.mxkLabel.textColor = self.currentStyle.primaryTextColor;
    
    cell.mxkTextField.userInteractionEnabled = YES;
    cell.mxkTextField.borderStyle = UITextBorderStyleNone;
    cell.mxkTextField.textAlignment = NSTextAlignmentRight;
    cell.mxkTextField.textColor = self.currentStyle.secondaryTextColor;
    cell.mxkTextField.font = [UIFont systemFontOfSize:16];
    cell.mxkTextField.placeholder = nil;
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    
    cell.alpha = 1.0f;
    cell.userInteractionEnabled = YES;
    
    [cell layoutIfNeeded];
    
    return cell;
}

- (MXKTableViewCellWithLabelAndSwitch*)getLabelAndSwitchCell:(UITableView*)tableview forIndexPath:(NSIndexPath *)indexPath
{
    MXKTableViewCellWithLabelAndSwitch *cell = [tableview dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier] forIndexPath:indexPath];
    
    cell.mxkLabelLeadingConstraint.constant = cell.separatorInset.left;
    cell.mxkSwitchTrailingConstraint.constant = 15;
    
    cell.mxkLabel.textColor = self.currentStyle.primaryTextColor;
    
    cell.mxkSwitch.onTintColor = self.currentStyle.buttonBorderedBackgroundColor;
    [cell.mxkSwitch removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
    
    // Force layout before reusing a cell (fix switch displayed outside the screen)
    [cell layoutIfNeeded];
    
    return cell;
}

- (MXKTableViewCell*)getDefaultTableViewCell:(UITableView*)tableView
{
    MXKTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCell defaultReuseIdentifier]];
    if (!cell)
    {
        cell = [[MXKTableViewCell alloc] init];
    }
    else
    {
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = nil;
    }
    cell.textLabel.accessibilityIdentifier = nil;
    cell.textLabel.font = [UIFont systemFontOfSize:17];
    cell.textLabel.textColor = self.currentStyle.primaryTextColor;
    
    return cell;
}

- (MXKTableViewCellWithTextView*)textViewCellForTableView:(UITableView*)tableView atIndexPath:(NSIndexPath *)indexPath
{
    MXKTableViewCellWithTextView *textViewCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithTextView defaultReuseIdentifier] forIndexPath:indexPath];
    
    textViewCell.mxkTextView.textColor = self.currentStyle.primaryTextColor;
    textViewCell.mxkTextView.font = [UIFont systemFontOfSize:17];
    textViewCell.mxkTextView.backgroundColor = [UIColor clearColor];
    textViewCell.mxkTextViewLeadingConstraint.constant = tableView.separatorInset.left;
    textViewCell.mxkTextViewTrailingConstraint.constant = tableView.separatorInset.right;
    textViewCell.mxkTextView.accessibilityIdentifier = nil;
    
    return textViewCell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;

    // set the cell to a default value to avoid application crashes
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.backgroundColor = self.currentStyle.warnTextColor;
    
    // check if there is a valid session
    MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    MXSession* session = [account mxSession];
    if (!session)
    {
        return cell;
    }

    if (section == SETTINGS_SECTION_SIGN_OUT_INDEX)
    {
        MXKTableViewCellWithButton *signOutCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
        if (!signOutCell)
        {
            signOutCell = [[MXKTableViewCellWithButton alloc] init];
        }
        else
        {
            // Fix https://github.com/vector-im/riot-ios/issues/1354
            // Do not move this line in prepareForReuse because of https://github.com/vector-im/riot-ios/issues/1323
            signOutCell.mxkButton.titleLabel.text = nil;
        }
        
        NSString* title = NSLocalizedStringFromTable(@"settings_sign_out", @"Vector", nil);
        
        [signOutCell.mxkButton setTitle:title forState:UIControlStateNormal];
        [signOutCell.mxkButton setTitle:title forState:UIControlStateHighlighted];
        [signOutCell.mxkButton setTintColor:self.currentStyle.buttonPlainTitleColor];
        signOutCell.mxkButton.titleLabel.font = [UIFont systemFontOfSize:17];
        
        [signOutCell.mxkButton  removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
        [signOutCell.mxkButton addTarget:self action:@selector(onSignout:) forControlEvents:UIControlEventTouchUpInside];
        signOutCell.mxkButton.accessibilityIdentifier=@"SettingsVCSignOutButton";
        
        cell = signOutCell;
    }
    else if (section == SETTINGS_SECTION_USER_SETTINGS_INDEX)
    {
        MXMyUser* myUser = session.myUser;
        
        if (row == userSettingsProfilePictureIndex)
        {
            MXKTableViewCellWithLabelAndMXKImageView *profileCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndMXKImageView defaultReuseIdentifier] forIndexPath:indexPath];
            
            profileCell.mxkLabelLeadingConstraint.constant = profileCell.separatorInset.left;
            profileCell.mxkImageViewTrailingConstraint.constant = 10;
            
            profileCell.mxkImageViewWidthConstraint.constant = profileCell.mxkImageViewHeightConstraint.constant = 30;
            profileCell.mxkImageViewDisplayBoxType = MXKTableViewCellDisplayBoxTypeCircle;
            
            if (!profileCell.mxkImageView.gestureRecognizers.count)
            {
                // tap on avatar to update it
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onProfileAvatarTap:)];
                [profileCell.mxkImageView addGestureRecognizer:tap];
            }
            
            profileCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_profile_picture", @"Vector", nil);
            profileCell.accessibilityIdentifier=@"SettingsVCProfilPictureStaticText";
            profileCell.mxkLabel.textColor = self.currentStyle.primaryTextColor;
            
            // if the user defines a new avatar
            if (newAvatarImage)
            {
                profileCell.mxkImageView.image = newAvatarImage;
            }
            else
            {
                UIImage* avatarImage = [AvatarGenerator generateAvatarForMatrixItem:myUser.userId withDisplayName:myUser.displayname];
                
                if (myUser.avatarUrl)
                {
                    profileCell.mxkImageView.enableInMemoryCache = YES;
                    
                    [profileCell.mxkImageView setImageURI:myUser.avatarUrl
                                                 withType:nil
                                      andImageOrientation:UIImageOrientationUp
                                            toFitViewSize:profileCell.mxkImageView.frame.size
                                               withMethod:MXThumbnailingMethodCrop
                                             previewImage:avatarImage
                                             mediaManager:session.mediaManager];
                }
                else
                {
                    profileCell.mxkImageView.image = avatarImage;
                }
            }
            
            cell = profileCell;
        }
        else if (row == userSettingsDisplayNameIndex)
        {
            MXKTableViewCellWithLabelAndTextField *displaynameCell = [self getLabelAndTextFieldCell:tableView forIndexPath:indexPath];
            
            displaynameCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_display_name", @"Vector", nil);
            displaynameCell.mxkTextField.text = myUser.displayname;
            
            displaynameCell.mxkTextField.tag = row;
            displaynameCell.mxkTextField.delegate = self;
            displaynameCell.mxkTextField.accessibilityIdentifier=@"SettingsVCDisplayNameTextField";
            displaynameCell.mxkTextField.userInteractionEnabled = NO;
            
            cell = displaynameCell;
        }
        else if (row == userSettingsFirstNameIndex)
        {
            MXKTableViewCellWithLabelAndTextField *firstCell = [self getLabelAndTextFieldCell:tableView forIndexPath:indexPath];
        
            firstCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_first_name", @"Vector", nil);
            firstCell.mxkTextField.userInteractionEnabled = NO;
            
            cell = firstCell;
        }
        else if (row == userSettingsSurnameIndex)
        {
            MXKTableViewCellWithLabelAndTextField *surnameCell = [self getLabelAndTextFieldCell:tableView forIndexPath:indexPath];
            
            surnameCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_surname", @"Vector", nil);
            surnameCell.mxkTextField.userInteractionEnabled = NO;
            
            cell = surnameCell;
        }
        else if (userSettingsEmailStartIndex <= row &&  row < userSettingsPhoneStartIndex)
        {
            MXKTableViewCellWithLabelAndTextField *emailCell = [self getLabelAndTextFieldCell:tableView forIndexPath:indexPath];
            
            emailCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_email_address", @"Vector", nil);
            emailCell.mxkTextField.text = account.linkedEmails[row - userSettingsEmailStartIndex];
            emailCell.mxkTextField.userInteractionEnabled = NO;
            
            cell = emailCell;
        }
        else if (userSettingsPhoneStartIndex <= row)
        {
            MXKTableViewCellWithLabelAndTextField *phoneCell = [self getLabelAndTextFieldCell:tableView forIndexPath:indexPath];
            
            phoneCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_phone_number", @"Vector", nil);
            
            NSString *e164 = [NSString stringWithFormat:@"+%@", account.linkedPhoneNumbers[row - userSettingsPhoneStartIndex]];
            NBPhoneNumber *phoneNb = [[NBPhoneNumberUtil sharedInstance] parse:e164 defaultRegion:nil error:nil];
            phoneCell.mxkTextField.text = [[NBPhoneNumberUtil sharedInstance] format:phoneNb numberFormat:NBEPhoneNumberFormatINTERNATIONAL error:nil];
            phoneCell.mxkTextField.userInteractionEnabled = NO;
            
            cell = phoneCell;
        }
        else if (row == userSettingsChangePasswordIndex)
        {
            MXKTableViewCellWithLabelAndTextField *passwordCell = [self getLabelAndTextFieldCell:tableView forIndexPath:indexPath];
            
            passwordCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_change_password", @"Vector", nil);
            passwordCell.mxkTextField.text = @"*********";
            passwordCell.mxkTextField.userInteractionEnabled = NO;
            passwordCell.mxkLabel.accessibilityIdentifier=@"SettingsVCChangePwdStaticText";
            
            cell = passwordCell;
        }
        else if (row == userSettingsNightModeSepIndex)
        {
            UITableViewCell *sepCell = [[UITableViewCell alloc] init];
            sepCell.backgroundColor = self.currentStyle.secondaryBackgroundColor;
            
            cell = sepCell;
        }
        else if (row == userSettingsNightModeIndex)
        {
            MXKTableViewCellWithLabelAndTextField *nightModeCell = [self getLabelAndTextFieldCell:tableView forIndexPath:indexPath];
                                                                    
            nightModeCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_night_mode", @"Vector", nil);
            nightModeCell.mxkTextField.userInteractionEnabled = NO;
            nightModeCell.mxkTextField.text = NSLocalizedStringFromTable(@"off", @"Vector", nil);
            nightModeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell = nightModeCell;
        }
        else if (row == userSettingsHideFromUsersDirIndex)
        {
            MXKTableViewCellWithLabelAndSwitch* labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
            
            NSString *title = NSLocalizedStringFromTable(@"settings_hide_from_users_directory_title", @"Tchap", nil);
            NSString *summary = NSLocalizedStringFromTable(@"settings_hide_from_users_directory_summary", @"Tchap", nil);
            NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString: title
                                                                                               attributes:@{NSForegroundColorAttributeName : self.currentStyle.primaryTextColor,
                                                                                                            NSFontAttributeName: [UIFont systemFontOfSize:17.0]}];
            [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:4]}]];
            [attributedText appendAttributedString:[[NSMutableAttributedString alloc] initWithString: summary
                                                                                          attributes:@{NSForegroundColorAttributeName : self.currentStyle.secondaryTextColor,
                                                                                                       NSFontAttributeName: [UIFont systemFontOfSize:14.0]}]];
            
            labelAndSwitchCell.mxkLabel.attributedText = attributedText;
            labelAndSwitchCell.mxkSwitch.on = [self isHiddenFromUsersDirectory:session];
            labelAndSwitchCell.mxkSwitch.enabled = YES;
            [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleHideFromUsersDirectory:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = labelAndSwitchCell;
        }
    }
    else if (section == SETTINGS_SECTION_NOTIFICATIONS_SETTINGS_INDEX)
    {
        if (row == NOTIFICATION_SETTINGS_ENABLE_PUSH_INDEX)
        {
            MXKTableViewCellWithLabelAndSwitch* labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
    
            labelAndSwitchCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_enable_push_notif", @"Vector", nil);
            labelAndSwitchCell.mxkSwitch.on = account.isPushKitNotificationActive;
            labelAndSwitchCell.mxkSwitch.enabled = YES;
            [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(togglePushNotifications:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = labelAndSwitchCell;
        }
        else if (row == NOTIFICATION_SETTINGS_SHOW_DECODED_CONTENT)
        {
            MXKTableViewCellWithLabelAndSwitch* labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
            
            labelAndSwitchCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_show_decrypted_content", @"Vector", nil);
            labelAndSwitchCell.mxkSwitch.on = RiotSettings.shared.showDecryptedContentInNotifications;
            labelAndSwitchCell.mxkSwitch.enabled = account.isPushKitNotificationActive;
            [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleShowDecodedContent:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = labelAndSwitchCell;
        }
        else if (row == NOTIFICATION_SETTINGS_GLOBAL_SETTINGS_INDEX)
        {
            MXKTableViewCell *globalInfoCell = [self getDefaultTableViewCell:tableView];

            NSString *appDisplayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];

            globalInfoCell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"settings_global_settings_info", @"Vector", nil), appDisplayName];
            globalInfoCell.textLabel.numberOfLines = 0;
            
            globalInfoCell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            cell = globalInfoCell;
        }
    }
//    else if (section == SETTINGS_SECTION_CALLS_INDEX)
//    {
//        if (row == CALLS_ENABLE_CALLKIT_INDEX)
//        {
//            MXKTableViewCellWithLabelAndSwitch* labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
//            labelAndSwitchCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_enable_callkit", @"Vector", nil);
//            labelAndSwitchCell.mxkSwitch.on = [MXKAppSettings standardAppSettings].isCallKitEnabled;
//            labelAndSwitchCell.mxkSwitch.enabled = YES;
//            [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleCallKit:) forControlEvents:UIControlEventTouchUpInside];
//
//            cell = labelAndSwitchCell;
//        }
//        else if (row == CALLS_DESCRIPTION_INDEX)
//        {
//            MXKTableViewCell *globalInfoCell = [self getDefaultTableViewCell:tableView];
//            globalInfoCell.textLabel.text = NSLocalizedStringFromTable(@"settings_callkit_info", @"Vector", nil);
//            globalInfoCell.textLabel.numberOfLines = 0;
//            globalInfoCell.selectionStyle = UITableViewCellSelectionStyleNone;
//
//            cell = globalInfoCell;
//        }
//    }
    else if (section == SETTINGS_SECTION_IGNORED_USERS_INDEX)
    {
        MXKTableViewCell *ignoredUserCell = [self getDefaultTableViewCell:tableView];

        NSString *ignoredUserId;
        if (indexPath.row < session.ignoredUsers.count)
        {
            ignoredUserId = session.ignoredUsers[indexPath.row];
        }
        ignoredUserCell.textLabel.text = ignoredUserId; // FIXME replace this id with a display name

        cell = ignoredUserCell;
    }
    else if (section == SETTINGS_SECTION_CONTACTS_INDEX)
    {
        if (row == localContactsSyncIndex)
        {
            MXKTableViewCellWithLabelAndSwitch* labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];

            labelAndSwitchCell.mxkLabel.numberOfLines = 0;
            labelAndSwitchCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_contacts_discover_matrix_users", @"Tchap", nil);
            labelAndSwitchCell.mxkSwitch.on = [MXKAppSettings standardAppSettings].syncLocalContacts;
            labelAndSwitchCell.mxkSwitch.enabled = YES;
            [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleLocalContactsSync:) forControlEvents:UIControlEventTouchUpInside];

            cell = labelAndSwitchCell;
        }
        else if (row == localContactsPhoneBookCountryIndex)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kSettingsViewControllerPhoneBookCountryCellId];
            if (!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kSettingsViewControllerPhoneBookCountryCellId];
            }
            
            NSString* countryCode = [[MXKAppSettings standardAppSettings] phonebookCountryCode];
            NSLocale *local = [[NSLocale alloc] initWithLocaleIdentifier:[[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0]];
            NSString *countryName = [local displayNameForKey:NSLocaleCountryCode value:countryCode];
            
            cell.textLabel.textColor = self.currentStyle.primaryTextColor;
            
            cell.textLabel.text = NSLocalizedStringFromTable(@"settings_contacts_phonebook_country", @"Vector", nil);
            cell.detailTextLabel.text = countryName;
            
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
    }
    else if (section == SETTINGS_SECTION_OTHER_INDEX)
    {
        if (row == OTHER_VERSION_INDEX)
        {
            MXKTableViewCell *versionCell = [self getDefaultTableViewCell:tableView];
            
            NSString* appVersion = [AppDelegate theDelegate].appVersion;
            NSString* build = [AppDelegate theDelegate].build;
            
            versionCell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"settings_version", @"Vector", nil), [NSString stringWithFormat:@"%@ %@", appVersion, build]];
            
            versionCell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            cell = versionCell;
        }
        else if (row == OTHER_TERM_CONDITIONS_INDEX)
        {
            MXKTableViewCell *termAndConditionCell = [self getDefaultTableViewCell:tableView];

            termAndConditionCell.textLabel.text = NSLocalizedStringFromTable(@"settings_term_conditions", @"Vector", nil);
            
            termAndConditionCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            cell = termAndConditionCell;
        }
        else if (row == OTHER_THIRD_PARTY_INDEX)
        {
            MXKTableViewCell *thirdPartyCell = [self getDefaultTableViewCell:tableView];
            
            thirdPartyCell.textLabel.text = NSLocalizedStringFromTable(@"settings_third_party_notices", @"Vector", nil);
            
            thirdPartyCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            cell = thirdPartyCell;
        }
//        else if (row == OTHER_CRASH_REPORT_INDEX)
//        {
//            MXKTableViewCellWithLabelAndSwitch* sendCrashReportCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
//
//            sendCrashReportCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_send_crash_report", @"Vector", nil);
//            sendCrashReportCell.mxkSwitch.on = RiotSettings.shared.enableCrashReport;
//            sendCrashReportCell.mxkSwitch.enabled = YES;
//            [sendCrashReportCell.mxkSwitch addTarget:self action:@selector(toggleSendCrashReport:) forControlEvents:UIControlEventTouchUpInside];
//
//            cell = sendCrashReportCell;
//        }
//        else if (row == OTHER_ENABLE_RAGESHAKE_INDEX)
//        {
//            MXKTableViewCellWithLabelAndSwitch* enableRageShakeCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
//
//            enableRageShakeCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_enable_rageshake", @"Vector", nil);
//            enableRageShakeCell.mxkSwitch.on = RiotSettings.shared.enableRageShake;
//            enableRageShakeCell.mxkSwitch.enabled = YES;
//            [enableRageShakeCell.mxkSwitch addTarget:self action:@selector(toggleEnableRageShake:) forControlEvents:UIControlEventTouchUpInside];
//
//            cell = enableRageShakeCell;
//        }
        else if (row == OTHER_MARK_ALL_AS_READ_INDEX)
        {
            MXKTableViewCellWithButton *markAllBtnCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
            if (!markAllBtnCell)
            {
                markAllBtnCell = [[MXKTableViewCellWithButton alloc] init];
            }
            else
            {
                // Fix https://github.com/vector-im/riot-ios/issues/1354
                markAllBtnCell.mxkButton.titleLabel.text = nil;
            }
            
            NSString *btnTitle = NSLocalizedStringFromTable(@"settings_mark_all_as_read", @"Vector", nil);
            [markAllBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateNormal];
            [markAllBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateHighlighted];
            [markAllBtnCell.mxkButton setTintColor:self.currentStyle.buttonPlainTitleColor];
            markAllBtnCell.mxkButton.titleLabel.font = [UIFont systemFontOfSize:17];
            
            [markAllBtnCell.mxkButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [markAllBtnCell.mxkButton addTarget:self action:@selector(markAllAsRead:) forControlEvents:UIControlEventTouchUpInside];
            markAllBtnCell.mxkButton.accessibilityIdentifier = nil;
            
            cell = markAllBtnCell;
        }
        else if (row == OTHER_CLEAR_CACHE_INDEX)
        {
            MXKTableViewCellWithButton *clearCacheBtnCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
            if (!clearCacheBtnCell)
            {
                clearCacheBtnCell = [[MXKTableViewCellWithButton alloc] init];
            }
            else
            {
                // Fix https://github.com/vector-im/riot-ios/issues/1354
                clearCacheBtnCell.mxkButton.titleLabel.text = nil;
            }
            
            NSString *btnTitle = NSLocalizedStringFromTable(@"settings_clear_cache", @"Vector", nil);
            [clearCacheBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateNormal];
            [clearCacheBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateHighlighted];
            [clearCacheBtnCell.mxkButton setTintColor:self.currentStyle.buttonPlainTitleColor];
            clearCacheBtnCell.mxkButton.titleLabel.font = [UIFont systemFontOfSize:17];
            
            [clearCacheBtnCell.mxkButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [clearCacheBtnCell.mxkButton addTarget:self action:@selector(clearCache:) forControlEvents:UIControlEventTouchUpInside];
            clearCacheBtnCell.mxkButton.accessibilityIdentifier = nil;
            
            cell = clearCacheBtnCell;
        }
        else if (row == OTHER_REPORT_BUG_INDEX)
        {
            MXKTableViewCellWithButton *reportBugBtnCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
            if (!reportBugBtnCell)
            {
                reportBugBtnCell = [[MXKTableViewCellWithButton alloc] init];
            }
            else
            {
                // Fix https://github.com/vector-im/riot-ios/issues/1354
                reportBugBtnCell.mxkButton.titleLabel.text = nil;
            }

            NSString *btnTitle = NSLocalizedStringFromTable(@"settings_report_bug", @"Vector", nil);
            [reportBugBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateNormal];
            [reportBugBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateHighlighted];
            [reportBugBtnCell.mxkButton setTintColor:self.currentStyle.buttonPlainTitleColor];
            reportBugBtnCell.mxkButton.titleLabel.font = [UIFont systemFontOfSize:17];

            [reportBugBtnCell.mxkButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [reportBugBtnCell.mxkButton addTarget:self action:@selector(reportBug:) forControlEvents:UIControlEventTouchUpInside];
            reportBugBtnCell.mxkButton.accessibilityIdentifier = nil;

            cell = reportBugBtnCell;
        }
    }
    else if (section == SETTINGS_SECTION_DEVICES_INDEX)
    {
        MXKTableViewCell *deviceCell = [self getDefaultTableViewCell:tableView];
        
        if (row < devicesArray.count)
        {
            NSString *name = devicesArray[row].displayName;
            NSString *deviceId = devicesArray[row].deviceId;
            deviceCell.textLabel.text = (name.length ? [NSString stringWithFormat:@"%@ (%@)", name, deviceId] : [NSString stringWithFormat:@"(%@)", deviceId]);
            deviceCell.textLabel.numberOfLines = 0;
            
            if ([deviceId isEqualToString:self.mainSession.matrixRestClient.credentials.deviceId])
            {
                deviceCell.textLabel.font = [UIFont boldSystemFontOfSize:17];
            }
        }
        
        cell = deviceCell;
    }
    else if (section == SETTINGS_SECTION_CRYPTOGRAPHY_INDEX)
    {
        if (row == CRYPTOGRAPHY_INFO_INDEX)
        {
            MXKTableViewCellWithTextView *cryptoCell = [self textViewCellForTableView:tableView atIndexPath:indexPath];
            
            cryptoCell.mxkTextView.attributedText = [self cryptographyInformation];

            cell = cryptoCell;
        }
        else if (row == CRYPTOGRAPHY_EXPORT_INDEX)
        {
            MXKTableViewCellWithButton *exportKeysBtnCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
            if (!exportKeysBtnCell)
            {
                exportKeysBtnCell = [[MXKTableViewCellWithButton alloc] init];
            }
            else
            {
                // Fix https://github.com/vector-im/riot-ios/issues/1354
                exportKeysBtnCell.mxkButton.titleLabel.text = nil;
            }

            NSString *btnTitle = NSLocalizedStringFromTable(@"settings_crypto_export", @"Vector", nil);
            [exportKeysBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateNormal];
            [exportKeysBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateHighlighted];
            [exportKeysBtnCell.mxkButton setTintColor:self.currentStyle.buttonPlainTitleColor];
            exportKeysBtnCell.mxkButton.titleLabel.font = [UIFont systemFontOfSize:17];

            [exportKeysBtnCell.mxkButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [exportKeysBtnCell.mxkButton addTarget:self action:@selector(exportEncryptionKeys:) forControlEvents:UIControlEventTouchUpInside];
            exportKeysBtnCell.mxkButton.accessibilityIdentifier = nil;

            cell = exportKeysBtnCell;
        }
    }
    else if (section == SETTINGS_SECTION_DEACTIVATE_ACCOUNT_INDEX)
    {
        MXKTableViewCellWithButton *deactivateAccountBtnCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
        
        if (!deactivateAccountBtnCell)
        {
            deactivateAccountBtnCell = [[MXKTableViewCellWithButton alloc] init];
        }
        else
        {
            // Fix https://github.com/vector-im/riot-ios/issues/1354
            deactivateAccountBtnCell.mxkButton.titleLabel.text = nil;
        }
        
        NSString *btnTitle = NSLocalizedStringFromTable(@"settings_deactivate_my_account", @"Vector", nil);
        [deactivateAccountBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateNormal];
        [deactivateAccountBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateHighlighted];
        [deactivateAccountBtnCell.mxkButton setTintColor:self.currentStyle.warnTextColor];
        deactivateAccountBtnCell.mxkButton.titleLabel.font = [UIFont systemFontOfSize:17];
        
        [deactivateAccountBtnCell.mxkButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
        [deactivateAccountBtnCell.mxkButton addTarget:self action:@selector(deactivateAccountAction) forControlEvents:UIControlEventTouchUpInside];
        deactivateAccountBtnCell.mxkButton.accessibilityIdentifier = nil;
        
        cell = deactivateAccountBtnCell;
    }

    return cell;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == SETTINGS_SECTION_USER_SETTINGS_INDEX)
    {
        return NSLocalizedStringFromTable(@"settings_user_settings", @"Vector", nil);
    }
    else if (section == SETTINGS_SECTION_NOTIFICATIONS_SETTINGS_INDEX)
    {
        return NSLocalizedStringFromTable(@"settings_notifications_settings", @"Vector", nil);
    }
//    else if (section == SETTINGS_SECTION_CALLS_INDEX)
//    {
//        if ([MXCallKitAdapter callKitAvailable])
//        {
//            return NSLocalizedStringFromTable(@"settings_calls_settings", @"Vector", nil);
//        }
//    }
    else if (section == SETTINGS_SECTION_IGNORED_USERS_INDEX)
    {
        // Check whether this section is visible
        MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
        MXSession* session = [account mxSession];
        if (session && session.ignoredUsers.count)
        {
            return NSLocalizedStringFromTable(@"settings_ignored_users", @"Vector", nil);
        }
    }
    else if (section == SETTINGS_SECTION_CONTACTS_INDEX)
    {
        return NSLocalizedStringFromTable(@"settings_contacts", @"Vector", nil);
    }
    else if (section == SETTINGS_SECTION_OTHER_INDEX)
    {
        return NSLocalizedStringFromTable(@"settings_other", @"Vector", nil);
    }
    else if (section == SETTINGS_SECTION_DEVICES_INDEX)
    {
        // Check whether this section is visible
        if (devicesArray.count > 0)
        {
            return NSLocalizedStringFromTable(@"settings_devices", @"Vector", nil);
        }
    }
    else if (section == SETTINGS_SECTION_CRYPTOGRAPHY_INDEX)
    {
        // Check whether this section is visible
        if (self.mainSession.crypto)
        {
            return NSLocalizedStringFromTable(@"settings_cryptography", @"Vector", nil);
        }
    }
    else if (section == SETTINGS_SECTION_DEACTIVATE_ACCOUNT_INDEX)
    {
        return NSLocalizedStringFromTable(@"settings_deactivate_my_account", @"Vector", nil);
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if ([view isKindOfClass:UITableViewHeaderFooterView.class])
    {
        // Customize label style
        UITableViewHeaderFooterView *tableViewHeaderFooterView = (UITableViewHeaderFooterView*)view;
        tableViewHeaderFooterView.textLabel.textColor = self.currentStyle.primaryTextColor;
        tableViewHeaderFooterView.textLabel.font = [UIFont systemFontOfSize:15];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    // iOS8 requires this method to enable editing (see editActionsForRowAtIndexPath).
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    cell.backgroundColor = self.currentStyle.backgroundColor;
    
    if (cell.selectionStyle != UITableViewCellSelectionStyleNone)
    {        
        // Update the selected background view
        if (self.currentStyle.secondaryBackgroundColor)
        {
            cell.selectedBackgroundView = [[UIView alloc] init];
            cell.selectedBackgroundView.backgroundColor = self.currentStyle.secondaryBackgroundColor;
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
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == SETTINGS_SECTION_IGNORED_USERS_INDEX)
    {
        MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
        MXSession* session = [account mxSession];
        if (session && session.ignoredUsers.count == 0)
        {
            // Hide this section
            return SECTION_TITLE_PADDING_WHEN_HIDDEN;
        }
    }
//    else if (section == SETTINGS_SECTION_CALLS_INDEX)
//    {
//        if (![MXCallKitAdapter callKitAvailable])
//        {
//            return SECTION_TITLE_PADDING_WHEN_HIDDEN;
//        }
//    }
    
    return 24;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == SETTINGS_SECTION_IGNORED_USERS_INDEX)
    {
        MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
        MXSession* session = [account mxSession];
        if (session && session.ignoredUsers.count == 0)
        {
            // Hide this section
            return SECTION_TITLE_PADDING_WHEN_HIDDEN;
        }
    }
//    else if (section == SETTINGS_SECTION_CALLS_INDEX)
//    {
//        if (![MXCallKitAdapter callKitAvailable])
//        {
//            return SECTION_TITLE_PADDING_WHEN_HIDDEN;
//        }
//    }

    return 24;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView == tableView)
    {
        NSInteger section = indexPath.section;
        NSInteger row = indexPath.row;
        
        if (section == SETTINGS_SECTION_IGNORED_USERS_INDEX)
        {
            MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
            MXSession* session = [account mxSession];

            NSString *ignoredUserId;
            if (indexPath.row < session.ignoredUsers.count)
            {
                ignoredUserId = session.ignoredUsers[indexPath.row];
            }

            if (ignoredUserId)
            {
                [currentAlert dismissViewControllerAnimated:NO completion:nil];

                __weak typeof(self) weakSelf = self;
                
                currentAlert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"settings_unignore_user", @"Vector", nil), ignoredUserId] message:nil preferredStyle:UIAlertControllerStyleAlert];

                [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"yes"]
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       self->currentAlert = nil;
                                                                       
                                                                       // Remove the member from the ignored user list
                                                                       [self startActivityIndicator];
                                                                       [session unIgnoreUsers:@[ignoredUserId] success:^{
                                                                           
                                                                           [self stopActivityIndicator];
                                                                           
                                                                       } failure:^(NSError *error) {
                                                                           
                                                                           [self stopActivityIndicator];
                                                                           
                                                                           NSLog(@"[SettingsViewController] Unignore %@ failed", ignoredUserId);
                                                                           
                                                                           NSString *myUserId = session.myUser.userId;
                                                                           [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                                                                           
                                                                       }];
                                                                   }
                                                                   
                                                               }]];
                
                [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"no"]
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       self->currentAlert = nil;
                                                                   }
                                                                   
                                                               }]];
                
                [currentAlert mxk_setAccessibilityIdentifier: @"SettingsVCUnignoreAlert"];
                [self presentViewController:currentAlert animated:YES completion:nil];
            }
        }
        else if (section == SETTINGS_SECTION_OTHER_INDEX)
        {
            if (row == OTHER_TERM_CONDITIONS_INDEX)
            {
                NSString *tac_url = [[MXKAppSettings standardAppSettings].sharedUserDefaults objectForKey:@"tacURL"];
                WebViewViewController *webViewViewController = [[WebViewViewController alloc] initWithURL:tac_url];
                
                webViewViewController.title = NSLocalizedStringFromTable(@"settings_term_conditions", @"Vector", nil);
                
                [self pushViewController:webViewViewController];
            }
            else if (row == OTHER_THIRD_PARTY_INDEX)
            {
                NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"third_party_licenses" ofType:@"html" inDirectory:nil];

                WebViewViewController *webViewViewController = [[WebViewViewController alloc] initWithLocalHTMLFile:htmlFile];
                
                webViewViewController.title = NSLocalizedStringFromTable(@"settings_third_party_notices", @"Vector", nil);
                
                [self pushViewController:webViewViewController];
            }
        }
        else if (section == SETTINGS_SECTION_USER_SETTINGS_INDEX)
        {
            if (row == userSettingsProfilePictureIndex)
            {
                [self onProfileAvatarTap:nil];
            }
            else if (row == userSettingsChangePasswordIndex)
            {
                [self promptUserBeforePasswordChange];
            }
        }
        else if (section == SETTINGS_SECTION_DEVICES_INDEX)
        {
            if (row < devicesArray.count)
            {
                [self showDeviceDetails:devicesArray[row]];
            }
        }
        else if (section == SETTINGS_SECTION_CONTACTS_INDEX)
        {
            if (row == localContactsPhoneBookCountryIndex)
            {
                CountryPickerViewController *countryPicker = [CountryPickerViewController countryPickerViewController];
                countryPicker.view.tag = SETTINGS_SECTION_CONTACTS_INDEX;
                countryPicker.delegate = self;
                countryPicker.showCountryCallingCode = YES;
                [self pushViewController:countryPicker];
            }
        }
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - actions


- (void)onSignout:(id)sender
{
    // Feedback: disable button and run activity indicator
    UIButton *button = (UIButton*)sender;
    button.enabled = NO;
    [self startActivityIndicator];
    
     __weak typeof(self) weakSelf = self;
    
    [[AppDelegate theDelegate] logoutWithConfirmation:YES completion:^(BOOL isLoggedOut) {
        
        if (!isLoggedOut && weakSelf)
        {
            typeof(self) self = weakSelf;
            
            // Enable the button and stop activity indicator
            button.enabled = YES;
            [self stopActivityIndicator];
        }
    }];
}

- (void)togglePushNotifications:(id)sender
{
    // Check first whether the user allow notification from device settings
    UIUserNotificationType currentUserNotificationTypes = UIApplication.sharedApplication.currentUserNotificationSettings.types;
    if (currentUserNotificationTypes == UIUserNotificationTypeNone)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        
        __weak typeof(self) weakSelf = self;

        NSString *appDisplayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
        
        currentAlert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"settings_on_denied_notification", @"Vector", nil), appDisplayName] message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               self->currentAlert = nil;
                                                           }
                                                           
                                                       }]];
        
        [currentAlert mxk_setAccessibilityIdentifier: @"SettingsVCPushNotificationsAlert"];
        [self presentViewController:currentAlert animated:YES completion:nil];
        
        // Keep off the switch
        ((UISwitch*)sender).on = NO;
    }
    else if ([MXKAccountManager sharedManager].activeAccounts.count)
    {
        [self startActivityIndicator];
        
        MXKAccountManager *accountManager = [MXKAccountManager sharedManager];
        MXKAccount* account = accountManager.activeAccounts.firstObject;
        
        if (accountManager.pushDeviceToken)
        {
            [account enablePushKitNotifications:!account.isPushKitNotificationActive success:^{
                [self stopActivityIndicator];
            } failure:^(NSError *error) {
                [self stopActivityIndicator];
            }];
        }
        else
        {
            // Obtain device token when user has just enabled access to notifications from system settings
            [[AppDelegate theDelegate] registerForRemoteNotificationsWithCompletion:^(NSError * error) {
                if (error)
                {
                    [(UISwitch *)sender setOn:NO animated:YES];
                    [self stopActivityIndicator];
                }
                else
                {
                    [account enablePushKitNotifications:YES success:^{
                        [self stopActivityIndicator];
                    } failure:^(NSError *error) {
                        [self stopActivityIndicator];
                    }];
                }
            }];
        }
    }
}

- (void)toggleCallKit:(id)sender
{
    UISwitch *switchButton = (UISwitch*)sender;
    [MXKAppSettings standardAppSettings].enableCallKit = switchButton.isOn;
}

- (void)toggleShowDecodedContent:(id)sender
{
    UISwitch *switchButton = (UISwitch*)sender;
    RiotSettings.shared.showDecryptedContentInNotifications = switchButton.isOn;
}

- (void)toggleLocalContactsSync:(id)sender
{
    UISwitch *switchButton = (UISwitch*)sender;

    if (switchButton.on)
    {
        [MXKContactManager requestUserConfirmationForLocalContactsSyncInViewController:self completionHandler:^(BOOL granted) {

            [MXKAppSettings standardAppSettings].syncLocalContacts = granted;
            
            [self.tableView reloadData];
        }];
    }
    else
    {
        [MXKAppSettings standardAppSettings].syncLocalContacts = NO;
        
        [self.tableView reloadData];
    }
}

//- (void)toggleSendCrashReport:(id)sender
//{
//    BOOL enable = RiotSettings.shared.enableCrashReport;
//    if (enable)
//    {
//        NSLog(@"[SettingsViewController] disable automatic crash report and analytics sending");
//
//        RiotSettings.shared.enableCrashReport = NO;
//
//        [[Analytics sharedInstance] stop];
//
//        // Remove potential crash file.
//        [MXLogger deleteCrashLog];
//    }
//    else
//    {
//        NSLog(@"[SettingsViewController] enable automatic crash report and analytics sending");
//
//        RiotSettings.shared.enableCrashReport = YES;
//
//        [[Analytics sharedInstance] start];
//    }
//}
//
//- (void)toggleEnableRageShake:(id)sender
//{
//    if (sender && [sender isKindOfClass:UISwitch.class])
//    {
//        UISwitch *switchButton = (UISwitch*)sender;
//
//        RiotSettings.shared.enableRageShake = switchButton.isOn;
//
//        [self.tableView reloadData];
//    }
//}

- (void)toggleBlacklistUnverifiedDevices:(id)sender
{
    UISwitch *switchButton = (UISwitch*)sender;

    MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    account.mxSession.crypto.globalBlacklistUnverifiedDevices = switchButton.on;

    [self.tableView reloadData];
}

- (void)markAllAsRead:(id)sender
{
    // Feedback: disable button and run activity indicator
    UIButton *button = (UIButton*)sender;
    button.enabled = NO;
    [self startActivityIndicator];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        [[AppDelegate theDelegate] markAllMessagesAsRead];
        
        [self stopActivityIndicator];
        button.enabled = YES;
        
    });
}

- (void)clearCache:(id)sender
{
    // Feedback: disable button and run activity indicator
    UIButton *button = (UIButton*)sender;
    button.enabled = NO;

    [self launchClearCache];
}

- (void)launchClearCache
{
    if (_delegate)
    {
        [self startActivityIndicator];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            
            [self.delegate settingsViewController:self reloadMatrixSessionsByClearingCache:YES];
            
        });
    }
}

- (void)reportBug:(id)sender
{
    BugReportViewController *bugReportViewController = [BugReportViewController bugReportViewController];
    [bugReportViewController showInViewController:self];
}

//- (void)onRuleUpdate:(id)sender
//{
//    MXPushRule* pushRule = nil;
//    MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
//    MXSession* session = [account mxSession];
//
//    NSInteger row = ((UIView*)sender).tag;
//    
//    if (row == NOTIFICATION_SETTINGS_CONTAINING_MY_DISPLAY_NAME_INDEX)
//    {
//        pushRule = [session.notificationCenter ruleById:kMXNotificationCenterContainDisplayNameRuleID];
//    }
//    else if (row == NOTIFICATION_SETTINGS_CONTAINING_MY_USER_NAME_INDEX)
//    {
//        pushRule = [session.notificationCenter ruleById:kMXNotificationCenterContainUserNameRuleID];
//    }
//    else if (row == NOTIFICATION_SETTINGS_SENT_TO_ME_INDEX)
//    {
//        pushRule = [session.notificationCenter ruleById:kMXNotificationCenterOneToOneRoomRuleID];
//    }
//    else if (row == NOTIFICATION_SETTINGS_INVITED_TO_ROOM_INDEX)
//    {
//        pushRule = [session.notificationCenter ruleById:kMXNotificationCenterInviteMeRuleID];
//    }
//    else if (row == NOTIFICATION_SETTINGS_PEOPLE_LEAVE_JOIN_INDEX)
//    {
//        pushRule = [session.notificationCenter ruleById:kMXNotificationCenterMemberEventRuleID];
//    }
//    else if (row == NOTIFICATION_SETTINGS_CALL_INVITATION_INDEX)
//    {
//        pushRule = [session.notificationCenter ruleById:kMXNotificationCenterCallRuleID];
//    }
//    
//    if (pushRule)
//    {
//        // toggle the rule
//        [session.notificationCenter enableRule:pushRule isEnabled:!pushRule.enabled];
//    }
//}


- (void)onSave:(id)sender
{
    // sanity check
    if ([MXKAccountManager sharedManager].activeAccounts.count == 0)
    {
        return;
    }
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self startActivityIndicator];
    
    MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    
    if (newAvatarImage)
    {
        // Retrieve the current picture and make sure its orientation is up
        UIImage *updatedPicture = [MXKTools forceImageOrientationUp:newAvatarImage];
        
        // Upload picture
        // We retain 'self' on purpose during this operation in order to keep saving changes when the user leaves the settings screen.
        MXMediaLoader *uploader = [MXMediaManager prepareUploaderWithMatrixSession:account.mxSession initialRange:0 andRange:1.0];
        [uploader uploadData:UIImageJPEGRepresentation(updatedPicture, 0.5) filename:nil mimeType:@"image/jpeg" success:^(NSString *url) {
            
            // Store uploaded picture url and trigger picture saving
            self->uploadedAvatarURL = url;
            self->newAvatarImage = nil;
            [self onSave:nil];
            
        } failure:^(NSError *error) {
            
            NSLog(@"[SettingsViewController] Failed to upload image");
            [self handleErrorDuringProfileChangeSaving:error];
            
        }];
        
        return;
    }
    else if (uploadedAvatarURL)
    {
        // We retain 'self' on purpose during this operation in order to keep saving changes when the user leaves the settings screen.
        [account setUserAvatarUrl:uploadedAvatarURL success:^{
            
            self->uploadedAvatarURL = nil;
            [self onSave:nil];
            
        } failure:^(NSError *error) {
            
            NSLog(@"[SettingsViewController] Failed to set avatar url");
            [self handleErrorDuringProfileChangeSaving:error];
            
        }];
        
        return;
    }
    
    // Backup is complete
    [self stopActivityIndicator];
    
    // Check whether the settings screen is still visible
    if (self.navigationController)
    {
        [self.tableView reloadData];
    }
}

- (void)handleErrorDuringProfileChangeSaving:(NSError*)error
{
    // Sanity check: retrieve the current root view controller
    UIViewController *rootViewController = [AppDelegate theDelegate].window.rootViewController;
    if (rootViewController)
    {
        __weak typeof(self) weakSelf = self;
        
        // Alert user
        NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
        if (!title)
        {
            title = [NSBundle mxk_localizedStringForKey:@"settings_fail_to_update_profile"];
        }
        NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
        
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        
        currentAlert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
        
        [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"abort"]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               
                                                               self->currentAlert = nil;
                                                               
                                                               // Discard picture change
                                                               self->uploadedAvatarURL = nil;
                                                               self->newAvatarImage = nil;
                                                               
                                                               // Loop to end saving
                                                               [self onSave:nil];
                                                           }
                                                           
                                                       }]];
        
        [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"retry"]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               
                                                               self->currentAlert = nil;
                                                               
                                                               // Loop to retry saving
                                                               [self onSave:nil];
                                                           }
                                                           
                                                       }]];
        
        [currentAlert mxk_setAccessibilityIdentifier: @"SettingsVCSaveChangesFailedAlert"];
        [rootViewController presentViewController:currentAlert animated:YES completion:nil];
    }
}

- (void)updateSaveButtonStatus
{
    self.navigationItem.rightBarButtonItem.enabled = (nil != newAvatarImage);
}

- (void)onProfileAvatarTap:(UITapGestureRecognizer *)recognizer
{
    mediaPicker = [MediaPickerViewController mediaPickerViewController];
    mediaPicker.mediaTypes = @[(NSString *)kUTTypeImage];
    mediaPicker.delegate = self;
    UINavigationController *navigationController = [UINavigationController new];
    [navigationController pushViewController:mediaPicker animated:NO];
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)exportEncryptionKeys:(UITapGestureRecognizer *)recognizer
{
    [currentAlert dismissViewControllerAnimated:NO completion:nil];

    exportView = [[MXKEncryptionKeysExportView alloc] initWithMatrixSession:self.mainSession];
    currentAlert = exportView.alertController;

    // Use a temporary file for the export
    keyExportsFile = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"tchap-keys.txt"]];

    // Make sure the file is empty
    [self deleteKeyExportFile];

    // Show the export dialog
    __weak typeof(self) weakSelf = self;
    [exportView showInViewController:self toExportKeysToFile:keyExportsFile onComplete:^(BOOL success) {

        if (weakSelf)
        {
             typeof(self) self = weakSelf;
            self->currentAlert = nil;
            self->exportView = nil;

            if (success)
            {
                // Let another app handling this file
                self->documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:keyExportsFile];
                [self->documentInteractionController setDelegate:self];

                if ([self->documentInteractionController presentOptionsMenuFromRect:self.view.bounds inView:self.view animated:YES])
                {
                    // We want to delete the temp keys file after it has been processed by the other app.
                    // We use [UIDocumentInteractionControllerDelegate didEndSendingToApplication] for that
                    // but it is not reliable for all cases (see http://stackoverflow.com/a/21867096).
                    // So, arm a timer to auto delete the file after 10mins.
                    keyExportsFileDeletionTimer = [NSTimer scheduledTimerWithTimeInterval:600 target:self selector:@selector(deleteKeyExportFile) userInfo:self repeats:NO];
                }
                else
                {
                    self->documentInteractionController = nil;
                    [self deleteKeyExportFile];
                }
            }
        }
    }];
}

- (void)deleteKeyExportFile
{
    // Cancel the deletion timer if it is still here
    if (keyExportsFileDeletionTimer)
    {
        [keyExportsFileDeletionTimer invalidate];
        keyExportsFileDeletionTimer = nil;
    }

    // And delete the file
    if (keyExportsFile && [[NSFileManager defaultManager] fileExistsAtPath:keyExportsFile.path])
    {
        [[NSFileManager defaultManager] removeItemAtPath:keyExportsFile.path error:nil];
    }
}

- (void)deactivateAccountAction
{
    DeactivateAccountViewController *deactivateAccountViewController = [DeactivateAccountViewController instantiateWithMatrixSession:self.mainSession];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:deactivateAccountViewController];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self presentViewController:navigationController animated:YES completion:nil];
    
    deactivateAccountViewController.delegate = self;
    
    self.deactivateAccountViewController = deactivateAccountViewController;
}

#pragma mark - MediaPickerViewController Delegate

- (void)dismissMediaPicker
{
    if (mediaPicker)
    {
        [mediaPicker withdrawViewControllerAnimated:YES completion:nil];
        mediaPicker = nil;
    }
}

- (void)mediaPickerController:(MediaPickerViewController *)mediaPickerController didSelectImage:(NSData*)imageData withMimeType:(NSString *)mimetype isPhotoLibraryAsset:(BOOL)isPhotoLibraryAsset
{
    [self dismissMediaPicker];
    
    newAvatarImage = [UIImage imageWithData:imageData];
    
    [self.tableView reloadData];
}

- (void)mediaPickerController:(MediaPickerViewController *)mediaPickerController didSelectVideo:(NSURL*)videoURL
{
    // this method should not be called
    [self dismissMediaPicker];
}

#pragma mark - UITextField delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField.tag == userSettingsDisplayNameIndex)
    {
        textField.textAlignment = NSTextAlignmentLeft;
    }
}
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField.tag == userSettingsDisplayNameIndex)
    {
        textField.textAlignment = NSTextAlignmentRight;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.tag == userSettingsDisplayNameIndex)
    {
        [textField resignFirstResponder];
    }
    else if (textField == newPasswordTextField2)
    {
        [newPasswordTextField2 resignFirstResponder];
        return NO;
    }
    
    return YES;
}

#pragma password update management

- (void)promptUserBeforePasswordChange
{
    MXWeakify(self);
    [resetPwdAlertController dismissViewControllerAnimated:NO completion:nil];
    
    resetPwdAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"warning", @"Vector", nil) message:NSLocalizedStringFromTable(@"settings_change_pwd_caution", @"Tchap", nil) preferredStyle:UIAlertControllerStyleAlert];
    resetPwdAlertController.accessibilityLabel=@"promptUserBeforePasswordChange";
    UIAlertAction  *continueAction = [UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"continue", @"Vector", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        
        MXStrongifyAndReturnIfNil(self);
        self->resetPwdAlertController = nil;
        [self displayPasswordAlert];
        
    }];
    
    UIAlertAction  *exportAction = [UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"settings_crypto_export", @"Vector", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        
        MXStrongifyAndReturnIfNil(self);
        self->resetPwdAlertController = nil;
        [self exportEncryptionKeys:nil];
        
    }];
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        
        MXStrongifyAndReturnIfNil(self);
        self->resetPwdAlertController = nil;
        
    }];
    
    [resetPwdAlertController addAction:continueAction];
    [resetPwdAlertController addAction:exportAction];
    [resetPwdAlertController addAction:cancel];
    [self presentViewController:resetPwdAlertController animated:YES completion:nil];
}

- (IBAction)passwordTextFieldDidChange:(id)sender
{
    savePasswordAction.enabled = (currentPasswordTextField.text.length > 0) && (newPasswordTextField1.text.length > 7) && [newPasswordTextField1.text isEqualToString:newPasswordTextField2.text];
}

- (void)displayPasswordAlert
{
    MXWeakify(self);
    [resetPwdAlertController dismissViewControllerAnimated:NO completion:nil];
    
    resetPwdAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"settings_change_password", @"Vector", nil)
                                                                  message:NSLocalizedStringFromTable(@"settings_change_pwd_message", @"Tchap", nil) preferredStyle:UIAlertControllerStyleAlert];
    resetPwdAlertController.accessibilityLabel=@"ChangePasswordAlertController";
    savePasswordAction = [UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"save", @"Vector", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        
        MXStrongifyAndReturnIfNil(self);
        self->resetPwdAlertController = nil;
        
        if ([MXKAccountManager sharedManager].activeAccounts.count > 0)
        {
            [self startActivityIndicator];
            
            // We retain 'self' on purpose during this operation in order to keep saving changes when the user leaves the settings screen.
            MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
            [account changePassword:self->currentPasswordTextField.text with:self->newPasswordTextField1.text success:^{
                
                [self stopActivityIndicator];
                
                // Display a successful message only if the settings screen is still visible
                if (self.navigationController)
                {
                    MXWeakify(self);
                    [self->currentAlert dismissViewControllerAnimated:NO completion:nil];
                    
                    self->currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"settings_change_pwd_success_title", @"Tchap", nil) message:NSLocalizedStringFromTable(@"settings_change_pwd_success_msg", @"Tchap", nil) preferredStyle:UIAlertControllerStyleAlert];
                    
                    [self->currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                                           style:UIAlertActionStyleDefault
                                                                         handler:^(UIAlertAction * action) {
                                                                             
                                                                             MXStrongifyAndReturnIfNil(self);
                                                                             self->currentAlert = nil;
                                                                             
                                                                         }]];
                    
                    [self->currentAlert mxk_setAccessibilityIdentifier:@"SettingsVCOnPasswordUpdatedAlert"];
                    [self presentViewController:self->currentAlert animated:YES completion:nil];
                }
                
            } failure:^(NSError *error) {
                
                [self stopActivityIndicator];
                
                // Display a failure message on the current screen
                UIViewController *rootViewController = [AppDelegate theDelegate].window.rootViewController;
                if (rootViewController)
                {
                    MXWeakify(self);
                    [self->currentAlert dismissViewControllerAnimated:NO completion:nil];
                    
                    NSString *alertTitle = NSLocalizedStringFromTable(@"settings_fail_to_update_password", @"Vector", nil);
                    NSString *alertMessage = [self detailedMessageOnPasswordUpdateFailure:error];
                    if (!alertMessage)
                    {
                        alertMessage = alertTitle;
                        alertTitle = nil;
                    }
                    
                    self->currentAlert = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
                    
                    [self->currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                                                   style:UIAlertActionStyleDefault
                                                                                 handler:^(UIAlertAction * action) {
                                                                                     
                                                                                     MXStrongifyAndReturnIfNil(self);
                                                                                     self->currentAlert = nil;
                                                                                     
                                                                                 }]];
                    
                    [self->currentAlert mxk_setAccessibilityIdentifier:@"SettingsVCPasswordChangeFailedAlert"];
                    [rootViewController presentViewController:self->currentAlert animated:YES completion:nil];
                }
                
            }];
        }
        
    }];
    
    // disable by default
    // check if the textfields have the right value
    savePasswordAction.enabled = NO;
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        
        MXStrongifyAndReturnIfNil(self);
        self->resetPwdAlertController = nil;
        
    }];
    
    [resetPwdAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        
        MXStrongifyAndReturnIfNil(self);
        self->currentPasswordTextField = textField;
        self->currentPasswordTextField.placeholder = NSLocalizedStringFromTable(@"settings_old_password", @"Vector", nil);
        self->currentPasswordTextField.secureTextEntry = YES;
        self->currentPasswordTextField.returnKeyType = UIReturnKeyNext;
        if (@available(iOS 11.0, *)) {
            self->currentPasswordTextField.textContentType = UITextContentTypePassword;
        }
        [self->currentPasswordTextField addTarget:self action:@selector(passwordTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
         
     }];
    
    [resetPwdAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        
        MXStrongifyAndReturnIfNil(self);
        self->newPasswordTextField1 = textField;
        self->newPasswordTextField1.placeholder = NSLocalizedStringFromTable(@"settings_new_password", @"Vector", nil);
        self->newPasswordTextField1.secureTextEntry = YES;
        self->newPasswordTextField1.returnKeyType = UIReturnKeyNext;
        [self->newPasswordTextField1 addTarget:self action:@selector(passwordTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        
    }];
    
    [resetPwdAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        
        MXStrongifyAndReturnIfNil(self);
        self->newPasswordTextField2 = textField;
        self->newPasswordTextField2.placeholder = NSLocalizedStringFromTable(@"settings_confirm_password", @"Vector", nil);
        self->newPasswordTextField2.secureTextEntry = YES;
        self->newPasswordTextField2.returnKeyType = UIReturnKeyDone;
        self->newPasswordTextField2.delegate = self;
        [self->newPasswordTextField2 addTarget:self action:@selector(passwordTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        
    }];

    
    [resetPwdAlertController addAction:cancel];
    [resetPwdAlertController addAction:savePasswordAction];
    [self presentViewController:resetPwdAlertController animated:YES completion:nil];
}

- (nullable NSString *)detailedMessageOnPasswordUpdateFailure:(NSError *)error
{
    // Check for specific password policy error
    NSDictionary* dict = error.userInfo;
    NSString *message = nil;
    if (dict)
    {
        NSString* errCode = [dict valueForKey:@"errcode"];
        if (errCode)
        {
            if ([errCode isEqualToString:kMXErrCodeStringPasswordTooShort])
            {
                message = NSLocalizedStringFromTable(@"password_policy_too_short_pwd_error", @"Tchap", nil);;
            }
            else if ([errCode isEqualToString:kMXErrCodeStringPasswordNoDigit]
                     || [errCode isEqualToString:kMXErrCodeStringPasswordNoSymbol]
                     || [errCode isEqualToString:kMXErrCodeStringPasswordNoUppercase]
                     || [errCode isEqualToString:kMXErrCodeStringPasswordNoLowercase]
                     || [errCode isEqualToString:kMXErrCodeStringWeakPassword])
            {
                message = NSLocalizedStringFromTable(@"password_policy_weak_pwd_error", @"Tchap", nil);;
            }
            else if ([errCode isEqualToString:kMXErrCodeStringPasswordInDictionary])
            {
                message = NSLocalizedStringFromTable(@"password_policy_pwd_in_dict_error", @"Tchap", nil);;
            }
        }
    }
    return message;
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application
{
    // If iOS wants to call this method, this is the right time to remove the file
    [self deleteKeyExportFile];
}

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    documentInteractionController = nil;
}

#pragma mark - MXKCountryPickerViewControllerDelegate

- (void)countryPickerViewController:(MXKCountryPickerViewController *)countryPickerViewController didSelectCountry:(NSString *)isoCountryCode
{
    if (countryPickerViewController.view.tag == SETTINGS_SECTION_CONTACTS_INDEX)
    {
        [MXKAppSettings standardAppSettings].phonebookCountryCode = isoCountryCode;
    }
    
    [countryPickerViewController withdrawViewControllerAnimated:YES completion:nil];
}

#pragma mark - MXKCountryPickerViewControllerDelegate

- (void)languagePickerViewController:(MXKLanguagePickerViewController *)languagePickerViewController didSelectLangugage:(NSString *)language
{
    [languagePickerViewController withdrawViewControllerAnimated:YES completion:nil];

    if (![language isEqualToString:[NSBundle mxk_language]]
        || (language == nil && [NSBundle mxk_language]))
    {
        [NSBundle mxk_setLanguage:language];

        // Store user settings
        NSUserDefaults *sharedUserDefaults = [MXKAppSettings standardAppSettings].sharedUserDefaults;
        [sharedUserDefaults setObject:language forKey:@"appLanguage"];

        // Do a reload in order to recompute strings in the new language
        // Note that "reloadMatrixSessionsByClearingCache:NO" will reset room summaries
        if (_delegate)
        {
            [self startActivityIndicator];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                
                [self.delegate settingsViewController:self reloadMatrixSessionsByClearingCache:NO];
                
            });
        }
    }
}

#pragma mark - DeactivateAccountViewControllerDelegate

- (void)deactivateAccountViewControllerDidDeactivateWithSuccess:(DeactivateAccountViewController *)deactivateAccountViewController
{
    NSLog(@"[SettingsViewController] Deactivate account with success");

    
    [[AppDelegate theDelegate] logoutSendingRequestServer:NO completion:^(BOOL isLoggedOut) {
        NSLog(@"[SettingsViewController] Complete clear user data after account deactivation");
    }];
}

- (void)deactivateAccountViewControllerDidCancel:(DeactivateAccountViewController *)deactivateAccountViewController
{
    [deactivateAccountViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Hide from users directory

- (BOOL)isHiddenFromUsersDirectory:(MXSession *)session
{
    BOOL isHidden = NO;
    NSDictionary *content = [session.accountData accountDataForEventType:@"im.vector.hide_profile"];
    if (content && content[@"hide_profile"])
    {
        MXJSONModelSetBoolean(isHidden, content[@"hide_profile"]);
    }
    return isHidden;
}

- (void)toggleHideFromUsersDirectory:(id)sender
{
    UISwitch *switchButton = (UISwitch*)sender;
    MXKAccount *account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    MXSession *session = [account mxSession];
    if (session)
    {
        NSDictionary *dict = @{@"hide_profile": [NSNumber numberWithBool:switchButton.on]};
        
        MXWeakify(self);
        [self startActivityIndicator];
        [account.mxSession setAccountData:dict forType:@"im.vector.hide_profile" success:^{
            MXStrongifyAndReturnIfNil(self);
            [self stopActivityIndicator];
        } failure:^(NSError *error) {
            MXStrongifyAndReturnIfNil(self);
            [self stopActivityIndicator];
            NSLog(@"[SettingsViewController] toggleHideFromUsersDirectory failed");
            
            NSString *myUserId = account.mxSession.myUser.userId;
            [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
            [self refreshSettings];
        }];
    }
}

@end
