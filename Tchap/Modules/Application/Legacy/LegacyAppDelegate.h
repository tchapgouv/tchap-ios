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

#import <UIKit/UIKit.h>
#import <MatrixKit/MatrixKit.h>
#import <PushKit/PushKit.h>

#import "JitsiViewController.h"

#import "RageShakeManager.h"
#import "Analytics.h"

#import "DesignValues.h"

#pragma mark - Notifications
/**
 Posted when the user taps the clock status bar.
 */
extern NSString *const kAppDelegateDidTapStatusBarNotification;

/**
 Posted when the property 'isOffline' has changed. This property is related to the network reachability status.
 */
extern NSString *const kAppDelegateNetworkStatusDidChangeNotification;

/**
 Posted when user logout request complete with success.
 */
extern NSString *const kLegacyAppDelegateDidLogoutNotification;

/**
 Posted when user login request complete with success.
 */
extern NSString *const kLegacyAppDelegateDidLoginNotification;

/**
 LegacyAppDelegate is based on Riot AppDelegate, is here to keep some Riot behaviors and be decoupled in the future.
 */
@interface LegacyAppDelegate : UIResponder <UIApplicationDelegate, MXKCallViewControllerDelegate, UINavigationControllerDelegate, JitsiViewControllerDelegate, PKPushRegistryDelegate>
{
    BOOL isPushRegistered;
    
    // background sync management
    void (^_completionHandler)(UIBackgroundFetchResult);
}

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UIAlertController *errorNotification;

@property (strong, nonatomic) NSString *appVersion;
@property (strong, nonatomic) NSString *build;

@property (nonatomic) BOOL isAppForeground;
@property (nonatomic) BOOL isOffline;

// Associated matrix sessions (empty by default).
@property (nonatomic, readonly) NSArray *mxSessions;

// Current selected room id. nil if no room is presently visible.
@property (strong, nonatomic) NSString *visibleRoomId;

// New message sound id.
@property (nonatomic, readonly) SystemSoundID messageSound;

+ (instancetype)theDelegate;

#pragma mark - Application layout handling

- (UIAlertController*)showErrorAsAlert:(NSError*)error;

#pragma mark - Matrix Sessions handling

// Add a matrix session.
- (void)addMatrixSession:(MXSession*)mxSession;

// Remove a matrix session.
- (void)removeMatrixSession:(MXSession*)mxSession;

// Mark all messages as read in the running matrix sessions.
- (void)markAllMessagesAsRead;

/**
 Log out all the accounts after asking for a potential confirmation.
 Show the authentication screen on successful logout.
 
 @param askConfirmation tell whether a confirmation is required before logging out.
 @param completion the block to execute at the end of the operation.
 */
- (void)logoutWithConfirmation:(BOOL)askConfirmation completion:(void (^)(BOOL isLoggedOut))completion;

/**
 Log out all the accounts without confirmation.
 Show the authentication screen on successful logout.
 
 @param sendLogoutRequest Indicate whether send logout request to home server.
 @param completion the block to execute at the end of the operation.
 */
- (void)logoutSendingRequestServer:(BOOL)sendLogoutServerRequest
                        completion:(void (^)(BOOL isLoggedOut))completion;


#pragma mark - Matrix Accounts handling

- (void)selectMatrixAccount:(void (^)(MXKAccount *selectedAccount))onSelection;

#pragma mark - Push notifications

- (void)registerUserNotificationSettings;

/**
 Perform registration for remote notifications.
 
 @param completion the block to be executed when registration finished.
 */
- (void)registerForRemoteNotificationsWithCompletion:(void (^)(NSError *))completion;

#pragma mark - Jitsi call

/**
 Open the Jitsi view controller from a widget.
 
 @param jitsiWidget the jitsi widget.
 @param video to indicate voice or video call.
 */
- (void)displayJitsiViewControllerWithWidget:(Widget*)jitsiWidget andVideo:(BOOL)video;

/**
 The current Jitsi view controller being displayed.
 */
@property (nonatomic, readonly) JitsiViewController *jitsiViewController;

#pragma mark - Call status handling

/**
 Call status window displayed when user goes back to app during a call.
 */
@property (nonatomic, readonly) UIWindow* callStatusBarWindow;
@property (nonatomic, readonly) UIButton* callStatusBarButton;

@end

