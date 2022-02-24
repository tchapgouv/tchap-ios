/*
 Copyright 2014 OpenMarket Ltd
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

#import <UIKit/UIKit.h>
#import "MatrixKit.h"

#import "JitsiViewController.h"

#import "RageShakeManager.h"
#import "Analytics.h"

@protocol Configurable;
@protocol LegacyAppDelegateDelegate;
@class RoomNavigationParameters;

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
@interface LegacyAppDelegate : UIResponder <UIApplicationDelegate, MXKCallViewControllerDelegate, JitsiViewControllerDelegate>
{
    // background sync management
    void (^_completionHandler)(UIBackgroundFetchResult);
}

@property (weak, nonatomic) id<LegacyAppDelegateDelegate> delegate;

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UIAlertController *errorNotification;

@property (strong, nonatomic) NSString *appVersion;
@property (strong, nonatomic) NSString *build;

@property (nonatomic) BOOL isAppForeground;
@property (nonatomic) BOOL isOffline;

/**
 Last navigated room's identifier from a push notification.
 */
// TODO: This property is introduced to fix #3672. Remove it when a better solution revealed to the problem.
@property (nonatomic, copy) NSString *lastNavigatedRoomIdFromPush;

/**
 Let the AppDelegate handle and display self verification requests.
 Default is YES;
 */
@property (nonatomic) BOOL handleSelfVerificationRequest;

// Associated matrix sessions (empty by default).
@property (nonatomic, readonly) NSArray *mxSessions;

// Current selected room id. nil if no room is presently visible.
@property (strong, nonatomic) NSString *visibleRoomId;

// New message sound id.
@property (nonatomic, readonly) SystemSoundID messageSound;

// Build Settings
@property (nonatomic, readonly) id<Configurable> configuration;

// List here the server error codes which must be ignored by `[showErrorAsAlert:]`
@property (nonatomic) NSSet<NSString *> *ignoredServerErrorCodes;

+ (instancetype)theDelegate;

#pragma mark - Push Notifications

/**
 Perform registration for remote notifications.
 
 @param completion the block to be executed when registration finished.
 */
- (void)registerForRemoteNotificationsWithCompletion:(nullable void (^)(NSError *))completion;

#pragma mark - Badge Count

- (void)refreshApplicationIconBadgeNumber;

#pragma mark - Application layout handling

- (void)restoreInitialDisplay:(void (^)(void))completion;

- (UIAlertController*)showErrorAsAlert:(NSError*)error;
- (UIAlertController*)showAlertWithTitle:(NSString*)title message:(NSString*)message;

#pragma mark - Matrix Sessions handling

// Add a matrix session.
- (void)addMatrixSession:(MXSession*)mxSession;

// Remove a matrix session.
- (void)removeMatrixSession:(MXSession*)mxSession;

// Mark all messages as read in the running matrix sessions.
- (void)markAllMessagesAsRead;

// Remove delivred notifications for a given room id except call notifications
- (void)removeDeliveredNotificationsWithRoomId:(NSString*)roomId completion:(dispatch_block_t)completion;

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

 @param sendLogoutRequest Indicate whether send logout request to homeserver.
 @param completion the block to execute at the end of the operation.
 */
- (void)logoutSendingRequestServer:(BOOL)sendLogoutServerRequest
                        completion:(void (^)(BOOL isLoggedOut))completion;

/**
 Present incoming key verification request to accept.

 @param incomingKeyVerificationRequest The incoming key verification request.
 @param The matrix session.
 @return Indicate NO if the key verification screen could not be presented.
 */
- (BOOL)presentIncomingKeyVerificationRequest:(MXKeyVerificationRequest*)incomingKeyVerificationRequest
                                    inSession:(MXSession*)session;

//- (BOOL)presentUserVerificationForRoomMember:(MXRoomMember*)roomMember session:(MXSession*)mxSession;
//
//- (BOOL)presentCompleteSecurityForSession:(MXSession*)mxSession;

- (void)configureCallManagerIfRequiredForSession:(MXSession *)mxSession;

#pragma mark - Matrix Accounts handling

- (void)selectMatrixAccount:(void (^)(MXKAccount *selectedAccount))onSelection;

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

#pragma mark - Matrix Room handling

// Show a room and jump to the given event if event id is not nil otherwise go to last messages.
- (void)showRoomWithParameters:(RoomNavigationParameters*)parameters completion:(void (^)(void))completion;

- (void)showRoomWithParameters:(RoomNavigationParameters*)parameters;

// Restore display and show the room
- (void)showRoom:(NSString*)roomId andEventId:(NSString*)eventId withMatrixSession:(MXSession*)mxSession;

// Creates a new direct chat with the provided user id
- (void)createDirectChatWithUserId:(NSString*)userId completion:(void (^)(void))completion;

- (void)startDirectChatWithUserId:(NSString*)userId completion:(void (^)(void))completion;

#pragma mark - Call status handling

/**
 Call status window displayed when user goes back to app during a call.
 */
@property (nonatomic, readonly) UIWindow* callStatusBarWindow;
@property (nonatomic, readonly) UIButton* callStatusBarButton;

@end

@protocol LegacyAppDelegateDelegate <NSObject>

- (void)legacyAppDelegate:(LegacyAppDelegate*)legacyAppDelegate wantsToPopToHomeViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion;
- (void)legacyAppDelegateRestoreEmptyDetailsViewController:(LegacyAppDelegate*)legacyAppDelegate;

- (void)legacyAppDelegate:(LegacyAppDelegate*)legacyAppDelegate didAddMatrixSession:(MXSession*)session;

- (void)legacyAppDelegate:(LegacyAppDelegate*)legacyAppDelegate didRemoveMatrixSession:(MXSession*)session;

- (void)legacyAppDelegate:(LegacyAppDelegate*)legacyAppDelegate didAddAccount:(MXKAccount*)account;

- (void)legacyAppDelegate:(LegacyAppDelegate*)legacyAppDelegate didRemoveAccount:(MXKAccount*)account;

- (void)legacyAppDelegate:(LegacyAppDelegate*)legacyAppDelegate didNavigateToSpaceWithId:(NSString*)spaceId;

- (void)legacyAppDelegate:(LegacyAppDelegate*)legacyAppDelegate wantsToShowRoom:(NSString*)roomID completion:(void (^)(void))completion;

@end
