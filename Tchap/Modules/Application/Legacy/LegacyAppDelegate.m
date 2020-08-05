/*
 Copyright 2014 OpenMarket Ltd
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

#import "LegacyAppDelegate.h"

#import <Intents/Intents.h>
#import <Contacts/Contacts.h>

#import "RoomDataSource.h"

#import "EventFormatter.h"

#import "RoomViewController.h"

#import "BugReportViewController.h"
#import "RoomKeyRequestViewController.h"

#import <MatrixKit/MatrixKit.h>

#import "Tools.h"
#import "WidgetManager.h"

#import "AFNetworkReachabilityManager.h"

#import "PushNotificationService.h"

#import <AudioToolbox/AudioToolbox.h>

#include <MatrixSDK/MXUIKitBackgroundModeHandler.h>

#import "WebViewViewController.h"

// Calls
#import "CallViewController.h"

#import "MXSession+Riot.h"
#import "MXRoom+Riot.h"

#import "GeneratedInterface-Swift.h"

//#define MX_CALL_STACK_OPENWEBRTC
#ifdef MX_CALL_STACK_OPENWEBRTC
#import <MatrixOpenWebRTCWrapper/MatrixOpenWebRTCWrapper.h>
#endif

#ifdef MX_CALL_STACK_ENDPOINT
#import <MatrixEndpointWrapper/MatrixEndpointWrapper.h>
#endif


#if __has_include(<MatrixSDK/MXJingleCallStack.h>)
// Tchap: Disable voip call for the moment
//#define CALL_STACK_JINGLE
#endif
#ifdef CALL_STACK_JINGLE
#import <MatrixSDK/MXJingleCallStack.h>

#endif

#define CALL_STATUS_BAR_HEIGHT 44

#define MAKE_STRING(x) #x
#define MAKE_NS_STRING(x) @MAKE_STRING(x)

NSString *const kAppDelegateNetworkStatusDidChangeNotification = @"kAppDelegateNetworkStatusDidChangeNotification";
NSString *const kLegacyAppDelegateDidLogoutNotification = @"kLegacyAppDelegateDidLogoutNotification";
NSString *const kLegacyAppDelegateDidLoginNotification = @"kLegacyAppDelegateDidLoginNotification";

@interface LegacyAppDelegate () <GDPRConsentViewControllerDelegate, KeyVerificationCoordinatorBridgePresenterDelegate, ServiceTermsModalCoordinatorBridgePresenterDelegate>
{
    /**
     Reachability observer
     */
    id reachabilityObserver;
    
    /**
     MatrixKit error observer
     */
    id matrixKitErrorObserver;
    
    /**
     matrix session observer used to detect new opened sessions.
     */
    id matrixSessionStateObserver;
    
    /**
     matrix account observers.
     */
    id addedAccountObserver;
    id removedAccountObserver;
    
    /**
     matrix call observer used to handle incoming/outgoing call.
     */
    id matrixCallObserver;
    
    /**
     The current call view controller (if any).
     */
    CallViewController *currentCallViewController;

    /**
     Incoming room key requests observers
     */
    id roomKeyRequestObserver;
    id roomKeyRequestCancellationObserver;

    /**
     If any the currently displayed sharing key dialog
     */
    RoomKeyRequestViewController *roomKeyRequestViewController;
    BOOL isCheckPendingKeyRequestsInProgress;

    /**
     Incoming key verification requests observers
     */
    id incomingKeyVerificationObserver;

    /**
     If any the currently displayed key verification dialog
     */
    KeyVerificationCoordinatorBridgePresenter *keyVerificationCoordinatorBridgePresenter;

    /**
     Account picker used in case of multiple account.
     */
    UIAlertController *accountPicker;
    
    /**
     Array of `MXSession` instances.
     */
    NSMutableArray *mxSessionArray;
    
    /**
     Suspend the error notifications when the navigation stack of the root view controller is updating.
     */
    BOOL isErrorNotificationSuspended;
    
    /**
     The listeners to call events.
     There is one listener per MXSession.
     The key is an identifier of the MXSession. The value, the listener.
     */
    NSMutableDictionary *callEventsListeners;

    /**
     Currently displayed "Call not supported" alert.
     */
    UIAlertController *noCallSupportAlert;
    
    /**
     Prompt to ask the user to log in again.
     */
    UIAlertController *cryptoDataCorruptedAlert;

    /**
     Prompt to warn the user about a new backup on the homeserver.
     */
    UIAlertController *wrongBackupVersionAlert;

    /**
     The launch screen container view
     */
    UIView *launchScreenContainerView;
    NSDate *launchAnimationStart;
}

@property (strong, nonatomic) UIAlertController *logoutConfirmation;

@property (weak, nonatomic) UIAlertController *gdprConsentNotGivenAlertController;
@property (weak, nonatomic) UIViewController *gdprConsentController;

@property (weak, nonatomic) UIAlertController *incomingKeyVerificationRequestAlertController;

@property (nonatomic, strong) ServiceTermsModalCoordinatorBridgePresenter *serviceTermsModalCoordinatorBridgePresenter;
@property (nonatomic, strong) SlidingModalPresenter *slidingModalPresenter;

@property (nonatomic, weak) id userDidSignInOnNewDeviceObserver;
@property (weak, nonatomic) UIAlertController *userNewSignInAlertController;

/**
 Related push notification service instance. Will be created when launch finished.
 */
@property (nonatomic, strong) PushNotificationService *pushNotificationService;

@end

@implementation LegacyAppDelegate

#pragma mark -

+ (void)initialize
{
    NSLog(@"[AppDelegate] initialize");
    
    [LegacyAppDelegate setupUserDefaults];

    // Set the App Group identifier.
    MXSDKOptions *sdkOptions = [MXSDKOptions sharedInstance];
    sdkOptions.applicationGroupIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:@"appGroupId"];
    //sdkOptions.computeE2ERoomSummaryTrust = YES; //Tchap: keep using the default value (NO) for this option

    // Redirect NSLogs to files only if we are not debugging
    if (!isatty(STDERR_FILENO))
    {
        [MXLogger redirectNSLogToFiles:YES numberOfFiles:50];
    }

    NSLog(@"[AppDelegate] initialize: Done");
}

+ (instancetype)theDelegate
{
    static LegacyAppDelegate *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[LegacyAppDelegate alloc] init];
    });
    
    return sharedInstance;
}

#pragma mark - Push Notifications

- (void)registerForRemoteNotificationsWithCompletion:(nullable void (^)(NSError *))completion
{
    [self.pushNotificationService registerForRemoteNotificationsWithCompletion:completion];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [self.pushNotificationService didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    
    NSString * deviceTokenString = [[[[deviceToken description]
                                      stringByReplacingOccurrencesOfString: @"<" withString: @""]
                                     stringByReplacingOccurrencesOfString: @">" withString: @""]
                                    stringByReplacingOccurrencesOfString: @" " withString: @""];
    
    NSLog(@"The generated device token string is : %@",deviceTokenString);
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [self.pushNotificationService didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [self.pushNotificationService didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
}

#pragma mark -

- (NSString*)appVersion
{
    if (!_appVersion)
    {
        _appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    }
    
    return _appVersion;
}

- (NSString*)build
{
    if (!_build)
    {
        NSString *buildBranch = nil;
        NSString *buildNumber = nil;
        // Check whether GIT_BRANCH and BUILD_NUMBER were provided during compilation in command line argument.
#ifdef GIT_BRANCH
        buildBranch = MAKE_NS_STRING(GIT_BRANCH);
#endif
#ifdef BUILD_NUMBER
        buildNumber = [NSString stringWithFormat:@"#%@", @(BUILD_NUMBER)];
#endif
        if (buildBranch && buildNumber)
        {
            _build = [NSString stringWithFormat:@"%@ %@", buildBranch, buildNumber];
        } else if (buildNumber){
            _build = buildNumber;
        } else
        {
            _build = buildBranch ? buildBranch : @"";
        }
    }
    return _build;
}

- (void)setIsOffline:(BOOL)isOffline
{
    if (!reachabilityObserver)
    {
        // Define reachability observer when isOffline property is set for the first time
        reachabilityObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AFNetworkingReachabilityDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            
            NSNumber *statusItem = note.userInfo[AFNetworkingReachabilityNotificationStatusItem];
            if (statusItem)
            {
                AFNetworkReachabilityStatus reachabilityStatus = statusItem.integerValue;
                if (reachabilityStatus == AFNetworkReachabilityStatusNotReachable)
                {
                    [AppDelegate theDelegate].isOffline = YES;
                }
                else
                {
                    [AppDelegate theDelegate].isOffline = NO;
                }
            }
            
        }];
    }
    
    if (_isOffline != isOffline)
    {
        _isOffline = isOffline;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kAppDelegateNetworkStatusDidChangeNotification object:nil];
    }
}

- (UINavigationController*)secondaryNavigationController
{
    UIViewController* rootViewController = self.window.rootViewController;
    
    if ([rootViewController isKindOfClass:[UISplitViewController class]])
    {
        UISplitViewController *splitViewController = (UISplitViewController *)rootViewController;
        if (splitViewController.viewControllers.count == 2)
        {
            UIViewController *secondViewController = [splitViewController.viewControllers lastObject];
            
            if ([secondViewController isKindOfClass:[UINavigationController class]])
            {
                return (UINavigationController*)secondViewController;
            }
        }
    }
    
    return nil;
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions
{
    // Create message sound
    NSURL *messageSoundURL = [[NSBundle mainBundle] URLForResource:@"message" withExtension:@"caf"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)messageSoundURL, &_messageSound);
    
    // Prepare the launch screen displayed after the splash screen
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LaunchScreen" bundle:[NSBundle mainBundle]];
    UIViewController *launchScreenVC = [storyboard instantiateViewControllerWithIdentifier:@"LaunchScreenId"];
    launchScreenContainerView = launchScreenVC.view;
    launchScreenContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    NSLog(@"[AppDelegate] willFinishLaunchingWithOptions: Done");

    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSDate *startDate = [NSDate date];
    
#ifdef DEBUG
    // log the full launchOptions only in DEBUG
    NSLog(@"[AppDelegate] didFinishLaunchingWithOptions: %@", launchOptions);
#else
    NSLog(@"[AppDelegate] didFinishLaunchingWithOptions");
#endif

    NSLog(@"[AppDelegate] didFinishLaunchingWithOptions: isProtectedDataAvailable: %@", @([application isProtectedDataAvailable]));

    // Log app information
    NSString *appDisplayName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
    NSString* appVersion = [AppDelegate theDelegate].appVersion;
    NSString* build = [AppDelegate theDelegate].build;
    
    NSLog(@"------------------------------");
    NSLog(@"Application info:");
    NSLog(@"%@ version: %@", appDisplayName, appVersion);
    NSLog(@"MatrixKit version: %@", MatrixKitVersion);
    NSLog(@"MatrixSDK version: %@", MatrixSDKVersion);
    NSLog(@"Build: %@\n", build);
    NSLog(@"------------------------------\n");

    // Set up theme
    ThemeService.shared.themeId = RiotSettings.shared.userInterfaceTheme;

    // Set up runtime language and fallback by considering the userDefaults object shared within the application group.
    NSUserDefaults *sharedUserDefaults = [MXKAppSettings standardAppSettings].sharedUserDefaults;
    NSString *language = [sharedUserDefaults objectForKey:@"appLanguage"];
    if (!language)
    {
        // Check whether a langage was only defined at the Riot application level.
        language = [[NSUserDefaults standardUserDefaults] objectForKey:@"appLanguage"];
        if (language)
        {
            // Move this setting into the shared userDefaults object to apply it to the extensions.
            [sharedUserDefaults setObject:language forKey:@"appLanguage"];

            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"appLanguage"];
        }
    }
    [NSBundle mxk_setLanguage:language];
    [NSBundle mxk_setFallbackLanguage:@"fr"];
    
    // Customize the localized string table
    [NSBundle mxk_customizeLocalizedStringTableName:@"Vector"];
    
    mxSessionArray = [NSMutableArray array];
    callEventsListeners = [NSMutableDictionary dictionary];
    
    _isAppForeground = NO;
    _handleSelfVerificationRequest = YES;
    
    // Tchap: Disable analytics use for the moment.
//    // Configure our analytics. It will indeed start if the option is enabled
//    [MXSDKOptions sharedInstance].analyticsDelegate = [Analytics sharedInstance];
//    [DecryptionFailureTracker sharedInstance].delegate = [Analytics sharedInstance];
//    [[Analytics sharedInstance] start];
    
    // Disable CallKit
    [MXKAppSettings standardAppSettings].enableCallKit = NO;
    
    // Enforce lazy loading
    [MXKAppSettings standardAppSettings].syncWithLazyLoadOfRoomMembers = YES;

    self.pushNotificationService = [PushNotificationService new];
    self.pushNotificationService.delegate = (id<PushNotificationServiceDelegate>)[UIApplication sharedApplication].delegate;
    
    // Add matrix observers, and initialize matrix sessions if the app is not launched in background.
    [self initMatrixSessions];
    
    // Setup Jitsi
// Tchap: JitsiService is not supported
//    NSString *jitsiServerStringURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"jitsiServerURL"];
//    if (jitsiServerStringURL) {
//        NSURL *jitsiServerURL = [NSURL URLWithString:jitsiServerStringURL];
//
//        [JitsiService.shared configureDefaultConferenceOptionsWith:jitsiServerURL];
//
//        [JitsiService.shared application:application didFinishLaunchingWithOptions:launchOptions];
//    }

    NSLog(@"[AppDelegate] didFinishLaunchingWithOptions: Done in %.0fms", [[NSDate date] timeIntervalSinceDate:startDate] * 1000);

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"[AppDelegate] applicationWillResignActive");
    
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    // Release MatrixKit error observer
    if (matrixKitErrorObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:matrixKitErrorObserver];
        matrixKitErrorObserver = nil;
    }
    
    if (self.errorNotification)
    {
        [self.errorNotification dismissViewControllerAnimated:NO completion:nil];
        self.errorNotification = nil;
    }
    
    if (accountPicker)
    {
        [accountPicker dismissViewControllerAnimated:NO completion:nil];
        accountPicker = nil;
    }
    
    if (noCallSupportAlert)
    {
        [noCallSupportAlert dismissViewControllerAnimated:NO completion:nil];
        noCallSupportAlert = nil;
    }
    
    if (cryptoDataCorruptedAlert)
    {
        [cryptoDataCorruptedAlert dismissViewControllerAnimated:NO completion:nil];
        cryptoDataCorruptedAlert = nil;
    }

    if (wrongBackupVersionAlert)
    {
        [wrongBackupVersionAlert dismissViewControllerAnimated:NO completion:nil];
        wrongBackupVersionAlert = nil;
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"[AppDelegate] applicationDidEnterBackground");
    
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    // Stop reachability monitoring
    if (reachabilityObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:reachabilityObserver];
        reachabilityObserver = nil;
    }
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:nil];
    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
    
    // check if some media must be released to reduce the cache size
    [MXMediaManager reduceCacheSizeToInsert:0];
    
    // Suspend all running matrix sessions
    NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
    for (MXKAccount *account in mxAccounts)
    {
        [account pauseInBackgroundTask];
    }
    
    // Refresh the notifications counter
    [self refreshApplicationIconBadgeNumber];
    
    _isAppForeground = NO;
    
    // Analytics: Force to send the pending actions
    [[DecryptionFailureTracker sharedInstance] dispatch];
    [[Analytics sharedInstance] dispatch];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"[AppDelegate] applicationWillEnterForeground");
    
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

    // Notify push notification service
    [self.pushNotificationService applicationWillEnterForeground];

    // Force each session to refresh here their publicised groups by user dictionary.
    // When these publicised groups are retrieved for a user, they are cached and reused until the app is backgrounded and enters in the foreground again
    for (MXSession *session in mxSessionArray)
    {
        [session markOutdatedPublicisedGroupsByUserData];
    }
    
    _isAppForeground = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"[AppDelegate] applicationDidBecomeActive");
    
    // Check if there is crash log to send
    if (RiotSettings.shared.enableCrashReport)
    {
        [self checkExceptionToReport];
    }
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

    // Check if an initial sync failure occured while the app was in background
    MXSession *mainSession = self.mxSessions.firstObject;
    if (mainSession.state == MXSessionStateInitialSyncFailed)
    {
        // Inform the end user why the app appears blank
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                             code:NSURLErrorCannotConnectToHost
                                         userInfo:@{NSLocalizedDescriptionKey : NSLocalizedStringFromTable(@"homeserver_connection_lost", @"Vector", nil)}];

        [self showErrorAsAlert:error];
    }
    
    // Register to GDPR consent not given notification
    [self registerUserConsentNotGivenNotification];
    
    // Register to identity server terms not signed notification
    [self registerIdentityServiceTermsNotSignedNotification];
    
    // Start monitoring reachability
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        // Check whether monitoring is ready
        if (status != AFNetworkReachabilityStatusUnknown)
        {
            if (status == AFNetworkReachabilityStatusNotReachable)
            {
                // Prompt user
                [[AppDelegate theDelegate] showErrorAsAlert:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:@{NSLocalizedDescriptionKey : NSLocalizedStringFromTable(@"network_offline_prompt", @"Vector", nil)}]];
            }
            else
            {
                self.isOffline = NO;
            }
            
            // Use a dispatch to avoid to kill ourselves
            dispatch_async(dispatch_get_main_queue(), ^{
                [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:nil];
            });
        }
        
    }];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    // Observe matrixKit error to alert user on error
    matrixKitErrorObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKErrorNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        [self showErrorAsAlert:note.object];
        
    }];
    
    // Observe crypto data storage corruption
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSessionCryptoDidCorruptData:) name:kMXSessionCryptoDidCorruptDataNotification object:nil];

    // Observe wrong backup version
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBackupStateDidChangeNotification:) name:kMXKeyBackupDidStateChangeNotification object:nil];

    // Resume all existing matrix sessions
    NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
    for (MXKAccount *account in mxAccounts)
    {
        [account resume];
    }
    
    _isAppForeground = YES;

    if (@available(iOS 11.0, *))
    {
        // Riot has its own dark theme. Prevent iOS from applying its one
        [application keyWindow].accessibilityIgnoresInvertColors = YES;
    }
    
    [self handleLaunchAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"[AppDelegate] applicationWillTerminate");
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    NSLog(@"[AppDelegate] applicationDidReceiveMemoryWarning");
}

#pragma mark - Application layout handling

- (UIAlertController*)showErrorAsAlert:(NSError*)error
{
    // Ignore fake error, or connection cancellation error
    if (!error || ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled))
    {
        return nil;
    }
    
    // Ignore network reachability error when the app is already offline
    if (self.isOffline && [error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorNotConnectedToInternet)
    {
        return nil;
    }
    
    if ([MXError isMXError:error])
    {
        MXError *mxError = [[MXError alloc] initWithNSError:error];
        // Ignore the listed error codes, and the "GDPR Consent not given" already caught by kMXHTTPClientUserConsentNotGivenErrorNotification,
        if ([mxError.errcode isEqualToString:kMXErrCodeStringConsentNotGiven]
            || [self.ignoredServerErrorCodes containsObject:mxError.errcode])
        {
            return nil;
        }
    }

    NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
    NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
    if (!title)
    {
        if (msg)
        {
            title = msg;
            msg = nil;
        }
        else
        {
            title = NSLocalizedStringFromTable(@"error_message_default", @"Tchap", nil);
        }
    }
    
    // Switch in offline mode in case of network reachability error
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorNotConnectedToInternet)
    {
        self.isOffline = YES;
    }
    
    return [self showAlertWithTitle:title message:msg];
}

- (UIAlertController*)showAlertWithTitle:(NSString*)title message:(NSString*)message
{
    [_errorNotification dismissViewControllerAnimated:NO completion:nil];
    _errorNotification = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [_errorNotification addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {

                                                             [AppDelegate theDelegate].errorNotification = nil;

                                                         }]];
    // Display the error notification
    if (!isErrorNotificationSuspended)
    {
        [_errorNotification mxk_setAccessibilityIdentifier:@"AppDelegateErrorAlert"];
        [self showNotificationAlert:_errorNotification];
    }
    
    return self.errorNotification;
}

- (void)showNotificationAlert:(UIAlertController*)alert
{
    [alert popoverPresentationController].sourceView = self.presentedViewController.view;
    [alert popoverPresentationController].sourceRect = self.presentedViewController.view.bounds;
    [self.presentedViewController presentViewController:alert animated:YES completion:nil];
}

- (void)onSessionCryptoDidCorruptData:(NSNotification *)notification
{
    NSString *userId = notification.object;
    
    MXKAccount *account = [[MXKAccountManager sharedManager] accountForUserId:userId];
    if (account)
    {
        if (cryptoDataCorruptedAlert)
        {
            [cryptoDataCorruptedAlert dismissViewControllerAnimated:NO completion:nil];
        }
        
        cryptoDataCorruptedAlert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:NSLocalizedStringFromTable(@"e2e_need_log_in_again", @"Vector", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        __weak typeof(self) weakSelf = self;
        
        [cryptoDataCorruptedAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"later"]
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
                                                                       
                                                                       if (weakSelf)
                                                                       {
                                                                           typeof(self) self = weakSelf;
                                                                           self->cryptoDataCorruptedAlert = nil;
                                                                       }
                                                                       
                                                                   }]];
        
        [cryptoDataCorruptedAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"settings_sign_out"]
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
                                                                       
                                                                       if (weakSelf)
                                                                       {
                                                                           typeof(self) self = weakSelf;
                                                                           self->cryptoDataCorruptedAlert = nil;
                                                                           
                                                                           [[MXKAccountManager sharedManager] removeAccount:account completion:nil];
                                                                       }
                                                                       
                                                                   }]];
        
        [self showNotificationAlert:cryptoDataCorruptedAlert];
    }
}

- (void)keyBackupStateDidChangeNotification:(NSNotification *)notification
{
    MXKeyBackup *keyBackup = notification.object;

    if (keyBackup.state == MXKeyBackupStateWrongBackUpVersion)
    {
        if (wrongBackupVersionAlert)
        {
            [wrongBackupVersionAlert dismissViewControllerAnimated:NO completion:nil];
        }

        wrongBackupVersionAlert = [UIAlertController
                                   alertControllerWithTitle:NSLocalizedStringFromTable(@"e2e_key_backup_wrong_version_title", @"Vector", nil)

                                   message:NSLocalizedStringFromTable(@"e2e_key_backup_wrong_version", @"Vector", nil)

                                   preferredStyle:UIAlertControllerStyleAlert];

        MXWeakify(self);
        [wrongBackupVersionAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"e2e_key_backup_wrong_version_button_settings"]
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action)
                                             {
                                                 MXStrongifyAndReturnIfNil(self);
                                                 self->wrongBackupVersionAlert = nil;

                                                 // TODO: Open settings
                                             }]];

        [wrongBackupVersionAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"e2e_key_backup_wrong_version_button_wasme"]
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action)
                                             {
                                                 MXStrongifyAndReturnIfNil(self);
                                                 self->wrongBackupVersionAlert = nil;
                                             }]];

        [self showNotificationAlert:wrongBackupVersionAlert];
    }
}

#pragma mark - Crash handling

// Check if there is a crash log to send to server
- (void)checkExceptionToReport
{
    // Check if the app crashed last time
    NSString *filePath = [MXLogger crashLog];
    if (filePath)
    {
        // Do not show the crash report dialog if it is already displayed
        if ([self.window.rootViewController.childViewControllers[0] isKindOfClass:[UINavigationController class]]
            && [((UINavigationController*)self.window.rootViewController.childViewControllers[0]).visibleViewController isKindOfClass:[BugReportViewController class]])
        {
            return;
        }
        
        NSString *description = [[NSString alloc] initWithContentsOfFile:filePath
                                                            usedEncoding:nil
                                                                   error:nil];
        
        NSLog(@"[AppDelegate] Promt user to report crash:\n%@", description);

        // Ask the user to send a crash report
        [[RageShakeManager sharedManager] promptCrashReportInViewController:self.window.rootViewController];
    }
}

#pragma mark - Badge Count

- (void)refreshApplicationIconBadgeNumber
{
    // Consider the total number of missed discussions including the invites.
    NSUInteger count = [self missedDiscussionsCount];
    
    NSLog(@"[AppDelegate] refreshApplicationIconBadgeNumber: %tu", count);
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = count;
}

- (NSUInteger)missedDiscussionsCount
{
    NSUInteger roomCount = 0;
    
    // Considering all the current sessions.
    for (MXSession *session in mxSessionArray)
    {
        roomCount += [session vc_missedDiscussionsCount];
    }
    
    return roomCount;
}

#pragma mark - Matrix sessions handling

- (void)initMatrixSessions
{
    NSLog(@"[AppDelegate] initMatrixSessions");
    
    MXSDKOptions *sdkOptions = [MXSDKOptions sharedInstance];
    
    // Define the media cache version
    sdkOptions.mediaCacheAppVersion = 0;
    
    // Enable e2e encryption for newly created MXSession
    sdkOptions.enableCryptoWhenStartingMXSession = YES;
    
    // Disable identicon use
    sdkOptions.disableIdenticonUseForUserAvatar = YES;
    
    // Use UIKit BackgroundTask for handling background tasks in the SDK
    sdkOptions.backgroundModeHandler = [[MXUIKitBackgroundModeHandler alloc] init];

    // Get modular widget events in rooms histories
    [[MXKAppSettings standardAppSettings] addSupportedEventTypes:@[kWidgetMatrixEventTypeString, kWidgetModularEventTypeString]];
    
    // Hide undecryptable messages that were sent while the user was not in the room
    [MXKAppSettings standardAppSettings].hidePreJoinedUndecryptableEvents = YES;
    
    // Tchap: remove some state events from the rooms histories: the history access, encryption
    [[MXKAppSettings standardAppSettings] removeSupportedEventTypes:@[kMXEventTypeStringRoomHistoryVisibility, kMXEventTypeStringRoomEncryption]];
    
    // Enable long press on event in bubble cells
    [MXKRoomBubbleTableViewCell disableLongPressGestureOnEvent:NO];
    
    // Set first RoomDataSource class used in Vector
    [MXKRoomDataSourceManager registerRoomDataSourceClass:RoomDataSource.class];
    
    // Register matrix session state observer in order to handle multi-sessions.
    matrixSessionStateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionStateDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        MXSession *mxSession = (MXSession*)notif.object;
        
        // Check whether the concerned session is a new one
        if (mxSession.state == MXSessionStateInitialised)
        {
            // Store this new session
            [self addMatrixSession:mxSession];
            
            // Set the VoIP call stack (if supported).
            id<MXCallStack> callStack;
            
#ifdef MX_CALL_STACK_OPENWEBRTC
            callStack = [[MXOpenWebRTCCallStack alloc] init];
#endif
#ifdef MX_CALL_STACK_ENDPOINT
            callStack = [[MXEndpointCallStack alloc] initWithMatrixId:mxSession.myUser.userId];
#endif
#ifdef CALL_STACK_JINGLE
            callStack = [[MXJingleCallStack alloc] init];
#endif
            if (callStack)
            {
                [mxSession enableVoIPWithCallStack:callStack];

                // Let's call invite be valid for 1 minute
                mxSession.callManager.inviteLifetime = 60000;

                if (RiotSettings.shared.allowStunServerFallback)
                {
                    mxSession.callManager.fallbackSTUNServer = RiotSettings.shared.stunServerFallback;
                }

                // Setup CallKit
                if ([MXCallKitAdapter callKitAvailable])
                {
                    BOOL isCallKitEnabled = [MXKAppSettings standardAppSettings].isCallKitEnabled;
                    [self enableCallKit:isCallKitEnabled forCallManager:mxSession.callManager];
                    
                    // Register for changes performed by the user
                    [[MXKAppSettings standardAppSettings] addObserver:self
                                                           forKeyPath:@"enableCallKit"
                                                              options:NSKeyValueObservingOptionNew
                                                              context:NULL];
                }
                else
                {
                    [self enableCallKit:NO forCallManager:mxSession.callManager];
                }
            }
            else
            {
                // When there is no call stack, display alerts on call invites
                [self enableNoVoIPOnMatrixSession:mxSession];
            }
            
            // Each room member will be considered as a potential contact.
            [MXKContactManager sharedManager].contactManagerMXRoomSource = MXKContactManagerMXRoomSourceAll;

            // Send read receipts for widgets events too
            NSMutableArray<MXEventTypeString> *acknowledgableEventTypes = [NSMutableArray arrayWithArray:mxSession.acknowledgableEventTypes];
            [acknowledgableEventTypes addObject:kWidgetMatrixEventTypeString];
            [acknowledgableEventTypes addObject:kWidgetModularEventTypeString];
            mxSession.acknowledgableEventTypes = acknowledgableEventTypes;
        }
        else if (mxSession.state == MXSessionStateStoreDataReady)
        {
            // A new call observer may be added here
            [self addMatrixCallObserver];
            
            // Clean the storage by removing expired data
            [mxSession tc_removeExpiredMessages];
            
            // Do not warn for unknown devices. We have cross-signing now
            mxSession.crypto.warnOnUnknowDevices = NO;
            
//            // Register to user new device sign in notification
//            [self registerUserDidSignInOnNewDeviceNotificationForSession:mxSession];
//
//            // Register to new key verification request
//            [self registerNewRequestNotificationForSession:mxSession];
//
//            [self checkLocalPrivateKeysInSession:mxSession];
        }
        else if (mxSession.state == MXSessionStateClosed)
        {
            [self removeMatrixSession:mxSession];
        }
        else if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
        {
            if (mxSession.state == MXSessionStateRunning)
            {
                // Check if we need to display a key share dialog
                [self checkPendingRoomKeyRequests];
                [self checkPendingIncomingKeyVerificationsInSession:mxSession];
            }
        }
        
        [self handleLaunchAnimation];
    }];
    
    // Register an observer in order to handle new account
    addedAccountObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountManagerDidAddAccountNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        // Finalize the initialization of this new account
        MXKAccount *account = notif.object;
        if (account)
        {
            // Replace default room summary updater
            EventFormatter *eventFormatter = [[EventFormatter alloc] initWithMatrixSession:account.mxSession];
            eventFormatter.isForSubtitle = YES;
            account.mxSession.roomSummaryUpdateDelegate = eventFormatter;
            
            // Set the push gateway URL.
            account.pushGatewayURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"pushGatewayURL"];

            BOOL isPushRegistered = self.pushNotificationService.isPushRegistered;

            NSLog(@"[AppDelegate][Push] didAddAccountNotification: isPushRegistered: %@", @(isPushRegistered));

            if (isPushRegistered)
            {
                // Enable push notifications by default on new added account
                [account enablePushNotifications:YES success:nil failure:nil];
            }
            else
            {
                // Set up push notifications
                [self.pushNotificationService registerUserNotificationSettings];
            }
        }
        
        // Load the local contacts on first account creation.
        if ([MXKAccountManager sharedManager].accounts.count == 1)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self refreshLocalContacts];
                
            });
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kLegacyAppDelegateDidLoginNotification object:nil];
        }
    }];
    
    // Add observer to handle removed accounts
    removedAccountObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountManagerDidRemoveAccountNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        // Clear Modular data
        MXKAccount *account = notif.object;
        [[WidgetManager sharedManager] deleteDataForUser:account.mxCredentials.userId];
        
        // Logout the app when there is no available account
        if (![MXKAccountManager sharedManager].accounts.count)
        {
            [self logoutWithConfirmation:NO completion:nil];
        }
    }];

//    // Add observer to handle soft logout // Not supported in Tchap
//    [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountManagerDidSoftlogoutAccountNotification  object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
//
//        MXKAccount *account = notif.object;
//        [self removeMatrixSession:account.mxSession];
//
//        // Return to authentication screen
//        [self.masterTabBarController showAuthenticationScreenAfterSoftLogout:account.mxCredentials];
//    }];
    
    // Prepare account manager
    MXKAccountManager *accountManager = [MXKAccountManager sharedManager];
    
    // Use MXFileStore as MXStore to permanently store events.
    accountManager.storeClass = [MXFileStore class];
    
    // Observers have been defined, we can start a matrix session for each enabled accounts.
    NSLog(@"[AppDelegate] initMatrixSessions: prepareSessionForActiveAccounts (app state: %tu)", [[UIApplication sharedApplication] applicationState]);
    [accountManager prepareSessionForActiveAccounts];
    
    // Check whether we're already logged in
    NSArray *mxAccounts = accountManager.activeAccounts;
    if (mxAccounts.count)
    {
        for (MXKAccount *account in mxAccounts)
        {
            // Replace default room summary updater
            EventFormatter *eventFormatter = [[EventFormatter alloc] initWithMatrixSession:account.mxSession];
            eventFormatter.isForSubtitle = YES;
            account.mxSession.roomSummaryUpdateDelegate = eventFormatter;
            
            // The push gateway url is now configurable.
            // Set this url in the existing accounts when it is undefined.
            if (!account.pushGatewayURL)
            {
                account.pushGatewayURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"pushGatewayURL"];
            }
        }
        
        // Set up push notifications
        [self.pushNotificationService registerUserNotificationSettings];
    }
}

- (NSArray*)mxSessions
{
    return [NSArray arrayWithArray:mxSessionArray];
}

- (void)addMatrixSession:(MXSession *)mxSession
{
    if (mxSession)
    {
        // Report this session to contact manager
        // But wait a bit that our launch animation screen is ready to show and
        // displayed if needed. As the processing in MXKContactManager can lock
        // the UI thread for several seconds, it is better to show the animation
        // during this blocking task.
        dispatch_after(dispatch_walltime(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [[MXKContactManager sharedManager] addMatrixSession:mxSession];

            // Load the local contacts on first account
            if ([MXKAccountManager sharedManager].accounts.count == 1)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self refreshLocalContacts];
                });
            }
        });

        // Register the session to the widgets manager
        [[WidgetManager sharedManager] addMatrixSession:mxSession];
        
        [mxSessionArray addObject:mxSession];
        
        // Do the one time check on device id
        [self checkDeviceId:mxSession];

        // Enable listening of incoming key share requests
        [self enableRoomKeyRequestObserver:mxSession];

        // Enable listening of incoming key verification requests
        [self enableIncomingKeyVerificationObserver:mxSession];
    }
}

- (void)removeMatrixSession:(MXSession*)mxSession
{
    [[MXKContactManager sharedManager] removeMatrixSession:mxSession];

    // Update the widgets manager
    [[WidgetManager sharedManager] removeMatrixSession:mxSession]; 
    
    // If any, disable the no VoIP support workaround
    [self disableNoVoIPOnMatrixSession:mxSession];

    // Disable listening of incoming key share requests
    [self disableRoomKeyRequestObserver:mxSession];

    // Disable listening of incoming key verification requests
    [self disableIncomingKeyVerificationObserver:mxSession];
    
    [mxSessionArray removeObject:mxSession];
    
    if (!mxSessionArray.count && matrixCallObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:matrixCallObserver];
        matrixCallObserver = nil;
    }
}

- (void)markAllMessagesAsRead
{
    for (MXSession *session in mxSessionArray)
    {
        [session markAllMessagesAsRead];
    }
}

- (void)removeDeliveredNotificationsWithRoomId:(NSString*)roomId completion:(dispatch_block_t)completion;
{
    [self.pushNotificationService removeDeliveredNotificationsWithRoomId:roomId completion:completion];
}

- (void)logoutWithConfirmation:(BOOL)askConfirmation completion:(void (^)(BOOL isLoggedOut))completion
{
    // Check whether we have to ask confirmation before logging out.
    if (askConfirmation)
    {
        if (self.logoutConfirmation)
        {
            [self.logoutConfirmation dismissViewControllerAnimated:NO completion:nil];
            self.logoutConfirmation = nil;
        }
        
        __weak typeof(self) weakSelf = self;
        
        NSString *message = NSLocalizedStringFromTable(@"settings_sign_out_confirmation", @"Vector", nil);
        
        // If the user has encrypted rooms, warn he will lose his e2e keys
        MXSession *session = self.mxSessions.firstObject;
        for (MXRoom *room in session.rooms)
        {
            if (room.summary.isEncrypted)
            {
                message = [message stringByAppendingString:[NSString stringWithFormat:@"\n\n%@", NSLocalizedStringFromTable(@"settings_sign_out_e2e_warn", @"Vector", nil)]];
                break;
            }
        }
        
        // Ask confirmation
        self.logoutConfirmation = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"settings_sign_out", @"Vector", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
        
        [self.logoutConfirmation addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"settings_sign_out", @"Vector", nil)
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               self.logoutConfirmation = nil;
                                                               
                                                               dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                                                   
                                                                   [self logoutWithConfirmation:NO completion:completion];
                                                                   
                                                               });
                                                           }
                                                           
                                                       }]];
        
        [self.logoutConfirmation addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               self.logoutConfirmation = nil;
                                                               
                                                               if (completion)
                                                               {
                                                                   completion(NO);
                                                               }
                                                           }
                                                           
                                                       }]];
        
        [self.logoutConfirmation mxk_setAccessibilityIdentifier: @"AppDelegateLogoutConfirmationAlert"];
        [self showNotificationAlert:self.logoutConfirmation];
        return;
    }
    
    [self logoutSendingRequestServer:YES completion:^(BOOL isLoggedOut) {
        if (completion)
        {
            completion (YES);
        }
        
        if (isLoggedOut)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kLegacyAppDelegateDidLogoutNotification object:nil];
        }
    }];
}

- (void)logoutSendingRequestServer:(BOOL)sendLogoutServerRequest
                        completion:(void (^)(BOOL isLoggedOut))completion
{
    [self.pushNotificationService deregisterRemoteNotifications];

    // Clear cache
    [MXMediaManager clearCache];
    
    // Reset key backup banner preferences
    [SecureBackupBannerPreferences.shared reset];
    
    // Reset key verification banner preferences
    [CrossSigningBannerPreferences.shared reset];
    
#ifdef MX_CALL_STACK_ENDPOINT
    // Erase all created certificates and private keys by MXEndpointCallStack
    for (MXKAccount *account in MXKAccountManager.sharedManager.accounts)
    {
        if ([account.mxSession.callManager.callStack isKindOfClass:MXEndpointCallStack.class])
        {
            [(MXEndpointCallStack*)account.mxSession.callManager.callStack deleteData:account.mxSession.myUser.userId];
        }
    }
#endif
    
    // Logout all matrix account
    [[MXKAccountManager sharedManager] logoutWithCompletion:^{
        
        if (completion)
        {
            completion (YES);
        }
        
        // Note: Keep App settings
        // But enforce usage of member lazy loading
        [MXKAppSettings standardAppSettings].syncWithLazyLoadOfRoomMembers = YES;
        
        // Reset the contact manager
        [[MXKContactManager sharedManager] reset];
        
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == [MXKAppSettings standardAppSettings] && [keyPath isEqualToString:@"enableCallKit"])
    {
        BOOL isCallKitEnabled = [MXKAppSettings standardAppSettings].isCallKitEnabled;
        MXCallManager *callManager = [[[[[MXKAccountManager sharedManager] activeAccounts] firstObject] mxSession] callManager];
        [self enableCallKit:isCallKitEnabled forCallManager:callManager];
    }
}

- (void)addMatrixCallObserver
{
    if (matrixCallObserver)
    {
        return;
    }
    
    MXWeakify(self);
    
    // Register call observer in order to handle incoming calls
    matrixCallObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXCallManagerNewCall
                                                                           object:nil
                                                                            queue:[NSOperationQueue mainQueue]
                                                                       usingBlock:^(NSNotification *notif)
    {
        MXStrongifyAndReturnIfNil(self);
        
        // Ignore the call if a call is already in progress
        if (!self->currentCallViewController && !self->_jitsiViewController)
        {
            MXCall *mxCall = (MXCall*)notif.object;
            
            BOOL isCallKitEnabled = [MXCallKitAdapter callKitAvailable] && [MXKAppSettings standardAppSettings].isCallKitEnabled;
            
            // Prepare the call view controller
            self->currentCallViewController = [CallViewController callViewController:nil];
            self->currentCallViewController.playRingtone = !isCallKitEnabled;
            self->currentCallViewController.mxCall = mxCall;
            self->currentCallViewController.delegate = self;

            UIApplicationState applicationState = UIApplication.sharedApplication.applicationState;
            
            // App has been woken by PushKit notification in the background
            if (applicationState == UIApplicationStateBackground && mxCall.isIncoming)
            {
                // Create backgound task.
                // Without CallKit this will allow us to play vibro until the call was ended
                // With CallKit we'll inform the system when the call is ended to let the system terminate our app to save resources
                id<MXBackgroundModeHandler> handler = [MXSDKOptions sharedInstance].backgroundModeHandler;
                id<MXBackgroundTask> callBackgroundTask = [handler startBackgroundTaskWithName:@"[AppDelegate] addMatrixCallObserver" expirationHandler:nil];
                
                MXWeakify(self);
                
                // Start listening for call state change notifications
                __weak NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
                __block id token = [[NSNotificationCenter defaultCenter] addObserverForName:kMXCallStateDidChange
                                                                                     object:mxCall
                                                                                      queue:nil
                                                                                 usingBlock:^(NSNotification * _Nonnull note) {
                                                        
                                                                                     MXStrongifyAndReturnIfNil(self);
                    
                                                                                     MXCall *call = (MXCall *)note.object;
                                                                                     
                                                                                     if (call.state == MXCallStateEnded)
                                                                                     {
                                                                                         // Set call vc to nil to let our app handle new incoming calls even it wasn't killed by the system
                                                                                         [self->currentCallViewController destroy];
                                                                                         self->currentCallViewController = nil;
                                                                                         [notificationCenter removeObserver:token];
                                                                                         [callBackgroundTask stop];
                                                                                     }
                                                                                 }];
            }
            
            if (mxCall.isIncoming && isCallKitEnabled)
            {
                MXWeakify(self);
                
                // Let's CallKit display the system incoming call screen
                // Show the callVC only after the user answered the call
                __weak NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
                __block id token = [[NSNotificationCenter defaultCenter] addObserverForName:kMXCallStateDidChange
                                                                                     object:mxCall
                                                                                      queue:nil
                                                                                 usingBlock:^(NSNotification * _Nonnull note) {
                    
                                                                                     MXStrongifyAndReturnIfNil(self);
                    
                                                                                     MXCall *call = (MXCall *)note.object;
                                                                                     
                                                                                     NSLog(@"[AppDelegate] call.state: %@", call);
                                                                                     
                                                                                     if (call.state == MXCallStateCreateAnswer)
                                                                                     {
                                                                                         [notificationCenter removeObserver:token];
                                                                                         
                                                                                         NSLog(@"[AppDelegate] presentCallViewController");
                                                                                         [self presentCallViewController:NO completion:nil];
                                                                                     }
                                                                                     else if (call.state == MXCallStateEnded)
                                                                                     {
                                                                                         [notificationCenter removeObserver:token];
                                                                                         
                                                                                         // Set call vc to nil to let our app handle new incoming calls even it wasn't killed by the system
                                                                                         [self dismissCallViewController:self->currentCallViewController completion:nil];
                                                                                     }
                                                                                 }];
            }
            else
            {
                [self presentCallViewController:YES completion:nil];
            }
        }
    }];
}

- (void)handleLaunchAnimation
{
    MXSession *mainSession = self.mxSessions.firstObject;
    
    if (mainSession)
    {
        BOOL isLaunching = NO;
        
        switch (mainSession.state)
        {
            case MXSessionStateClosed:
            case MXSessionStateInitialised:
                isLaunching = YES;
                break;
            case MXSessionStateStoreDataReady:
            case MXSessionStateSyncInProgress:
                // Stay in launching during the first server sync if the store is empty.
                isLaunching = (mainSession.rooms.count == 0 && launchScreenContainerView.superview);
            default:
                break;
        }
        
        if (isLaunching)
        {
            UIWindow *window = [[UIApplication sharedApplication] keyWindow];
            if (!launchScreenContainerView.superview && window)
            {
                [window addSubview:launchScreenContainerView];
                launchAnimationStart = [NSDate date];
            }
            
            return;
        }
    }
    
    if (launchScreenContainerView.superview)
    {
        NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:launchAnimationStart];
        NSLog(@"[AppDelegate] LaunchScreen was shown for %.3fms", duration * 1000);

        // Track it on our analytics
        [[Analytics sharedInstance] trackLaunchScreenDisplayDuration:duration];

        // TODO: Send durationMs to Piwik
        // Such information should be the same on all platforms
        
        [launchScreenContainerView removeFromSuperview];
    }
}

- (void)enableCallKit:(BOOL)enable forCallManager:(MXCallManager *)callManager
{
// Tchap: JitsiService is not supported
//    JitsiService.shared.enableCallKit = enable;
    
    if (enable)
    {
        // Create adapter for Tchap
        MXCallKitConfiguration *callKitConfiguration = [[MXCallKitConfiguration alloc] init];
        callKitConfiguration.iconName = @"tchap_icon_callkit";

// Tchap: JitsiService is not supported
//        NSData *callKitIconData = UIImagePNGRepresentation([UIImage imageNamed:callKitConfiguration.iconName]);
//
//        [JitsiService.shared configureCallKitProviderWithLocalizedName:callKitConfiguration.name
//                                                          ringtoneName:callKitConfiguration.ringtoneName
//                                                 iconTemplateImageData:callKitIconData];

        MXCallKitAdapter *callKitAdapter = [[MXCallKitAdapter alloc] initWithConfiguration:callKitConfiguration];
        
        id<MXCallAudioSessionConfigurator> audioSessionConfigurator;
        
#ifdef CALL_STACK_JINGLE
        audioSessionConfigurator = [[MXJingleCallAudioSessionConfigurator alloc] init];
#endif
        
        callKitAdapter.audioSessionConfigurator = audioSessionConfigurator;
        
        callManager.callKitAdapter = callKitAdapter;
    }
    else
    {
        callManager.callKitAdapter = nil;
    }
}

- (void)checkLocalPrivateKeysInSession:(MXSession*)mxSession
{
    id<MXCryptoStore> cryptoStore = mxSession.crypto.store;
    NSUInteger keysCount = 0;
    if ([cryptoStore secretWithSecretId:MXSecretId.keyBackup])
    {
        keysCount++;
    }
    if ([cryptoStore secretWithSecretId:MXSecretId.crossSigningUserSigning])
    {
        keysCount++;
    }
    if ([cryptoStore secretWithSecretId:MXSecretId.crossSigningSelfSigning])
    {
        keysCount++;
    }
    
    if ((keysCount > 0 && keysCount < 3)
        || (mxSession.crypto.crossSigning.canTrustCrossSigning && !mxSession.crypto.crossSigning.canCrossSign))
    {
        // We should have 3 of them. If not, request them again as mitigation
        NSLog(@"[AppDelegate] checkLocalPrivateKeysInSession: request keys because keysCount = %@", @(keysCount));
        [mxSession.crypto requestAllPrivateKeys];
    }
}

#pragma mark -

/**
 Check the existence of device id.
 */
- (void)checkDeviceId:(MXSession*)mxSession
{
    // In case of the app update for the e2e encryption, the app starts with
    // no device id provided by the homeserver.
    // Ask the user to login again in order to enable e2e. Ask it once
    if (!isErrorNotificationSuspended && ![[NSUserDefaults standardUserDefaults] boolForKey:@"deviceIdAtStartupChecked"])
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"deviceIdAtStartupChecked"];
        
        // Check if there is a device id
        if (!mxSession.matrixRestClient.credentials.deviceId)
        {
            NSLog(@"WARNING: The user has no device. Prompt for login again");
            
            NSString *msg = NSLocalizedStringFromTable(@"e2e_enabling_on_app_update", @"Vector", nil);
            
            __weak typeof(self) weakSelf = self;
            [_errorNotification dismissViewControllerAnimated:NO completion:nil];
            _errorNotification = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
            
            [_errorNotification addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"later"]
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action) {
                                                                     
                                                                     if (weakSelf)
                                                                     {
                                                                         typeof(self) self = weakSelf;
                                                                         self->_errorNotification = nil;
                                                                     }
                                                                     
                                                                 }]];
            
            [_errorNotification addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action) {
                                                                     
                                                                     if (weakSelf)
                                                                     {
                                                                         typeof(self) self = weakSelf;
                                                                         self->_errorNotification = nil;
                                                                         
                                                                         [self logoutWithConfirmation:NO completion:nil];
                                                                     }
                                                                     
                                                                 }]];
            
            // Prompt the user
            [_errorNotification mxk_setAccessibilityIdentifier:@"AppDelegateErrorAlert"];
            [self showNotificationAlert:_errorNotification];
        }
    }
}

- (void)presentViewController:(UIViewController*)viewController
                     animated:(BOOL)animated
                   completion:(void (^)(void))completion
{
    [self.presentedViewController presentViewController:viewController animated:animated completion:completion];
}

- (UIViewController*)presentedViewController
{
    return self.window.rootViewController.presentedViewController ?: self.window.rootViewController;
}

#pragma mark - Matrix Accounts handling

- (void)selectMatrixAccount:(void (^)(MXKAccount *selectedAccount))onSelection
{
    NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
    
    if (mxAccounts.count == 1)
    {
        if (onSelection)
        {
            onSelection(mxAccounts.firstObject);
        }
    }
    else if (mxAccounts.count > 1)
    {
        [accountPicker dismissViewControllerAnimated:NO completion:nil];
        
        accountPicker = [UIAlertController alertControllerWithTitle:[NSBundle mxk_localizedStringForKey:@"select_account"] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        __weak typeof(self) weakSelf = self;
        for(MXKAccount *account in mxAccounts)
        {
            [accountPicker addAction:[UIAlertAction actionWithTitle:account.mxCredentials.userId
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {
                                                                
                                                                if (weakSelf)
                                                                {
                                                                    typeof(self) self = weakSelf;
                                                                    self->accountPicker = nil;
                                                                    
                                                                    if (onSelection)
                                                                    {
                                                                        onSelection(account);
                                                                    }
                                                                }
                                                                
                                                            }]];
        }
        
        [accountPicker addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                          style:UIAlertActionStyleCancel
                                                        handler:^(UIAlertAction * action) {
                                                            
                                                            if (weakSelf)
                                                            {
                                                                typeof(self) self = weakSelf;
                                                                self->accountPicker = nil;
                                                                
                                                                if (onSelection)
                                                                {
                                                                    onSelection(nil);
                                                                }
                                                            }
                                                            
                                                        }]];
        
        [self showNotificationAlert:accountPicker];
    }
}

#pragma mark - Contacts handling

- (void)refreshLocalContacts
{
    // Tchap: An identity server is defined by default. The user accepts to use it when he accepts
    // the Terms on registration
//    // Do not scan local contacts in background if the user has not decided yet about using
//    // an identity server
//    BOOL doRefreshLocalContacts = NO;
//    for (MXSession *session in mxSessionArray)
//    {
//        if (session.hasAccountDataIdentityServerValue)
//        {
//            doRefreshLocalContacts = YES;
//            break;
//        }
//    }
    BOOL doRefreshLocalContacts = YES;

    // Check whether the application is allowed to access the local contacts.
    if (doRefreshLocalContacts
        && [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusAuthorized)
    {
        // Check the user permission for syncing local contacts. This permission was handled independently on previous application version.
        if (![MXKAppSettings standardAppSettings].syncLocalContacts)
        {
            // Check whether it was not requested yet.
            if (![MXKAppSettings standardAppSettings].syncLocalContactsPermissionRequested)
            {
                [MXKAppSettings standardAppSettings].syncLocalContactsPermissionRequested = YES;
                
                [MXKContactManager requestUserConfirmationForLocalContactsSyncInViewController:self.presentedViewController completionHandler:^(BOOL granted) {
                    
                    if (granted)
                    {
                        // Allow local contacts sync in order to discover matrix users.
                        [MXKAppSettings standardAppSettings].syncLocalContacts = YES;
                    }
                    
                }];
            }
        }
        
        // Refresh the local contacts list.
        [[MXKContactManager sharedManager] refreshLocalContacts];
    }
}

#pragma mark - MXKCallViewControllerDelegate

- (void)dismissCallViewController:(MXKCallViewController *)callViewController completion:(void (^)(void))completion
{
    if (currentCallViewController && callViewController == currentCallViewController)
    {
        if (callViewController.isBeingPresented)
        {
            // Here the presentation of the call view controller is in progress
            // Postpone the dismiss
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self dismissCallViewController:callViewController completion:completion];
            });
        }
        // Check whether the call view controller is actually presented
        else if (callViewController.presentingViewController)
        {
            BOOL callIsEnded = (callViewController.mxCall.state == MXCallStateEnded);
            NSLog(@"Call view controller is dismissed (%d)", callIsEnded);
            
            [callViewController dismissViewControllerAnimated:YES completion:^{
                
                if (!callIsEnded)
                {
                    NSString *btnTitle = [NSString stringWithFormat:NSLocalizedStringFromTable(@"active_call_details", @"Vector", nil), callViewController.callerNameLabel.text];
                    [self addCallStatusBar:btnTitle];
                }

                if ([callViewController isKindOfClass:[CallViewController class]]
                    && ((CallViewController*)callViewController).shouldPromptForStunServerFallback)
                {
                    [self promptForStunServerFallback];
                }
                
                if (completion)
                {
                    completion();
                }
                
            }];
            
            if (callIsEnded)
            {
                [self removeCallStatusBar];
                
                // Release properly
                [currentCallViewController destroy];
                currentCallViewController = nil;
            }
        }
        else if (_callStatusBarWindow)
        {
            // Here the call view controller was not presented.
            NSLog(@"Call view controller was not presented");
            
            // Workaround to manage the "back to call" banner: present temporarily the call screen.
            // This will correctly manage the navigation bar layout.
            [self presentCallViewController:YES completion:^{
                
                [self dismissCallViewController:currentCallViewController completion:completion];
                
            }];
        }
        else
        {
            // Release properly
            [currentCallViewController destroy];
            currentCallViewController = nil;
        }
    }
}

- (void)promptForStunServerFallback
{
    [_errorNotification dismissViewControllerAnimated:NO completion:nil];

    NSString *stunFallbackHost = RiotSettings.shared.stunServerFallback;
    // Remove "stun:"
    stunFallbackHost = [stunFallbackHost componentsSeparatedByString:@":"].lastObject;

    MXSession *mainSession = self.mxSessions.firstObject;
    NSString *homeServerName = mainSession.matrixRestClient.credentials.homeServerName;

    NSString *message = [NSString stringWithFormat:@"%@\n\n%@",
                         [NSString stringWithFormat:NSLocalizedStringFromTable(@"call_no_stun_server_error_message_1", @"Vector", nil), homeServerName],
                         [NSString stringWithFormat: NSLocalizedStringFromTable(@"call_no_stun_server_error_message_2", @"Vector", nil), stunFallbackHost]];

    _errorNotification = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"call_no_stun_server_error_title", @"Vector", nil)
                                                             message:message
                                                      preferredStyle:UIAlertControllerStyleAlert];

    [_errorNotification addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat: NSLocalizedStringFromTable(@"call_no_stun_server_error_use_fallback_button", @"Vector", nil), stunFallbackHost]
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {

                                                             RiotSettings.shared.allowStunServerFallback = YES;
                                                             mainSession.callManager.fallbackSTUNServer = RiotSettings.shared.stunServerFallback;

                                                             [AppDelegate theDelegate].errorNotification = nil;
                                                         }]];

    [_errorNotification addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {

                                                             RiotSettings.shared.allowStunServerFallback = NO;

                                                             [AppDelegate theDelegate].errorNotification = nil;
                                                         }]];

    // Display the error notification
    if (!isErrorNotificationSuspended)
    {
        [_errorNotification mxk_setAccessibilityIdentifier:@"AppDelegateErrorAlert"];
        [self showNotificationAlert:_errorNotification];
    }
}

#pragma mark - Jitsi call

- (void)displayJitsiViewControllerWithWidget:(Widget*)jitsiWidget andVideo:(BOOL)video
{
    if (!_jitsiViewController && !currentCallViewController)
    {
// Tchap: JitsiService is not supported
//        MXWeakify(self);
//        [self checkPermissionForNativeWidget:jitsiWidget fromUrl:JitsiService.shared.serverURL completion:^(BOOL granted) {
//            MXStrongifyAndReturnIfNil(self);
//            if (!granted)
//            {
//                return;
//            }
//
//            self->_jitsiViewController = [JitsiViewController jitsiViewController];
//
//            [self->_jitsiViewController openWidget:jitsiWidget withVideo:video success:^{
//
//                self->_jitsiViewController.delegate = self;
//                [self presentJitsiViewController:nil];
//
//            } failure:^(NSError *error) {
//
//                self->_jitsiViewController = nil;
//
//                [self showAlertWithTitle:nil message:NSLocalizedStringFromTable(@"call_jitsi_error", @"Vector", nil)];
//            }];
//        }];
    }
    else
    {
        [self showAlertWithTitle:nil message:NSLocalizedStringFromTable(@"call_already_displayed", @"Vector", nil)];
    }
}

- (void)presentJitsiViewController:(void (^)(void))completion
{
    [self removeCallStatusBar];

    if (_jitsiViewController)
    {
        if (@available(iOS 13.0, *))
        {
            _jitsiViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        }

        [self presentViewController:_jitsiViewController animated:YES completion:completion];
    }
}

- (void)jitsiViewController:(JitsiViewController *)jitsiViewController dismissViewJitsiController:(void (^)(void))completion
{
    if (jitsiViewController == _jitsiViewController)
    {
        [_jitsiViewController dismissViewControllerAnimated:YES completion:completion];
        _jitsiViewController = nil;

        [self removeCallStatusBar];
    }
}

- (void)jitsiViewController:(JitsiViewController *)jitsiViewController goBackToApp:(void (^)(void))completion
{
    if (jitsiViewController == _jitsiViewController)
    {
        [_jitsiViewController dismissViewControllerAnimated:YES completion:^{

            MXRoom *room = [_jitsiViewController.widget.mxSession roomWithRoomId:_jitsiViewController.widget.roomId];
            NSString *btnTitle = [NSString stringWithFormat:NSLocalizedStringFromTable(@"active_call_details", @"Vector", nil), room.summary.displayname];
            [self addCallStatusBar:btnTitle];

            if (completion)
            {
                completion();
            }
        }];
    }
}


#pragma mark - Native Widget Permission

- (void)checkPermissionForNativeWidget:(Widget*)widget fromUrl:(NSURL*)url completion:(void (^)(BOOL granted))completion
{
    MXSession *session = widget.mxSession;

    if ([widget.widgetEvent.sender isEqualToString:session.myUser.userId])
    {
        // No need of more permission check if the user created the widget
        completion(YES);
        return;
    }

    // Check permission in user Riot settings
    __block RiotSharedSettings *sharedSettings = [[RiotSharedSettings alloc] initWithSession:session];

    WidgetPermission permission = [sharedSettings permissionForNative:widget fromUrl:url];
    if (permission == WidgetPermissionGranted)
    {
        completion(YES);
    }
    else
    {
        // Note: ask permission again if the user previously declined it
        [self askNativeWidgetPermissionWithWidget:widget completion:^(BOOL granted) {
            // Update the settings in user account data in parallel
            [sharedSettings setPermission:granted ? WidgetPermissionGranted : WidgetPermissionDeclined
                                forNative:widget fromUrl:url
                                  success:^
             {
                 sharedSettings = nil;
             }
                                  failure:^(NSError * _Nullable error)
             {
                 NSLog(@"[WidgetVC] setPermissionForWidget failed. Error: %@", error);
                 sharedSettings = nil;
             }];
            
            completion(granted);
        }];
    }
}

- (void)askNativeWidgetPermissionWithWidget:(Widget*)widget completion:(void (^)(BOOL granted))completion
{
    if (!self.slidingModalPresenter)
    {
        self.slidingModalPresenter = [SlidingModalPresenter new];
    }
    
    [self.slidingModalPresenter dismissWithAnimated:NO completion:nil];
    
    NSString *widgetCreatorUserId = widget.widgetEvent.sender ?: NSLocalizedStringFromTable(@"room_participants_unknown", @"Vector", nil);
    
    MXSession *session = widget.mxSession;
    MXRoom *room = [session roomWithRoomId:widget.widgetEvent.roomId];
    MXRoomState *roomState = room.dangerousSyncState;
    MXRoomMember *widgetCreatorRoomMember = [roomState.members memberWithUserId:widgetCreatorUserId];
    
    NSString *widgetDomain = @"";
    
    if (widget.url)
    {
        NSString *host = [[NSURL alloc] initWithString:widget.url].host;
        if (host)
        {
            widgetDomain = host;
        }
    }
    
    MXMediaManager *mediaManager = widget.mxSession.mediaManager;
    NSString *widgetCreatorDisplayName = widgetCreatorRoomMember.displayname;
    NSString *widgetCreatorAvatarURL = widgetCreatorRoomMember.avatarUrl;
    
    NSArray<NSString*> *permissionStrings = @[
                                              NSLocalizedStringFromTable(@"room_widget_permission_display_name_permission", @"Vector", nil),
                                              NSLocalizedStringFromTable(@"room_widget_permission_avatar_url_permission", @"Vector", nil)
                                              ];
    
    WidgetPermissionViewModel *widgetPermissionViewModel = [[WidgetPermissionViewModel alloc] initWithCreatorUserId:widgetCreatorUserId
                                                                                                 creatorDisplayName:widgetCreatorDisplayName creatorAvatarUrl:widgetCreatorAvatarURL widgetDomain:widgetDomain
                                                                                                    isWebviewWidget:NO
                                                                                                  widgetPermissions:permissionStrings
                                                                                                       mediaManager:mediaManager];
    
    
    WidgetPermissionViewController *widgetPermissionViewController = [WidgetPermissionViewController instantiateWith:widgetPermissionViewModel];
    
    MXWeakify(self);
    
    widgetPermissionViewController.didTapContinueButton = ^{
        
        MXStrongifyAndReturnIfNil(self);
        
        [self.slidingModalPresenter dismissWithAnimated:YES completion:^{
            completion(YES);
        }];
    };
    
    widgetPermissionViewController.didTapCloseButton = ^{
        
        MXStrongifyAndReturnIfNil(self);
        
        [self.slidingModalPresenter dismissWithAnimated:YES completion:^{
            completion(NO);
        }];
    };
    
    [self.slidingModalPresenter present:widgetPermissionViewController
                                   from:self.presentedViewController
                               animated:YES
                             completion:nil];
}


#pragma mark - Call status handling

/// Returns a suitable height for call status bar. Considers safe area insets if available and notch status.
- (CGFloat)calculateCallStatusBarHeight
{
    CGFloat result = CALL_STATUS_BAR_HEIGHT;
    if (@available(iOS 11.0, *))
    {
        if (UIDevice.currentDevice.hasNotch)
        {
            //  this device has a notch (iPhone X +)
            result += UIApplication.sharedApplication.keyWindow.safeAreaInsets.top;
        }
    }
    return result;
}

- (void)addCallStatusBar:(NSString*)buttonTitle
{
    // Add a call status bar
    CGSize topBarSize = CGSizeMake([[UIScreen mainScreen] bounds].size.width, [self calculateCallStatusBarHeight]);

    _callStatusBarWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, topBarSize.width, topBarSize.height)];
    _callStatusBarWindow.windowLevel = UIWindowLevelStatusBar;
    
    // Create statusBarButton
    _callStatusBarButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _callStatusBarButton.frame = CGRectMake(0, 0, topBarSize.width, topBarSize.height);
    
    [_callStatusBarButton setTitle:buttonTitle forState:UIControlStateNormal];
    [_callStatusBarButton setTitle:buttonTitle forState:UIControlStateHighlighted];
    _callStatusBarButton.titleLabel.textColor = ThemeService.shared.theme.backgroundColor;
    _callStatusBarButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    [_callStatusBarButton setBackgroundColor:kVariant2PrimaryBgColor];
    [_callStatusBarButton addTarget:self action:@selector(onCallStatusBarButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    // Place button into the new window
    [_callStatusBarButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_callStatusBarWindow addSubview:_callStatusBarButton];
    
    // Force callStatusBarButton to fill the window (to handle auto-layout in case of screen rotation)
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:_callStatusBarButton
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:_callStatusBarWindow
                                                                       attribute:NSLayoutAttributeWidth
                                                                      multiplier:1.0
                                                                        constant:0];
    
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:_callStatusBarButton
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:_callStatusBarWindow
                                                                        attribute:NSLayoutAttributeHeight
                                                                       multiplier:1.0
                                                                         constant:0];
    
    [NSLayoutConstraint activateConstraints:@[widthConstraint, heightConstraint]];
    
    _callStatusBarWindow.hidden = NO;
    [self statusBarDidChangeFrame];
    
    // We need to listen to the system status bar size change events to refresh the root controller frame.
    // Else the navigation bar position will be wrong.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(statusBarDidChangeFrame)
                                                 name:UIApplicationDidChangeStatusBarFrameNotification
                                               object:nil];
}

- (void)removeCallStatusBar
{
    if (_callStatusBarWindow)
    {
        // No more need to listen to system status bar changes
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
        
        // Hide & destroy it
        _callStatusBarWindow.hidden = YES;
        [_callStatusBarButton removeFromSuperview];
        _callStatusBarButton = nil;
        _callStatusBarWindow = nil;
        
        [self statusBarDidChangeFrame];
    }
}

- (void)onCallStatusBarButtonPressed
{
    if (currentCallViewController)
    {
        [self presentCallViewController:YES completion:nil];
    }
    else if (_jitsiViewController)
    {
        [self presentJitsiViewController:nil];
    }
}

- (void)presentCallViewController:(BOOL)animated completion:(void (^)(void))completion
{
    [self removeCallStatusBar];
    
    if (currentCallViewController)
    {
        if (@available(iOS 13.0, *))
        {
            currentCallViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        }

        [self presentViewController:currentCallViewController animated:animated completion:completion];
    }
}

- (void)statusBarDidChangeFrame
{
    UIApplication *app = [UIApplication sharedApplication];
    UIViewController *rootController = app.keyWindow.rootViewController;
    
    // Refresh the root view controller frame
    CGRect rootControllerFrame = [[UIScreen mainScreen] bounds];

    if (_callStatusBarWindow)
    {
        CGFloat callStatusBarHeight = [self calculateCallStatusBarHeight];

        UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
        
        switch (statusBarOrientation)
        {
            case UIInterfaceOrientationLandscapeLeft:
            {
                _callStatusBarWindow.frame = CGRectMake(-rootControllerFrame.size.width / 2, -callStatusBarHeight / 2, rootControllerFrame.size.width, callStatusBarHeight);
                _callStatusBarWindow.transform = CGAffineTransformMake(0, -1, 1, 0, callStatusBarHeight / 2, rootControllerFrame.size.width / 2);
                break;
            }
            case UIInterfaceOrientationLandscapeRight:
            {
                _callStatusBarWindow.frame = CGRectMake(-rootControllerFrame.size.width / 2, -callStatusBarHeight / 2, rootControllerFrame.size.width, callStatusBarHeight);
                _callStatusBarWindow.transform = CGAffineTransformMake(0, 1, -1, 0, rootControllerFrame.size.height - callStatusBarHeight / 2, rootControllerFrame.size.width / 2);
                break;
            }
            default:
            {
                _callStatusBarWindow.transform = CGAffineTransformIdentity;
                _callStatusBarWindow.frame = CGRectMake(0, 0, rootControllerFrame.size.width, callStatusBarHeight);
                break;
            }
        }

        UIEdgeInsets callBarButtonContentEdgeInsets = UIEdgeInsetsZero;

        if (@available(iOS 11.0, *))
        {
            callBarButtonContentEdgeInsets = UIApplication.sharedApplication.keyWindow.safeAreaInsets;
            //  should override top inset
            callBarButtonContentEdgeInsets.top = callStatusBarHeight - CALL_STATUS_BAR_HEIGHT;
            //  should ignore bottom inset
            callBarButtonContentEdgeInsets.bottom = 0.0;
            //  should keep left, and right insets as original
        }

        _callStatusBarButton.contentEdgeInsets = callBarButtonContentEdgeInsets;
        
        // Apply the vertical offset due to call status bar
        rootControllerFrame.origin.y = callStatusBarHeight;
        rootControllerFrame.size.height -= callStatusBarHeight;
    }
    
    rootController.view.frame = rootControllerFrame;
    if (rootController.presentedViewController)
    {
        rootController.presentedViewController.view.frame = rootControllerFrame;
    }
    [rootController.view setNeedsLayout];
}

#pragma mark - No call support
/**
 Display a "Call not supported" alert when the session receives a call invitation.
 
 @param mxSession the session to spy
 */
- (void)enableNoVoIPOnMatrixSession:(MXSession*)mxSession
{
    // Listen to call events
    callEventsListeners[@(mxSession.hash)] =
    [mxSession listenToEventsOfTypes:@[
                                       kMXEventTypeStringCallInvite,
                                       kMXEventTypeStringCallCandidates,
                                       kMXEventTypeStringCallAnswer,
                                       kMXEventTypeStringCallHangup
                                       ]
                             onEvent:^(MXEvent *event, MXTimelineDirection direction, id customObject) {
                                 
                                 if (MXTimelineDirectionForwards == direction)
                                 {
                                     switch (event.eventType)
                                     {
                                         case MXEventTypeCallInvite:
                                         {
                                             if (noCallSupportAlert)
                                             {
                                                 [noCallSupportAlert dismissViewControllerAnimated:NO completion:nil];
                                             }
                                             
                                             MXCallInviteEventContent *callInviteEventContent = [MXCallInviteEventContent modelFromJSON:event.content];
                                             
                                             // Sanity and invite expiration checks
                                             if (!callInviteEventContent || event.age >= callInviteEventContent.lifetime)
                                             {
                                                 return;
                                             }
                                             
                                             MXUser *caller = [mxSession userWithUserId:event.sender];
                                             NSString *callerDisplayname = caller.displayname;
                                             if (!callerDisplayname.length)
                                             {
                                                 callerDisplayname = event.sender;
                                             }
                                             
                                             NSString *appDisplayName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
                                             
                                             NSString *message = [NSString stringWithFormat:NSLocalizedStringFromTable(@"no_voip", @"Vector", nil), callerDisplayname, appDisplayName];
                                             
                                             noCallSupportAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"no_voip_title", @"Vector", nil)
                                                                                                      message:message
                                                                                               preferredStyle:UIAlertControllerStyleAlert];
                                             
                                             __weak typeof(self) weakSelf = self;
                                             
                                             [noCallSupportAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ignore"]
                                                                                                    style:UIAlertActionStyleDefault
                                                                                                  handler:^(UIAlertAction * action) {
                                                                                                      
                                                                                                      if (weakSelf)
                                                                                                      {
                                                                                                          typeof(self) self = weakSelf;
                                                                                                          self->noCallSupportAlert = nil;
                                                                                                      }
                                                                                                      
                                                                                                  }]];
                                             
                                             [noCallSupportAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"reject_call"]
                                                                                                    style:UIAlertActionStyleDefault
                                                                                                  handler:^(UIAlertAction * action) {
                                                                                                      
                                                                                                      // Reject the call by sending the hangup event
                                                                                                      NSDictionary *content = @{
                                                                                                                                @"call_id": callInviteEventContent.callId,
                                                                                                                                @"version": @(0)
                                                                                                                                };
                                                                                                      
                                                                                                      [mxSession.matrixRestClient sendEventToRoom:event.roomId eventType:kMXEventTypeStringCallHangup content:content txnId:nil success:nil failure:^(NSError *error) {
                                                                                                          NSLog(@"[AppDelegate] enableNoVoIPOnMatrixSession: ERROR: Cannot send m.call.hangup event.");
                                                                                                      }];
                                                                                                      
                                                                                                      if (weakSelf)
                                                                                                      {
                                                                                                          typeof(self) self = weakSelf;
                                                                                                          self->noCallSupportAlert = nil;
                                                                                                      }
                                                                                                      
                                                                                                  }]];
                                             
                                             [self showNotificationAlert:noCallSupportAlert];
                                             break;
                                         }
                                             
                                         case MXEventTypeCallAnswer:
                                         case MXEventTypeCallHangup:
                                             // The call has ended. The alert is no more needed.
                                             if (noCallSupportAlert)
                                             {
                                                 [noCallSupportAlert dismissViewControllerAnimated:YES completion:nil];
                                                 noCallSupportAlert = nil;
                                             }
                                             break;
                                             
                                         default:
                                             break;
                                     }
                                 }
                                 
                             }];
    
}

- (void)disableNoVoIPOnMatrixSession:(MXSession*)mxSession
{
    // Stop listening to the call events of this session 
    [mxSession removeListener:callEventsListeners[@(mxSession.hash)]];
    [callEventsListeners removeObjectForKey:@(mxSession.hash)];
}

#pragma mark - Incoming room key requests handling

- (void)enableRoomKeyRequestObserver:(MXSession*)mxSession
{
    roomKeyRequestObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:kMXCryptoRoomKeyRequestNotification
                                                      object:mxSession.crypto
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *notif)
     {
         [self checkPendingRoomKeyRequestsInSession:mxSession];
     }];

    roomKeyRequestCancellationObserver  =
    [[NSNotificationCenter defaultCenter] addObserverForName:kMXCryptoRoomKeyRequestCancellationNotification
                                                      object:mxSession.crypto
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *notif)
     {
         [self checkPendingRoomKeyRequestsInSession:mxSession];
     }];
}

- (void)disableRoomKeyRequestObserver:(MXSession*)mxSession
{
    if (roomKeyRequestObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:roomKeyRequestObserver];
        roomKeyRequestObserver = nil;
    }

    if (roomKeyRequestCancellationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:roomKeyRequestCancellationObserver];
        roomKeyRequestCancellationObserver = nil;
    }
}

// Check if a key share dialog must be displayed for the given session
- (void)checkPendingRoomKeyRequestsInSession:(MXSession*)mxSession
{
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive)
    {
        NSLog(@"[AppDelegate] checkPendingRoomKeyRequestsInSession called while the app is not active. Ignore it.");
        return;
    }
    
    if (isCheckPendingKeyRequestsInProgress)
    {
        NSLog(@"[AppDelegate] checkPendingRoomKeyRequestsInSession called while a check is already in progress. Ignore it.");
        return;
    }
    
    MXWeakify(self);
    isCheckPendingKeyRequestsInProgress = YES;
    [mxSession.crypto pendingKeyRequests:^(MXUsersDevicesMap<NSArray<MXIncomingRoomKeyRequest *> *> *pendingKeyRequests) {

        MXStrongifyAndReturnIfNil(self);
        NSLog(@"[AppDelegate] checkPendingRoomKeyRequestsInSession: pendingKeyRequests.count: %@. Already displayed: %@",
              @(pendingKeyRequests.count),
              self->roomKeyRequestViewController ? @"YES" : @"NO");

        if (self->roomKeyRequestViewController)
        {
            // Check if the current RoomKeyRequestViewController is still valid
            MXSession *currentMXSession = self->roomKeyRequestViewController.mxSession;
            NSString *currentUser = self->roomKeyRequestViewController.device.userId;
            NSString *currentDevice = self->roomKeyRequestViewController.device.deviceId;

            NSArray<MXIncomingRoomKeyRequest *> *currentPendingRequest = [pendingKeyRequests objectForDevice:currentDevice forUser:currentUser];

            if (currentMXSession == mxSession && currentPendingRequest.count == 0)
            {
                NSLog(@"[AppDelegate] checkPendingRoomKeyRequestsInSession: Cancel current dialog");

                // The key request has been probably cancelled, remove the popup
                [self->roomKeyRequestViewController hide];
                self->roomKeyRequestViewController = nil;
            }
        }

        if (!self->roomKeyRequestViewController && pendingKeyRequests.count)
        {
            // Pick the first coming user/device pair
            NSString *userId = pendingKeyRequests.userIds.firstObject;
            NSString *deviceId = [pendingKeyRequests deviceIdsForUser:userId].firstObject;

            // Give the client a chance to refresh the device list
            MXWeakify(self);
            [mxSession.crypto downloadKeys:@[userId] forceDownload:NO success:^(MXUsersDevicesMap<MXDeviceInfo *> *usersDevicesInfoMap, NSDictionary<NSString *,MXCrossSigningInfo *> *crossSigningKeysMap) {

                MXStrongifyAndReturnIfNil(self);
                MXDeviceInfo *deviceInfo = [usersDevicesInfoMap objectForDevice:deviceId forUser:userId];
                if (deviceInfo)
                {
                    BOOL wasNewDevice = (deviceInfo.trustLevel.localVerificationStatus == MXDeviceUnknown);
                    
                    MXWeakify(self);
                    void (^openDialog)(void) = ^void()
                    {
                        MXStrongifyAndReturnIfNil(self);
                        NSLog(@"[AppDelegate] checkPendingRoomKeyRequestsInSession: Open dialog for %@", deviceInfo);

                        self->roomKeyRequestViewController = [[RoomKeyRequestViewController alloc] initWithDeviceInfo:deviceInfo wasNewDevice:wasNewDevice andMatrixSession:mxSession onComplete:^{

                            self->roomKeyRequestViewController = nil;

                            // Check next pending key request, if any
                            [self checkPendingRoomKeyRequests];
                        }];

                        self->isCheckPendingKeyRequestsInProgress = NO;
                        [self->roomKeyRequestViewController show];
                    };

                    // If the device was new before, it's not any more.
                    if (wasNewDevice)
                    {
                        [mxSession.crypto setDeviceVerification:MXDeviceUnverified forDevice:deviceId ofUser:userId success:openDialog failure:nil];
                    }
                    else
                    {
                        openDialog();
                    }
                }
                else
                {
                    NSLog(@"[AppDelegate] checkPendingRoomKeyRequestsInSession: No details found for device %@:%@", userId, deviceId);
                    self->isCheckPendingKeyRequestsInProgress = NO;
                    // Ignore this device to avoid to loop on it
                    [mxSession.crypto ignoreAllPendingKeyRequestsFromUser:userId andDevice:deviceId onComplete:^{
                        // And check next requests
                        [self checkPendingRoomKeyRequests];
                    }];
                }

            } failure:^(NSError *error) {
                // Retry
                MXStrongifyAndReturnIfNil(self);
                self->isCheckPendingKeyRequestsInProgress = NO;
                NSLog(@"[AppDelegate] checkPendingRoomKeyRequestsInSession: Failed to download device keys. Retry");
                [self checkPendingRoomKeyRequests];
            }];
        }
        else
        {
            self->isCheckPendingKeyRequestsInProgress = NO;
        }
    }];
}

// Check all opened MXSessions for key share dialog 
- (void)checkPendingRoomKeyRequests
{
    for (MXSession *mxSession in mxSessionArray)
    {
        [self checkPendingRoomKeyRequestsInSession:mxSession];
    }
}

#pragma mark - Incoming key verification handling

- (void)enableIncomingKeyVerificationObserver:(MXSession*)mxSession
{
    incomingKeyVerificationObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:MXKeyVerificationManagerNewTransactionNotification
                                                      object:mxSession.crypto.keyVerificationManager
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *notif)
     {
         NSObject *object = notif.userInfo[MXKeyVerificationManagerNotificationTransactionKey];
         if ([object isKindOfClass:MXIncomingSASTransaction.class])
         {
             [self checkPendingIncomingKeyVerificationsInSession:mxSession];
         }
     }];
}

- (void)disableIncomingKeyVerificationObserver:(MXSession*)mxSession
{
    if (incomingKeyVerificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:incomingKeyVerificationObserver];
        incomingKeyVerificationObserver = nil;
    }
}

// Check if an incoming key verification dialog must be displayed for the given session
- (void)checkPendingIncomingKeyVerificationsInSession:(MXSession*)mxSession
{
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive)
    {
        NSLog(@"[AppDelegate][MXKeyVerification] checkPendingIncomingKeyVerificationsInSession: called while the app is not active. Ignore it.");
        return;
    }

    [mxSession.crypto.keyVerificationManager transactions:^(NSArray<MXKeyVerificationTransaction *> * _Nonnull transactions) {

        NSLog(@"[AppDelegate][MXKeyVerification] checkPendingIncomingKeyVerificationsInSession: transactions: %@", transactions);

        for (MXKeyVerificationTransaction *transaction in transactions)
        {
            if (transaction.isIncoming)
            {
                MXIncomingSASTransaction *incomingTransaction = (MXIncomingSASTransaction*)transaction;
                if (incomingTransaction.state == MXSASTransactionStateIncomingShowAccept)
                {
                    [self presentIncomingKeyVerification:incomingTransaction inSession:mxSession];
                    break;
                }
            }
        }
    }];
}

// Check all opened MXSessions for incoming key verification dialog
- (void)checkPendingIncomingKeyVerifications
{
    for (MXSession *mxSession in mxSessionArray)
    {
        [self checkPendingIncomingKeyVerificationsInSession:mxSession];
    }
}

- (BOOL)presentIncomingKeyVerificationRequest:(MXKeyVerificationRequest*)incomingKeyVerificationRequest
                                    inSession:(MXSession*)session
{
    BOOL presented = NO;
    
    if (!keyVerificationCoordinatorBridgePresenter.isPresenting)
    {
        NSLog(@"[AppDelegate] presentIncomingKeyVerificationRequest");
        
        keyVerificationCoordinatorBridgePresenter = [[KeyVerificationCoordinatorBridgePresenter alloc] initWithSession:session];
        keyVerificationCoordinatorBridgePresenter.delegate = self;
        
        [keyVerificationCoordinatorBridgePresenter presentFrom:self.presentedViewController incomingKeyVerificationRequest:incomingKeyVerificationRequest animated:YES];
        
        presented = YES;
    }
    else
    {
        NSLog(@"[AppDelegate][MXKeyVerification] presentIncomingKeyVerificationRequest: Controller already presented.");
    }
    
    return presented;
}

- (BOOL)presentIncomingKeyVerification:(MXIncomingSASTransaction*)transaction inSession:(MXSession*)mxSession
{
    NSLog(@"[AppDelegate][MXKeyVerification] presentIncomingKeyVerification: %@", transaction);

    BOOL presented = NO;
    if (!keyVerificationCoordinatorBridgePresenter.isPresenting)
    {
        keyVerificationCoordinatorBridgePresenter = [[KeyVerificationCoordinatorBridgePresenter alloc] initWithSession:mxSession];
        keyVerificationCoordinatorBridgePresenter.delegate = self;

        [keyVerificationCoordinatorBridgePresenter presentFrom:self.presentedViewController incomingTransaction:transaction animated:YES];

        presented = YES;
    }
    else
    {
        NSLog(@"[AppDelegate][MXKeyVerification] presentIncomingKeyVerification: Controller already presented.");
    }
    return presented;
}

- (BOOL)presentUserVerificationForRoomMember:(MXRoomMember*)roomMember session:(MXSession*)mxSession
{
    NSLog(@"[AppDelegate][MXKeyVerification] presentUserVerificationForRoomMember: %@", roomMember);
    
    BOOL presented = NO;
    if (!keyVerificationCoordinatorBridgePresenter.isPresenting)
    {
        keyVerificationCoordinatorBridgePresenter = [[KeyVerificationCoordinatorBridgePresenter alloc] initWithSession:mxSession];
        keyVerificationCoordinatorBridgePresenter.delegate = self;
        
        [keyVerificationCoordinatorBridgePresenter presentFrom:self.presentedViewController roomMember:roomMember animated:YES];
        
        presented = YES;
    }
    else
    {
        NSLog(@"[AppDelegate][MXKeyVerification] presentUserVerificationForRoomMember: Controller already presented.");
    }
    return presented;
}

- (BOOL)presentSelfVerificationForOtherDeviceId:(NSString*)deviceId inSession:(MXSession*)mxSession
{
    NSLog(@"[AppDelegate][MXKeyVerification] presentSelfVerificationForOtherDeviceId: %@", deviceId);
    
    BOOL presented = NO;
    if (!keyVerificationCoordinatorBridgePresenter.isPresenting)
    {
        keyVerificationCoordinatorBridgePresenter = [[KeyVerificationCoordinatorBridgePresenter alloc] initWithSession:mxSession];
        keyVerificationCoordinatorBridgePresenter.delegate = self;
        
        [keyVerificationCoordinatorBridgePresenter presentFrom:self.presentedViewController otherUserId:mxSession.myUser.userId otherDeviceId:deviceId animated:YES];
        
        presented = YES;
    }
    else
    {
        NSLog(@"[AppDelegate][MXKeyVerification] presentUserVerificationForRoomMember: Controller already presented.");
    }
    return presented;
}

- (void)keyVerificationCoordinatorBridgePresenterDelegateDidComplete:(KeyVerificationCoordinatorBridgePresenter *)coordinatorBridgePresenter otherUserId:(NSString * _Nonnull)otherUserId otherDeviceId:(NSString * _Nonnull)otherDeviceId
{
    [self dismissKeyVerificationCoordinatorBridgePresenter];
}

- (void)keyVerificationCoordinatorBridgePresenterDelegateDidCancel:(KeyVerificationCoordinatorBridgePresenter * _Nonnull)coordinatorBridgePresenter
{
    [self dismissKeyVerificationCoordinatorBridgePresenter];
}

- (void)dismissKeyVerificationCoordinatorBridgePresenter
{
    [keyVerificationCoordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        [self checkPendingIncomingKeyVerifications];
    }];
    
    keyVerificationCoordinatorBridgePresenter = nil;
}

#pragma mark - New request

- (void)registerNewRequestNotificationForSession:(MXSession*)session
{
    MXKeyVerificationManager *keyverificationManager = session.crypto.keyVerificationManager;
    
    if (!keyverificationManager)
    {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyVerificationNewRequestNotification:) name:MXKeyVerificationManagerNewRequestNotification object:keyverificationManager];
}

- (void)keyVerificationNewRequestNotification:(NSNotification *)notification
{
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)
    {
        return;
    }
    
    NSDictionary *userInfo = notification.userInfo;
    
    MXKeyVerificationRequest *keyVerificationRequest = userInfo[MXKeyVerificationManagerNotificationRequestKey];
    
    if ([keyVerificationRequest isKindOfClass:MXKeyVerificationByDMRequest.class])
    {
        MXKeyVerificationByDMRequest *keyVerificationByDMRequest = (MXKeyVerificationByDMRequest*)keyVerificationRequest;
        
        if (!keyVerificationByDMRequest.isFromMyUser && keyVerificationByDMRequest.state == MXKeyVerificationRequestStatePending)
        {
            MXKAccount *currentAccount = [MXKAccountManager sharedManager].activeAccounts.firstObject;
            MXSession *session = currentAccount.mxSession;
            MXRoom *room = [currentAccount.mxSession roomWithRoomId:keyVerificationByDMRequest.roomId];
            if (!room)
            {
                NSLog(@"[AppDelegate][KeyVerification] keyVerificationRequestDidChangeNotification: Unknown room");
                return;
            }
            
            NSString *sender = keyVerificationByDMRequest.otherUser;

            [room state:^(MXRoomState *roomState) {

                NSString *senderName = [roomState.members memberName:sender];
                
                [self presentNewKeyVerificationRequestAlertForSession:session senderName:senderName senderId:sender request:keyVerificationByDMRequest];
            }];
        }
    }
    else if ([keyVerificationRequest isKindOfClass:MXKeyVerificationByToDeviceRequest.class])
    {
        MXKeyVerificationByToDeviceRequest *keyVerificationByToDeviceRequest = (MXKeyVerificationByToDeviceRequest*)keyVerificationRequest;
        
        if (!keyVerificationByToDeviceRequest.isFromMyDevice
            && keyVerificationByToDeviceRequest.state == MXKeyVerificationRequestStatePending)
        {
            if (keyVerificationByToDeviceRequest.isFromMyUser)
            {
                // Self verification
                NSLog(@"[AppDelegate][KeyVerification] keyVerificationNewRequestNotification: Self verification from %@", keyVerificationByToDeviceRequest.otherDevice);
                
                if (!self.handleSelfVerificationRequest)
                {
                    NSLog(@"[AppDelegate][KeyVerification] keyVerificationNewRequestNotification: Self verification handled elsewhere");
                    return;
                }
                      
                NSString *myUserId = keyVerificationByToDeviceRequest.otherUser;
                MXKAccount *account = [[MXKAccountManager sharedManager] accountForUserId:myUserId];
                if (account)
                {
                    MXSession *session = account.mxSession;
                    MXUser *user = [session userWithUserId:myUserId];
                    
                    [self presentNewKeyVerificationRequestAlertForSession:session senderName:user.displayname senderId:user.userId request:keyVerificationRequest];
                }
            }
            else
            {
                // Device verification from other user
                // This happens when they or our user do not have cross-signing enabled
                NSLog(@"[AppDelegate][KeyVerification] keyVerificationNewRequestNotification: Device verification from other user %@:%@", keyVerificationByToDeviceRequest.otherUser, keyVerificationByToDeviceRequest.otherDevice);
                
                NSString *myUserId = keyVerificationByToDeviceRequest.to;
                NSString *userId = keyVerificationByToDeviceRequest.otherUser;
                MXKAccount *account = [[MXKAccountManager sharedManager] accountForUserId:myUserId];
                if (account)
                {
                    MXSession *session = account.mxSession;
                    MXUser *user = [session userWithUserId:userId];
                    
                    [self presentNewKeyVerificationRequestAlertForSession:session senderName:user.displayname senderId:user.userId request:keyVerificationRequest];
                }
            }
        }
        else
        {
            NSLog(@"[AppDelegate][KeyVerification] keyVerificationNewRequestNotification. Bad request state: %@", keyVerificationByToDeviceRequest);
        }
    }
}

- (void)presentNewKeyVerificationRequestAlertForSession:(MXSession*)session
                                             senderName:(NSString*)senderName
                                               senderId:(NSString*)senderId
                                                request:(MXKeyVerificationRequest*)keyVerificationRequest
{
    if (keyVerificationRequest.state != MXKeyVerificationRequestStatePending)
    {
        NSLog(@"[AppDelegate] presentNewKeyVerificationRequest: Request already accepted. Do not display it");
        return;
    }
    
    if (self.incomingKeyVerificationRequestAlertController)
    {
        [self.incomingKeyVerificationRequestAlertController dismissViewControllerAnimated:NO completion:nil];
    }
    
    NSString *senderInfo;
    
    if (senderName)
    {
        senderInfo = [NSString stringWithFormat:@"%@ (%@)", senderName, senderId];
    }
    else
    {
        senderInfo = senderId;
    }

    
    __block id observer;
    void (^removeObserver)(void) = ^() {
        if (observer)
        {
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
            observer = nil;
        }
    };

    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"key_verification_tile_request_incoming_title", @"Vector", nil)
                                                                                             message:senderInfo
                                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"key_verification_tile_request_incoming_approval_accept", @"Vector", nil)
                                                                                           style:UIAlertActionStyleDefault
                                                                                         handler:^(UIAlertAction * action)
                                                                   {
                                                                       removeObserver();
                                                                       [self presentIncomingKeyVerificationRequest:keyVerificationRequest inSession:session];
                                                                   }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"key_verification_tile_request_incoming_approval_decline", @"Vector", nil)
                                                                                           style:UIAlertActionStyleDestructive
                                                                                         handler:^(UIAlertAction * action)
                                                                   {
                                                                       removeObserver();
                                                                       [keyVerificationRequest cancelWithCancelCode:MXTransactionCancelCode.user success:^{
                                                                           
                                                                       } failure:^(NSError * _Nonnull error) {
                                                                           NSLog(@"[AppDelegate][KeyVerification] Fail to cancel incoming key verification request with error: %@", error);
                                                                       }];
                                                                   }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"later", @"Vector", nil)
                                                                                           style:UIAlertActionStyleCancel
                                                                                         handler:^(UIAlertAction * action)
                                                                   {
                                                                       removeObserver();
                                                                   }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
    self.incomingKeyVerificationRequestAlertController = alertController;
    
    observer = [[NSNotificationCenter defaultCenter] addObserverForName:MXKeyVerificationRequestDidChangeNotification
                                                                 object:keyVerificationRequest
                                                                  queue:[NSOperationQueue mainQueue]
                                                             usingBlock:^(NSNotification * _Nonnull note)
                {
                    if (keyVerificationRequest.state != MXKeyVerificationRequestStatePending)
                    {
                        if (self.incomingKeyVerificationRequestAlertController == alertController)
                        {
                            [self.incomingKeyVerificationRequestAlertController dismissViewControllerAnimated:NO completion:nil];
                            removeObserver();
                        }
                    }
                }];
}

#pragma mark - New Sign In

- (void)registerUserDidSignInOnNewDeviceNotificationForSession:(MXSession*)session
{
    MXCrossSigning *crossSigning = session.crypto.crossSigning;
    
    if (!crossSigning)
    {
        return;
    }
    
    self.userDidSignInOnNewDeviceObserver = [NSNotificationCenter.defaultCenter addObserverForName:MXCrossSigningMyUserDidSignInOnNewDeviceNotification
                                                    object:crossSigning
                                                     queue:[NSOperationQueue mainQueue]
                                                usingBlock:^(NSNotification *notification)
     {
         NSArray<NSString*> *deviceIds = notification.userInfo[MXCrossSigningNotificationDeviceIdsKey];
         
         [session.matrixRestClient devices:^(NSArray<MXDevice *> *devices) {
             
             NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.deviceId IN %@", deviceIds];
             NSArray<MXDevice*> *newDevices = [devices filteredArrayUsingPredicate:predicate];
             
             NSArray *sortedDevices = [newDevices sortedArrayUsingComparator:^NSComparisonResult(MXDevice * _Nonnull device1, MXDevice *  _Nonnull device2) {
                 
                 if (device1.lastSeenTs == device2.lastSeenTs)
                 {
                     return NSOrderedSame;
                 }
                 
                 return device1.lastSeenTs > device2.lastSeenTs ? NSOrderedDescending : NSOrderedAscending;
             }];
             
             MXDevice *mostRecentDevice = sortedDevices.lastObject;
             
             if (mostRecentDevice)
             {
                 [self presentNewSignInAlertForDevice:mostRecentDevice inSession:session];
             }
             
         } failure:^(NSError *error) {
             NSLog(@"[AppDelegate][NewSignIn] Fail to fetch devices");
         }];
     }];
}

- (void)presentNewSignInAlertForDevice:(MXDevice*)device inSession:(MXSession*)session
{
    if (self.userNewSignInAlertController)
    {
        return;
    }
    
    NSString *deviceInfo;
    
    if (device.displayName)
    {
        deviceInfo = [NSString stringWithFormat:@"%@ (%@)", device.displayName, device.deviceId];
    }
    else
    {
        deviceInfo = device.deviceId;
    }
    
    NSString *alertMessage = [NSString stringWithFormat:NSLocalizedStringFromTable(@"device_verification_self_verify_alert_message", @"Vector", nil), deviceInfo];
    
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"device_verification_self_verify_alert_title", @"Vector", nil)
                                                                   message:alertMessage
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"device_verification_self_verify_alert_validate_action", @"Vector", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                
                                                [self presentSelfVerificationForOtherDeviceId:device.deviceId inSession:session];
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"later", @"Vector", nil)
                                               style:UIAlertActionStyleCancel
                                             handler:nil]];
     
    [self presentViewController:alert animated:YES completion:nil];
    
    self.userNewSignInAlertController = alert;
}

#pragma mark - Complete security

- (BOOL)presentCompleteSecurityForSession:(MXSession*)mxSession
{
    NSLog(@"[AppDelegate][MXKeyVerification] presentCompleteSecurityForSession");
    
    BOOL presented = NO;
    if (!keyVerificationCoordinatorBridgePresenter.isPresenting)
    {
        keyVerificationCoordinatorBridgePresenter = [[KeyVerificationCoordinatorBridgePresenter alloc] initWithSession:mxSession];
        keyVerificationCoordinatorBridgePresenter.delegate = self;
        
        [keyVerificationCoordinatorBridgePresenter presentCompleteSecurityFrom:self.presentedViewController isNewSignIn:NO animated:YES];
        
        presented = YES;
    }
    else
    {
        NSLog(@"[AppDelegate][MXKeyVerification] presentCompleteSecurityForSession: Controller already presented.");
    }
    return presented;
}

#pragma mark - GDPR consent

// Observe user GDPR consent not given
- (void)registerUserConsentNotGivenNotification
{
    [NSNotificationCenter.defaultCenter addObserverForName:kMXHTTPClientUserConsentNotGivenErrorNotification
                                                    object:nil
                                                     queue:[NSOperationQueue mainQueue]
                                                usingBlock:^(NSNotification *notification)
    {
        NSString *consentURI = notification.userInfo[kMXHTTPClientUserConsentNotGivenErrorNotificationConsentURIKey];
        if (consentURI
            && self.gdprConsentNotGivenAlertController.presentingViewController == nil
            && self.gdprConsentController.presentingViewController == nil)
        {
            self.gdprConsentNotGivenAlertController = nil;
            self.gdprConsentController = nil;
            
            __weak typeof(self) weakSelf = self;
            
            NSString *alertMessage = NSLocalizedStringFromTable(@"gdpr_consent_not_given_alert_message", @"Tchap", nil);
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"settings_term_conditions", @"Vector", nil)                                        
                                                                           message:alertMessage
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"gdpr_consent_not_given_alert_review_now_action", @"Vector", nil)
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * action) {
                                                        
                                                        typeof(weakSelf) strongSelf = weakSelf;
                                                        
                                                        if (strongSelf)
                                                        {
                                                            [strongSelf presentGDPRConsentFromViewController:self.presentedViewController consentURI:consentURI];
                                                        }
                                                    }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"later", @"Vector", nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            
            [self presentViewController:alert animated:YES completion:nil];
            
            self.gdprConsentNotGivenAlertController = alert;
        }
    }];
}

- (void)presentGDPRConsentFromViewController:(UIViewController*)viewController consentURI:(NSString*)consentURI
{
    GDPRConsentViewController *gdprConsentViewController = [[GDPRConsentViewController alloc] initWithURL:consentURI];    
    
    UIBarButtonItem *closeBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle mxk_localizedStringForKey:@"close"]
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:self
                                                                          action:@selector(dismissGDPRConsent)];
    
    gdprConsentViewController.navigationItem.leftBarButtonItem = closeBarButtonItem;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:gdprConsentViewController];
    
    [viewController presentViewController:navigationController animated:YES completion:nil];
    
    self.gdprConsentController = navigationController;
    
    gdprConsentViewController.delegate = self;
}

- (void)dismissGDPRConsent
{    
    [self.gdprConsentController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - GDPRConsentViewControllerDelegate

- (void)gdprConsentViewControllerDidConsentToGDPRWithSuccess:(GDPRConsentViewController *)gdprConsentViewController
{
    // Leave the GDPR consent right now
    [self dismissGDPRConsent];
}

#pragma mark - Identity server service terms

// Observe identity server terms not signed notification
- (void)registerIdentityServiceTermsNotSignedNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleIdentityServiceTermsNotSignedNotification:) name:MXIdentityServiceTermsNotSignedNotification object:nil];
}

- (void)handleIdentityServiceTermsNotSignedNotification:(NSNotification*)notification
{
    NSLog(@"[AppDelegate] IS Terms: handleIdentityServiceTermsNotSignedNotification.");
    
    NSString *baseURL;
    NSString *accessToken;
    
    MXJSONModelSetString(baseURL, notification.userInfo[MXIdentityServiceNotificationIdentityServerKey]);
    MXJSONModelSetString(accessToken, notification.userInfo[MXIdentityServiceNotificationAccessTokenKey]);
    
    [self presentIdentityServerTermsWithBaseURL:baseURL andAccessToken:accessToken];
}

- (void)presentIdentityServerTermsWithBaseURL:(NSString*)baseURL andAccessToken:(NSString*)accessToken
{
    MXSession *mxSession = self.mxSessions.firstObject;
    
    if (!mxSession || !baseURL || !accessToken || self.serviceTermsModalCoordinatorBridgePresenter.isPresenting)
    {
        return;
    }
    
    ServiceTermsModalCoordinatorBridgePresenter *serviceTermsModalCoordinatorBridgePresenter = [[ServiceTermsModalCoordinatorBridgePresenter alloc] initWithSession:mxSession
                                                                                                                                                            baseUrl:baseURL
                                                                                                                                                        serviceType:MXServiceTypeIdentityService
                                                                                                                                                       outOfContext:YES
                                                                                                                                                        accessToken:accessToken];
    
    serviceTermsModalCoordinatorBridgePresenter.delegate = self;
    
    [serviceTermsModalCoordinatorBridgePresenter presentFrom:self.presentedViewController animated:YES];
    self.serviceTermsModalCoordinatorBridgePresenter = serviceTermsModalCoordinatorBridgePresenter;
}

- (void)serviceTermsModalCoordinatorBridgePresenterDelegateDidAccept:(ServiceTermsModalCoordinatorBridgePresenter * _Nonnull)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        
    }];
    self.serviceTermsModalCoordinatorBridgePresenter = nil;
}

- (void)serviceTermsModalCoordinatorBridgePresenterDelegateDidDecline:(ServiceTermsModalCoordinatorBridgePresenter *)coordinatorBridgePresenter session:(MXSession *)session
{
    NSLog(@"[AppDelegate] IS Terms: User has declined the use of the default IS.");
    
    // The user does not want to use the proposed IS.
    // Disable IS feature on user's account
    [session setIdentityServer:nil andAccessToken:nil];
    [session setAccountDataIdentityServer:nil success:^{
    } failure:^(NSError *error) {
        NSLog(@"[AppDelegate] IS Terms: Error: %@", error);
    }];
    
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        
    }];
    self.serviceTermsModalCoordinatorBridgePresenter = nil;
}

- (void)serviceTermsModalCoordinatorBridgePresenterDelegateDidCancel:(ServiceTermsModalCoordinatorBridgePresenter * _Nonnull)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        
    }];
    self.serviceTermsModalCoordinatorBridgePresenter = nil;
}

#pragma mark - Settings

+ (void)setupUserDefaults
{
    // Register "Tchap-Defaults.plist" default values
    NSString* userDefaults = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UserDefaults"];
    NSString *defaultsPathFromApp = [[NSBundle mainBundle] pathForResource:userDefaults ofType:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:defaultsPathFromApp];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    if (!RiotSettings.shared.isUserDefaultsMigrated)
    {
        [RiotSettings.shared migrate];
    }
    
    // Now use RiotSettings and NSUserDefaults to store `showDecryptedContentInNotifications` setting option
    // Migrate this information from main MXKAccount to RiotSettings, if value is not in UserDefaults
    
    if (!RiotSettings.shared.isShowDecryptedContentInNotificationsHasBeenSetOnce)
    {
        MXKAccount *currentAccount = [MXKAccountManager sharedManager].activeAccounts.firstObject;
        RiotSettings.shared.showDecryptedContentInNotifications = currentAccount.showDecryptedContentInNotifications;
    }
}

@end
