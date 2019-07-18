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

#import "RoomSettingsViewController.h"

#import "TableViewCellWithLabelAndLargeTextView.h"

#import "SegmentedViewController.h"

#import "AvatarGenerator.h"
#import "Tools.h"

#import "MXRoom+Riot.h"
#import "MXRoomSummary+Riot.h"

#import "GeneratedInterface-Swift.h"

#import "RoomMemberDetailsViewController.h"

#import <MobileCoreServices/MobileCoreServices.h>

enum
{
    ROOM_SETTINGS_MAIN_SECTION_INDEX = 0,
    ROOM_SETTINGS_BANNED_USERS_SECTION_INDEX,
    ROOM_SETTINGS_SECTION_COUNT
};

enum
{
    ROOM_SETTINGS_MAIN_SECTION_ROW_PHOTO = 0,
    ROOM_SETTINGS_MAIN_SECTION_ROW_NAME,
    ROOM_SETTINGS_MAIN_SECTION_ROW_TOPIC,
    ROOM_SETTINGS_MAIN_SECTION_ROW_MUTE_NOTIFICATIONS,
    ROOM_SETTINGS_MAIN_SECTION_ROW_LEAVE,
    ROOM_SETTINGS_MAIN_SECTION_ROW_COUNT
};

#define ROOM_TOPIC_CELL_HEIGHT 124

#define SECTION_TITLE_PADDING_WHEN_HIDDEN 0.01f

NSString *const kRoomSettingsAvatarKey = @"kRoomSettingsAvatarKey";
NSString *const kRoomSettingsAvatarURLKey = @"kRoomSettingsAvatarURLKey";
NSString *const kRoomSettingsNameKey = @"kRoomSettingsNameKey";
NSString *const kRoomSettingsTopicKey = @"kRoomSettingsTopicKey";
NSString *const kRoomSettingsMuteNotifKey = @"kRoomSettingsMuteNotifKey";
NSString *const kRoomSettingsDirectoryKey = @"kRoomSettingsDirectoryKey";

NSString *const kRoomSettingsNameCellViewIdentifier = @"kRoomSettingsNameCellViewIdentifier";
NSString *const kRoomSettingsTopicCellViewIdentifier = @"kRoomSettingsTopicCellViewIdentifier";
NSString *const kRoomSettingsBannedUserCellViewIdentifier = @"kRoomSettingsBannedUserCellViewIdentifier";

@interface RoomSettingsViewController () <Stylable>
{
    // The updated user data
    NSMutableDictionary<NSString*, id> *updatedItemsDict;
    
    // The current table items
    UITextField* nameTextField;
    UITextView* topicTextView;
    
    // Rooms directory items
    NSInteger directoryVisibilityIndex;
    MXRoomDirectoryVisibility actualDirectoryVisibility;
    MXHTTPOperation* actualDirectoryVisibilityRequest;
    
    // Room Access items
    NSInteger roomAccessRuleIndex;
    
    // The potential image loader
    MXMediaLoader *uploader;
    
    // The pending http operation
    MXHTTPOperation* pendingOperation;
    
    // the updating spinner
    UIActivityIndicatorView* updatingSpinner;
    
    UIAlertController *currentAlert;
    
    // listen to more events than the mother class
    id extraEventsListener;
    
    // picker
    MediaPickerViewController* mediaPicker;
    
    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
    id appDelegateDidTapStatusBarNotificationObserver;
    
    // A copy of the banned members
    NSArray<MXRoomMember*> *bannedMembers;
    
    // Observe kRiotDesignValuesDidChangeThemeNotification to handle user interface theme change.
    id kRiotDesignValuesDidChangeThemeNotificationObserver;
}

@property (nonatomic, strong) id<Style> currentStyle;

@end

@implementation RoomSettingsViewController

+ (instancetype)instantiate
{
    RoomSettingsViewController *roomSettingsViewController = [RoomSettingsViewController roomSettingsViewController];
    roomSettingsViewController.currentStyle = Variant2Style.shared;
    return roomSettingsViewController;
}

- (void)finalizeInit
{
    [super finalizeInit];
    
    _selectedRoomSettingsField = RoomSettingsViewControllerFieldNone;
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
}

- (void)initWithSession:(MXSession *)session andRoomId:(NSString *)roomId
{
    [super initWithSession:session andRoomId:roomId];
    
    // Add an additional listener to update banned users
    self->extraEventsListener = [mxRoom listenToEventsOfTypes:@[kMXEventTypeStringRoomMember, RoomStateService.roomAccessRulesStateEventType] onEvent:^(MXEvent *event, MXTimelineDirection direction, MXRoomState *roomState) {

        if (direction == MXTimelineDirectionForwards)
        {
            [self updateRoomState:roomState];
        }
    }];
}

- (void)updateRoomState:(MXRoomState *)newRoomState
{
    [super updateRoomState:newRoomState];
    
    bannedMembers = [mxRoomState.members membersWithMembership:MXMembershipBan];
}

- (UINavigationItem*)getNavigationItem
{
    // Check whether the view controller is currently displayed inside a segmented view controller or not.
    UIViewController* topViewController = ((self.parentViewController) ? self.parentViewController : self);
    
    return topViewController.navigationItem;
}

- (void)setNavBarButtons
{
    [self getNavigationItem].rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onSave:)];
    [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
    [self getNavigationItem].leftBarButtonItem  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancel:)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    updatedItemsDict = [[NSMutableDictionary alloc] init];
    
    [self.tableView registerClass:MXKTableViewCellWithLabelAndSwitch.class forCellReuseIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier]];
    [self.tableView registerClass:MXKTableViewCellWithLabelAndMXKImageView.class forCellReuseIdentifier:[MXKTableViewCellWithLabelAndMXKImageView defaultReuseIdentifier]];
    
    // Use a specific cell identifier for the room name, the topic and the address in order to be able to keep reference
    // on the text input field without being disturbed by the cell dequeuing process.
    [self.tableView registerClass:MXKTableViewCellWithLabelAndTextField.class forCellReuseIdentifier:kRoomSettingsNameCellViewIdentifier];
    [self.tableView registerClass:TableViewCellWithLabelAndLargeTextView.class forCellReuseIdentifier:kRoomSettingsTopicCellViewIdentifier];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:kRoomSettingsBannedUserCellViewIdentifier];
    
    [self.tableView registerClass:MXKTableViewCellWithButton.class forCellReuseIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
    [self.tableView registerClass:MXKTableViewCell.class forCellReuseIdentifier:[MXKTableViewCell defaultReuseIdentifier]];
    
    // Enable self sizing cells
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 44;
    
    [self setNavBarButtons];
    
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Screen tracking
    [[Analytics sharedInstance] trackScreen:@"RoomSettings"];
    
    // Release the potential media picker
    [self dismissMediaPicker];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateRules:) name:kMXNotificationCenterDidUpdateRules object:nil];
    
    // Observe appDelegateDidTapStatusBarNotificationObserver.
    appDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self.tableView setContentOffset:CGPointMake(-self.tableView.mxk_adjustedContentInset.left, -self.tableView.mxk_adjustedContentInset.top) animated:YES];
        
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Edit the selected field if any
    if (_selectedRoomSettingsField != RoomSettingsViewControllerFieldNone)
    {
        self.selectedRoomSettingsField = _selectedRoomSettingsField;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self dismissFirstResponder];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXNotificationCenterDidUpdateRules object:nil];
    
    if (appDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:appDelegateDidTapStatusBarNotificationObserver];
        appDelegateDidTapStatusBarNotificationObserver = nil;
    }
}

// Those methods are called when the viewcontroller is added or removed from a container view controller.
- (void)willMoveToParentViewController:(nullable UIViewController *)parent
{
    // Check whether the view is removed from its parent.
    if (!parent)
    {
        [self dismissFirstResponder];
        
        // Prompt user to save changes (if any).
        if (updatedItemsDict.count)
        {
            [self promptUserToSaveChanges];
        }
    }
    
    [super willMoveToParentViewController:parent];
}
- (void)didMoveToParentViewController:(nullable UIViewController *)parent
{
    [super didMoveToParentViewController:parent];
    
    [self setNavBarButtons];
}

- (void)destroy
{
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    if (uploader)
    {
        [uploader cancel];
        uploader = nil;
    }
    
    if (pendingOperation)
    {
        [pendingOperation cancel];
        pendingOperation = nil;
    }
    
    if (actualDirectoryVisibilityRequest)
    {
        [actualDirectoryVisibilityRequest cancel];
        actualDirectoryVisibilityRequest = nil;
    }
    
    if (kRiotDesignValuesDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kRiotDesignValuesDidChangeThemeNotificationObserver];
        kRiotDesignValuesDidChangeThemeNotificationObserver = nil;
    }
    
    if (appDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:appDelegateDidTapStatusBarNotificationObserver];
        appDelegateDidTapStatusBarNotificationObserver = nil;
    }
    
    updatedItemsDict = nil;
    
    if (extraEventsListener)
    {
        MXWeakify(self);
        [mxRoom liveTimeline:^(MXEventTimeline *liveTimeline) {
            MXStrongifyAndReturnIfNil(self);

            [liveTimeline removeListener:self->extraEventsListener];
            self->extraEventsListener = nil;
        }];
    }
    
    [super destroy];
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

- (void)refreshRoomSettings
{
    [self retrieveActualDirectoryVisibility];
    
    // Check whether a text input is currently edited
    BOOL isNameEdited = nameTextField ? nameTextField.isFirstResponder : NO;
    BOOL isTopicEdited = topicTextView ? topicTextView.isFirstResponder : NO;
    
    // Trigger a full table reloadData
    [super refreshRoomSettings];
    
    // Restore the previous edited field
    if (isNameEdited)
    {
        [self editRoomName];
    }
    else if (isTopicEdited)
    {
        [self editRoomTopic];
    }
}

#pragma mark -

- (void)setSelectedRoomSettingsField:(RoomSettingsViewControllerField)selectedRoomSettingsField
{
    // Check whether the view controller is already embedded inside a navigation controller
    if (self.navigationController)
    {
        [self dismissFirstResponder];
        
        // Check whether user allowed to change room info
        NSDictionary *eventTypes = @{
                                     @(RoomSettingsViewControllerFieldName): kMXEventTypeStringRoomName,
                                     @(RoomSettingsViewControllerFieldTopic): kMXEventTypeStringRoomTopic,
                                     @(RoomSettingsViewControllerFieldAvatar): kMXEventTypeStringRoomAvatar
                                     };
        
        NSString *eventTypeForSelectedField = eventTypes[@(selectedRoomSettingsField)];
        
        if (!eventTypeForSelectedField)
            return;
        
        MXRoomPowerLevels *powerLevels = [mxRoomState powerLevels];
        NSInteger oneSelfPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mainSession.myUser.userId];
        
        if (oneSelfPowerLevel < [powerLevels minimumPowerLevelForSendingEventAsStateEvent:eventTypeForSelectedField])
            return;
        
        switch (selectedRoomSettingsField)
        {
            case RoomSettingsViewControllerFieldName:
            {
                [self editRoomName];
                break;
            }
            case RoomSettingsViewControllerFieldTopic:
            {
                [self editRoomTopic];
                break;
            }
            case RoomSettingsViewControllerFieldAvatar:
            {
                [self onRoomAvatarTap:nil];
                break;
            }
                
            default:
                break;
        }
    }
    else
    {
        // This selection will be applied when the view controller will become active (see 'viewDidAppear')
        _selectedRoomSettingsField = selectedRoomSettingsField;
    }
}

#pragma mark - private

- (void)editRoomName
{
    if (![nameTextField becomeFirstResponder])
    {
        // Retry asynchronously
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self editRoomName];
            
        });
    }
}

- (void)editRoomTopic
{
    if (![topicTextView becomeFirstResponder])
    {
        // Retry asynchronously
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self editRoomTopic];
            
        });
    }
}

- (void)dismissFirstResponder
{
    if ([topicTextView isFirstResponder])
    {
        [topicTextView resignFirstResponder];
    }
    
    if ([nameTextField isFirstResponder])
    {
        [nameTextField resignFirstResponder];
    }
    
    _selectedRoomSettingsField = RoomSettingsViewControllerFieldNone;
}

- (void)startActivityIndicator
{
    // Lock user interaction
    self.tableView.userInteractionEnabled = NO;
    
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
    // Check local conditions before stop the activity indicator
    if (!pendingOperation && !uploader)
    {
        // Unlock user interaction
        self.tableView.userInteractionEnabled = YES;
        
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
}

- (void)promptUserToSaveChanges
{
    // ensure that the user understands that the updates will be lost if
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    __weak typeof(self) weakSelf = self;
    
    currentAlert = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedStringFromTable(@"room_details_save_changes_prompt", @"Vector", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"no"]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                           
                                                           [self->updatedItemsDict removeAllObjects];
                                                           
                                                           [self withdrawViewControllerAnimated:YES completion:nil];
                                                       }
                                                       
                                                   }]];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"yes"]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                           
                                                           [self onSave:nil];
                                                       }
                                                       
                                                   }]];
    
    [currentAlert mxk_setAccessibilityIdentifier:@"RoomSettingsVCSaveChangesAlert"];
    [self presentViewController:currentAlert animated:YES completion:nil];
}

- (void)retrieveActualDirectoryVisibility
{
    if (!mxRoom || actualDirectoryVisibilityRequest)
    {
        return;
    }
    
    // Trigger a new request to check the actual directory visibility
    MXWeakify(self);
    actualDirectoryVisibilityRequest = [mxRoom directoryVisibility:^(MXRoomDirectoryVisibility directoryVisibility) {
        
        MXStrongifyAndReturnIfNil(self);
        self->actualDirectoryVisibilityRequest = nil;
        
        // Return when the visibility is already known
        if ([self->actualDirectoryVisibility isEqualToString:directoryVisibility]) {
            return;
        }
        
        self->actualDirectoryVisibility = directoryVisibility;
        
        // Check a potential user's change before the end of the request
        MXRoomDirectoryVisibility modifiedDirectoryVisibility = [self->updatedItemsDict objectForKey:kRoomSettingsDirectoryKey];
        if (modifiedDirectoryVisibility)
        {
            if ([modifiedDirectoryVisibility isEqualToString:directoryVisibility])
            {
                // The requested change corresponds to the actual settings
                [self->updatedItemsDict removeObjectForKey:kRoomSettingsDirectoryKey];
                
                [self getNavigationItem].rightBarButtonItem.enabled = (self->updatedItemsDict.count != 0);
            }
        }
        
        // Force a refresh
        [self refreshRoomSettings];
        
    } failure:^(NSError *error) {
        
        NSLog(@"[RoomSettingsViewController] request to get directory visibility failed");
        MXStrongifyAndReturnIfNil(self);
        self->actualDirectoryVisibilityRequest = nil;
        
    }];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView;
{
    if (topicTextView == textView)
    {
        UIView *contentView = topicTextView.superview;
        if (contentView)
        {
            // refresh cell's layout
            [contentView.superview setNeedsLayout];
        }
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (topicTextView == textView)
    {
        UIView *contentView = topicTextView.superview;
        if (contentView)
        {
            // refresh cell's layout
            [contentView.superview setNeedsLayout];
        }
    }
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (topicTextView == textView)
    {
        NSString* currentTopic = mxRoomState.topic;
        
        // Remove white space from both ends
        NSString* topic = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        // Check whether the topic has been actually changed
        if ((topic || currentTopic) && ([topic isEqualToString:currentTopic] == NO))
        {
            [updatedItemsDict setObject:(topic ? topic : @"") forKey:kRoomSettingsTopicKey];
        }
        else
        {
            [updatedItemsDict removeObjectForKey:kRoomSettingsTopicKey];
        }
        
        [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField == nameTextField)
    {
        nameTextField.textAlignment = NSTextAlignmentLeft;
    }
}
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == nameTextField)
    {
        nameTextField.textAlignment = NSTextAlignmentRight;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == nameTextField)
    {
        // Dismiss the keyboard
        [nameTextField resignFirstResponder];
    }
    
    return YES;
}

#pragma mark - actions

- (IBAction)onTextFieldUpdate:(UITextField*)textField
{
    if (textField == nameTextField)
    {
        NSString *currentName = mxRoomState.name;
        
        // Remove white space from both ends
        NSString *displayName = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        // Check whether the name has been actually changed
        if ((displayName || currentName) && ([displayName isEqualToString:currentName] == NO))
        {
            [updatedItemsDict setObject:(displayName ? displayName : @"") forKey:kRoomSettingsNameKey];
        }
        else
        {
            [updatedItemsDict removeObjectForKey:kRoomSettingsNameKey];
        }
        
        [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
    }
}

- (void)didUpdateRules:(NSNotification *)notif
{
    [self refreshRoomSettings];
}

- (IBAction)onCancel:(id)sender
{
    [self dismissFirstResponder];
    
    // Check whether some changes have been done
    if (updatedItemsDict.count)
    {
        [self promptUserToSaveChanges];
    }
    else
    {
        [self withdrawViewControllerAnimated:YES completion:nil];
    }
}

- (void)onSaveFailed:(NSString*)message withKeys:(NSArray<NSString *>*)keys
{
    __weak typeof(self) weakSelf = self;
    
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    currentAlert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                           
                                                           // Discard related change
                                                           for (NSString *key in keys)
                                                           {
                                                               [self->updatedItemsDict removeObjectForKey:key];
                                                           }
                                                           
                                                           // Save anything else
                                                           [self onSave:nil];
                                                       }
                                                       
                                                   }]];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"retry", @"Vector", nil)
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                           
                                                           [self onSave:nil];
                                                       }
                                                       
                                                   }]];
    
    [currentAlert mxk_setAccessibilityIdentifier:@"RoomSettingsVCSaveChangesFailedAlert"];
    [self presentViewController:currentAlert animated:YES completion:nil];
}

- (IBAction)onSave:(id)sender
{
    if (updatedItemsDict.count)
    {
        [self startActivityIndicator];
        
        MXWeakify(self);
        
        // check if there is some updates related to room state
        if (mxRoomState)
        {
            if ([updatedItemsDict objectForKey:kRoomSettingsAvatarKey])
            {
                // Retrieve the current picture and make sure its orientation is up
                UIImage *updatedPicture = [MXKTools forceImageOrientationUp:[updatedItemsDict objectForKey:kRoomSettingsAvatarKey]];
                
                // Upload picture
                uploader = [MXMediaManager prepareUploaderWithMatrixSession:mxRoom.mxSession initialRange:0 andRange:1.0];
                
                [uploader uploadData:UIImageJPEGRepresentation(updatedPicture, 0.5) filename:nil mimeType:@"image/jpeg" success:^(NSString *url) {
                    
                    MXStrongifyAndReturnIfNil(self);
                    self->uploader = nil;
                    
                    [self->updatedItemsDict removeObjectForKey:kRoomSettingsAvatarKey];
                    [self->updatedItemsDict setObject:url forKey:kRoomSettingsAvatarURLKey];
                    
                    [self onSave:nil];
                    
                } failure:^(NSError *error) {
                    
                    NSLog(@"[RoomSettingsViewController] Image upload failed");
                    MXStrongifyAndReturnIfNil(self);
                    self->uploader = nil;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        NSString* message = error.localizedDescription;
                        if (!message.length)
                        {
                            message = NSLocalizedStringFromTable(@"room_details_fail_to_update_avatar", @"Vector", nil);
                        }
                        [self onSaveFailed:message withKeys:@[kRoomSettingsAvatarKey]];
                        
                    });
                    
                }];
                
                return;
            }
            
            NSString* photoUrl = [updatedItemsDict objectForKey:kRoomSettingsAvatarURLKey];
            if (photoUrl)
            {
                pendingOperation = [mxRoom setAvatar:photoUrl success:^{
                    
                    MXStrongifyAndReturnIfNil(self);
                    self->pendingOperation = nil;
                    [self->updatedItemsDict removeObjectForKey:kRoomSettingsAvatarURLKey];
                    [self onSave:nil];
                    
                } failure:^(NSError *error) {
                    
                    NSLog(@"[RoomSettingsViewController] Failed to update the room avatar");
                    MXStrongifyAndReturnIfNil(self);
                    self->pendingOperation = nil;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        NSString* message = error.localizedDescription;
                        if (!message.length)
                        {
                            message = NSLocalizedStringFromTable(@"room_details_fail_to_update_avatar", @"Vector", nil);
                        }
                        [self onSaveFailed:message withKeys:@[kRoomSettingsAvatarURLKey]];
                        
                    });
                    
                }];
                
                return;
            }
            
            // has a new room name
            NSString* roomName = [updatedItemsDict objectForKey:kRoomSettingsNameKey];
            if (roomName)
            {
                pendingOperation = [mxRoom setName:roomName success:^{
                    
                    MXStrongifyAndReturnIfNil(self);
                    self->pendingOperation = nil;
                    [self->updatedItemsDict removeObjectForKey:kRoomSettingsNameKey];
                    [self onSave:nil];
                    
                } failure:^(NSError *error) {
                    
                    NSLog(@"[RoomSettingsViewController] Rename room failed");
                    MXStrongifyAndReturnIfNil(self);
                    self->pendingOperation = nil;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        NSString* message = error.localizedDescription;
                        if (!message.length)
                        {
                            message = NSLocalizedStringFromTable(@"room_details_fail_to_update_room_name", @"Vector", nil);
                        }
                        [self onSaveFailed:message withKeys:@[kRoomSettingsNameKey]];
                        
                    });
                    
                }];
                
                return;
            }
            
            // has a new room topic
            NSString* roomTopic = [updatedItemsDict objectForKey:kRoomSettingsTopicKey];
            if (roomTopic)
            {
                pendingOperation = [mxRoom setTopic:roomTopic success:^{
                    
                    MXStrongifyAndReturnIfNil(self);
                    self->pendingOperation = nil;
                    [self->updatedItemsDict removeObjectForKey:kRoomSettingsTopicKey];
                    [self onSave:nil];
                    
                } failure:^(NSError *error) {
                    
                    NSLog(@"[RoomSettingsViewController] Rename topic failed");
                    MXStrongifyAndReturnIfNil(self);
                    self->pendingOperation = nil;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        NSString* message = error.localizedDescription;
                        if (!message.length)
                        {
                            message = NSLocalizedStringFromTable(@"room_details_fail_to_update_topic", @"Vector", nil);
                        }
                        [self onSaveFailed:message withKeys:@[kRoomSettingsTopicKey]];
                        
                    });
                    
                }];
                
                return;
            }
        }
        
        if ([updatedItemsDict objectForKey:kRoomSettingsMuteNotifKey])
        {
            if (((NSNumber*)[updatedItemsDict objectForKey:kRoomSettingsMuteNotifKey]).boolValue)
            {
                [mxRoom mentionsOnly:^{
                    
                    MXStrongifyAndReturnIfNil(self);
                    [self->updatedItemsDict removeObjectForKey:kRoomSettingsMuteNotifKey];
                    [self onSave:nil];
                    
                }];
            }
            else
            {
                [mxRoom allMessages:^{
                    
                    MXStrongifyAndReturnIfNil(self);
                    [self->updatedItemsDict removeObjectForKey:kRoomSettingsMuteNotifKey];
                    [self onSave:nil];
                    
                }];
            }
            return;
        }
    }
    
    [self getNavigationItem].rightBarButtonItem.enabled = NO;
    
    [self stopActivityIndicator];
    
    [self withdrawViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the fixed number of sections
    return ROOM_SETTINGS_SECTION_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    if (section == ROOM_SETTINGS_MAIN_SECTION_INDEX)
    {
        count = ROOM_SETTINGS_MAIN_SECTION_ROW_COUNT;
        
        directoryVisibilityIndex = -1;
        // Add a toggle when the room is listed in the rooms directory (public rooms) to let the user remove it from this list.
        // Check whether the room visibility is known, and if the room is public
        if ([actualDirectoryVisibility isEqualToString:kMXRoomDirectoryVisibilityPublic])
        {
            // Check user's power level to know whether the user may remove this room from the rooms directory.
            MXRoomPowerLevels *powerLevels = [mxRoomState powerLevels];
            NSInteger oneSelfPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mainSession.myUser.userId];
            if (oneSelfPowerLevel >= RoomPowerLevelAdmin)
            {
                directoryVisibilityIndex = count++;
            }
        }
        
        roomAccessRuleIndex = count++;
    }
    else if (section == ROOM_SETTINGS_BANNED_USERS_SECTION_INDEX)
    {
        count = bannedMembers.count;
    }
    
    return count;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == ROOM_SETTINGS_BANNED_USERS_SECTION_INDEX)
    {
        if (bannedMembers.count)
        {
            return NSLocalizedStringFromTable(@"room_details_banned_users_section", @"Vector", nil);
        }
        // Hide this section
        return nil;
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == ROOM_SETTINGS_BANNED_USERS_SECTION_INDEX && bannedMembers.count == 0)
    {
        // Hide this section
        return SECTION_TITLE_PADDING_WHEN_HIDDEN;
    }
    else
    {
        return [super tableView:tableView heightForHeaderInSection:section];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == ROOM_SETTINGS_BANNED_USERS_SECTION_INDEX && bannedMembers.count == 0)
    {
        // Hide this section
        return SECTION_TITLE_PADDING_WHEN_HIDDEN;
    }
    else
    {
        return [super tableView:tableView heightForFooterInSection:section];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == ROOM_SETTINGS_MAIN_SECTION_INDEX)
    {
        if (indexPath.row == ROOM_SETTINGS_MAIN_SECTION_ROW_TOPIC)
        {
            return ROOM_TOPIC_CELL_HEIGHT;
        }
    }
    
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    UITableViewCell* cell;
    
    // Check user's power level to know which settings are editable.
    MXRoomPowerLevels *powerLevels = [mxRoomState powerLevels];
    NSInteger oneSelfPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mainSession.myUser.userId];
    
    // general settings
    if (indexPath.section == ROOM_SETTINGS_MAIN_SECTION_INDEX)
    {
        if (row == ROOM_SETTINGS_MAIN_SECTION_ROW_MUTE_NOTIFICATIONS)
        {
            MXKTableViewCellWithLabelAndSwitch *roomNotifCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];

            [roomNotifCell.mxkSwitch addTarget:self action:@selector(toggleRoomNotification:) forControlEvents:UIControlEventValueChanged];
            
            roomNotifCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_details_mute_notifs", @"Vector", nil);
            
            if ([updatedItemsDict objectForKey:kRoomSettingsMuteNotifKey])
            {
                roomNotifCell.mxkSwitch.on = ((NSNumber*)[updatedItemsDict objectForKey:kRoomSettingsMuteNotifKey]).boolValue;
            }
            else
            {
                roomNotifCell.mxkSwitch.on = mxRoom.isMute || mxRoom.isMentionsOnly;
            }
            
            cell = roomNotifCell;
        }
        else if (row == ROOM_SETTINGS_MAIN_SECTION_ROW_PHOTO)
        {
            MXKTableViewCellWithLabelAndMXKImageView *roomPhotoCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndMXKImageView defaultReuseIdentifier] forIndexPath:indexPath];
            
            roomPhotoCell.mxkLabelLeadingConstraint.constant = roomPhotoCell.separatorInset.left;
            roomPhotoCell.mxkImageViewTrailingConstraint.constant = 10;
            
            roomPhotoCell.mxkImageViewWidthConstraint.constant = roomPhotoCell.mxkImageViewHeightConstraint.constant = 30;
            
            roomPhotoCell.mxkImageViewDisplayBoxType = MXKTableViewCellDisplayBoxTypeCircle;
            
            // Handle tap on avatar to update it
            if (!roomPhotoCell.mxkImageView.gestureRecognizers.count)
            {
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onRoomAvatarTap:)];
                [roomPhotoCell.mxkImageView addGestureRecognizer:tap];
            }
            
            roomPhotoCell.mxkImageView.defaultBackgroundColor = [UIColor clearColor];
            
            roomPhotoCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_details_photo", @"Vector", nil);
            roomPhotoCell.mxkLabel.textColor = self.currentStyle.primaryTextColor;
            
            if ([updatedItemsDict objectForKey:kRoomSettingsAvatarKey])
            {
                roomPhotoCell.mxkImageView.image = (UIImage*)[updatedItemsDict objectForKey:kRoomSettingsAvatarKey];
            }
            else
            {
                [mxRoom.summary setRoomAvatarImageIn:roomPhotoCell.mxkImageView];
                
                roomPhotoCell.userInteractionEnabled = (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomAvatar]);
                roomPhotoCell.mxkImageView.alpha = roomPhotoCell.userInteractionEnabled ? 1.0f : 0.5f;
            }
            
            cell = roomPhotoCell;
        }
        else if (row == ROOM_SETTINGS_MAIN_SECTION_ROW_TOPIC)
        {
            TableViewCellWithLabelAndLargeTextView *roomTopicCell = [tableView dequeueReusableCellWithIdentifier:kRoomSettingsTopicCellViewIdentifier forIndexPath:indexPath];
            
            roomTopicCell.labelLeadingConstraint.constant = roomTopicCell.separatorInset.left;
            
            roomTopicCell.label.text = NSLocalizedStringFromTable(@"room_details_topic", @"Vector", nil);
            
            topicTextView = roomTopicCell.textView;
            
            if ([updatedItemsDict objectForKey:kRoomSettingsTopicKey])
            {
                topicTextView.text = (NSString*)[updatedItemsDict objectForKey:kRoomSettingsTopicKey];
            }
            else
            {
                topicTextView.text = mxRoomState.topic;
            }
            
            topicTextView.tintColor = self.currentStyle.secondaryTextColor;
            topicTextView.font = [UIFont systemFontOfSize:15];
            topicTextView.bounces = NO;
            topicTextView.delegate = self;
            
            // disable the edition if the user cannot update it
            topicTextView.editable = (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomTopic]);
            topicTextView.textColor = self.currentStyle.secondaryTextColor;
            
            topicTextView.keyboardAppearance = kRiotKeyboard;
            
            cell = roomTopicCell;
        }
        else if (row == ROOM_SETTINGS_MAIN_SECTION_ROW_NAME)
        {
            MXKTableViewCellWithLabelAndTextField *roomNameCell = [tableView dequeueReusableCellWithIdentifier:kRoomSettingsNameCellViewIdentifier forIndexPath:indexPath];
            
            roomNameCell.mxkLabelLeadingConstraint.constant = roomNameCell.separatorInset.left;
            roomNameCell.mxkTextFieldLeadingConstraint.constant = 16;
            roomNameCell.mxkTextFieldTrailingConstraint.constant = 15;
            
            roomNameCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_details_room_name", @"Vector", nil);
            roomNameCell.mxkLabel.textColor = self.currentStyle.primaryTextColor;
            
            roomNameCell.accessoryType = UITableViewCellAccessoryNone;
            roomNameCell.accessoryView = nil;
            
            nameTextField = roomNameCell.mxkTextField;
            
            nameTextField.tintColor = self.currentStyle.secondaryTextColor;
            nameTextField.font = [UIFont systemFontOfSize:17];
            nameTextField.borderStyle = UITextBorderStyleNone;
            nameTextField.textAlignment = NSTextAlignmentRight;
            nameTextField.delegate = self;
            
            if ([updatedItemsDict objectForKey:kRoomSettingsNameKey])
            {
                nameTextField.text = (NSString*)[updatedItemsDict objectForKey:kRoomSettingsNameKey];
            }
            else
            {
                nameTextField.text = mxRoomState.name;
            }
            
            // disable the edition if the user cannot update it
            nameTextField.userInteractionEnabled = (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomName]);
            nameTextField.textColor = self.currentStyle.secondaryTextColor;
            
            // Add a "textFieldDidChange" notification method to the text field control.
            [nameTextField addTarget:self action:@selector(onTextFieldUpdate:) forControlEvents:UIControlEventEditingChanged];
            
            cell = roomNameCell;
        }
        else if (row == ROOM_SETTINGS_MAIN_SECTION_ROW_LEAVE)
        {
            MXKTableViewCellWithButton *leaveCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier] forIndexPath:indexPath];
            
            NSString* title = NSLocalizedStringFromTable(@"leave", @"Vector", nil);
            
            [leaveCell.mxkButton setTitle:title forState:UIControlStateNormal];
            [leaveCell.mxkButton setTitle:title forState:UIControlStateHighlighted];
            [leaveCell.mxkButton setTintColor:self.currentStyle.buttonPlainTitleColor];
            leaveCell.mxkButton.titleLabel.font = [UIFont systemFontOfSize:17];
            
            [leaveCell.mxkButton  removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [leaveCell.mxkButton addTarget:self action:@selector(onLeave:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = leaveCell;
        }
        else if (indexPath.row == directoryVisibilityIndex)
        {
            MXKTableViewCellWithLabelAndSwitch *removeFromDirectoryCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
            
            removeFromDirectoryCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_settings_remove_from_rooms_directory", @"Tchap", nil);
            removeFromDirectoryCell.mxkSwitch.on = NO;
            [removeFromDirectoryCell.mxkSwitch addTarget:self action:@selector(toggleRemoveFromDirectory:) forControlEvents:UIControlEventValueChanged];
            
            cell = removeFromDirectoryCell;
        }
        else if (indexPath.row == roomAccessRuleIndex)
        {
            // Retrieve the current room access rule
            NSString *roomAccessRule = [mxRoom.summary tc_roomAccessRuleIdentifier];
            
            // Check whether the current user is room admin
            BOOL isAdmin = (oneSelfPowerLevel >= RoomPowerLevelAdmin);
            
            // The room admin is able to open a "private room" to the external users
            // (We name "private rooms" those which require an invite to be joined)
            if ([roomAccessRule isEqualToString:RoomStateService.roomAccessRuleRestricted]
                && isAdmin
                && [mxRoomState.joinRule isEqualToString:kMXRoomJoinRuleInvite]) {
                MXKTableViewCellWithLabelAndSwitch *allowExternalMembersCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
                
                allowExternalMembersCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_settings_allow_external_users_to_join", @"Tchap", nil);
                allowExternalMembersCell.mxkSwitch.on = NO;
                [allowExternalMembersCell.mxkSwitch addTarget:self action:@selector(toggleRoomAccessRule:) forControlEvents:UIControlEventValueChanged];
                
                cell = allowExternalMembersCell;
            }
            else
            {
                MXKTableViewCell *roomAccessInfo = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCell defaultReuseIdentifier] forIndexPath:indexPath];
                
                NSString *title = NSLocalizedStringFromTable(@"room_settings_room_access_title", @"Tchap", nil);
                // Display a summary according to the room access rule value
                NSString *summary = roomAccessRule ? NSLocalizedStringFromTable(@"room_settings_room_access_restricted", @"Tchap", nil) : @"";
                if ([roomAccessRule isEqualToString:RoomStateService.roomAccessRuleUnrestricted]) {
                    summary = NSLocalizedStringFromTable(@"room_settings_room_access_unrestricted", @"Tchap", nil);
                }
                NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString: title
                                                                                                   attributes:@{NSForegroundColorAttributeName : self.currentStyle.primaryTextColor,
                                                                                                                NSFontAttributeName: [UIFont systemFontOfSize:17.0]}];
                [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:4]}]];
                [attributedText appendAttributedString:[[NSMutableAttributedString alloc] initWithString: summary
                                                                                              attributes:@{NSForegroundColorAttributeName : self.currentStyle.secondaryTextColor,
                                                                                                           NSFontAttributeName: [UIFont systemFontOfSize:14.0]}]];
                
                roomAccessInfo.textLabel.numberOfLines = 0;
                roomAccessInfo.textLabel.attributedText = attributedText;
                roomAccessInfo.selectionStyle = UITableViewCellSelectionStyleNone;
                
                cell = roomAccessInfo;
            }
        }
    }
    else if (indexPath.section == ROOM_SETTINGS_BANNED_USERS_SECTION_INDEX)
    {
        UITableViewCell *addressCell = [tableView dequeueReusableCellWithIdentifier:kRoomSettingsBannedUserCellViewIdentifier forIndexPath:indexPath];
        
        addressCell.textLabel.font = [UIFont systemFontOfSize:16];
        addressCell.textLabel.textColor = self.currentStyle.primaryTextColor;
        addressCell.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        addressCell.accessoryView = nil;
        addressCell.accessoryType = UITableViewCellAccessoryNone;
        addressCell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        addressCell.textLabel.text = bannedMembers[indexPath.row].userId;
        
        cell = addressCell;
    }
    
    // Sanity check
    if (!cell)
    {
        NSLog(@"[RoomSettingsViewController] cellForRowAtIndexPath: invalid indexPath");
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    // iOS8 requires this method to enable editing (see editActionsForRowAtIndexPath).
}

- (MXKTableViewCellWithLabelAndSwitch*)getLabelAndSwitchCell:(UITableView*)tableview forIndexPath:(NSIndexPath *)indexPath
{
    MXKTableViewCellWithLabelAndSwitch *cell = [tableview dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier] forIndexPath:indexPath];
    
    cell.mxkLabelLeadingConstraint.constant = cell.separatorInset.left;
    cell.mxkSwitchTrailingConstraint.constant = 15;
    
    cell.mxkLabel.textColor = self.currentStyle.primaryTextColor;
    
    cell.mxkSwitch.onTintColor = self.currentStyle.buttonBorderedBackgroundColor;
    [cell.mxkSwitch removeTarget:self action:nil forControlEvents:UIControlEventValueChanged];
    
    // Force layout before reusing a cell (fix switch displayed outside the screen)
    [cell layoutIfNeeded];
    
    return cell;
}

#pragma mark - UITableViewDelegate

//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
//{
//    cell.backgroundColor = self.currentStyle.backgroundColor;
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView == tableView)
    {
        [self dismissFirstResponder];
        
        if (indexPath.section == ROOM_SETTINGS_MAIN_SECTION_INDEX)
        {
            if (indexPath.row == ROOM_SETTINGS_MAIN_SECTION_ROW_PHOTO)
            {
                [self onRoomAvatarTap:nil];
            }
            else if (indexPath.row == ROOM_SETTINGS_MAIN_SECTION_ROW_TOPIC)
            {
                if (topicTextView.editable)
                {
                    [self editRoomTopic];
                }
            }
        }
        else if (indexPath.section == ROOM_SETTINGS_BANNED_USERS_SECTION_INDEX)
        {
            // Show the RoomMemberDetailsViewController on this member so that
            // if the user has enough power level, he will be able to unban him
            RoomMemberDetailsViewController *roomMemberDetailsViewController = [RoomMemberDetailsViewController instantiate];
            [roomMemberDetailsViewController displayRoomMember:bannedMembers[indexPath.row] withMatrixRoom:mxRoom];
            roomMemberDetailsViewController.enableVoipCall = NO;
            
            [self.parentViewController.navigationController pushViewController:roomMemberDetailsViewController animated:NO];
        }
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
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
    
    if (imageData)
    {
        UIImage *image = [UIImage imageWithData:imageData];
        if (image)
        {
            [self getNavigationItem].rightBarButtonItem.enabled = YES;
            
            [updatedItemsDict setObject:image forKey:kRoomSettingsAvatarKey];
            
            [self refreshRoomSettings];
        }
    }
}

- (void)mediaPickerController:(MediaPickerViewController *)mediaPickerController didSelectVideo:(NSURL*)videoURL
{
    // this method should not be called
    [self dismissMediaPicker];
}

#pragma mark - actions

- (void)onLeave:(id)sender
{
    // Prompt user before leaving the room
    __weak typeof(self) weakSelf = self;
    
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    
    currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"room_participants_leave_prompt_title", @"Vector", nil)
                                                       message:NSLocalizedStringFromTable(@"room_participants_leave_prompt_msg", @"Vector", nil)
                                                preferredStyle:UIAlertControllerStyleAlert];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                       }
                                                       
                                                   }]];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"leave", @"Vector", nil)
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                           
                                                           [self startActivityIndicator];
                                                           [self->mxRoom leave:^{
                                                               
                                                               [self withdrawViewControllerAnimated:YES completion:nil];
                                                               
                                                           } failure:^(NSError *error) {
                                                               
                                                               [self stopActivityIndicator];
                                                               
                                                               NSLog(@"[RoomSettingsViewController] Leave room failed");
                                                               // Alert user
                                                               [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                               
                                                           }];
                                                       }
                                                       
                                                   }]];
    
    [currentAlert mxk_setAccessibilityIdentifier:@"RoomSettingsVCLeaveAlert"];
    [self presentViewController:currentAlert animated:YES completion:nil];
}

- (void)onRoomAvatarTap:(UITapGestureRecognizer *)recognizer
{
    mediaPicker = [MediaPickerViewController mediaPickerViewController];
    mediaPicker.mediaTypes = @[(NSString *)kUTTypeImage];
    mediaPicker.delegate = self;
    UINavigationController *navigationController = [UINavigationController new];
    [navigationController pushViewController:mediaPicker animated:NO];
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)toggleRoomNotification:(UISwitch*)theSwitch
{
    if (theSwitch.on == (mxRoom.isMute || mxRoom.isMentionsOnly))
    {
        [updatedItemsDict removeObjectForKey:kRoomSettingsMuteNotifKey];
    }
    else
    {
        [updatedItemsDict setObject:[NSNumber numberWithBool:theSwitch.on] forKey:kRoomSettingsMuteNotifKey];
    }
    
    [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
}

- (void)toggleRemoveFromDirectory:(UISwitch*)theSwitch
{
    // Prompt the user before removing the room from the rooms directory
    MXWeakify(self);
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"warning", @"Vector", nil)
                                                       message:NSLocalizedStringFromTable(@"room_settings_remove_from_rooms_directory_prompt", @"Tchap", nil)
                                                preferredStyle:UIAlertControllerStyleAlert];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"yes"]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       MXStrongifyAndReturnIfNil(self);
                                                       self->currentAlert = nil;
                                                       [self removeFromRoomsDirectory];
                                                       
                                                   }]];
    
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       MXStrongifyAndReturnIfNil(self);
                                                       self->currentAlert = nil;
                                                       // Reset the switch change
                                                       theSwitch.on = NO;
                                                       
                                                   }]];
    
    [currentAlert mxk_setAccessibilityIdentifier:@"RoomSettingsVCRoomDirectoryAlert"];
    [self presentViewController:currentAlert animated:YES completion:nil];
}

- (void)removeFromRoomsDirectory
{
    [self startActivityIndicator];
    MXWeakify(self);
    
    void (^failure)(NSError *error) = ^(NSError *error){
        
        NSLog(@"[RoomSettingsViewController] Update room directory visibility failed");
        MXStrongifyAndReturnIfNil(self);
        self->pendingOperation = nil;
        [self stopActivityIndicator];
        // Alert user
        [[AppDelegate theDelegate] showErrorAsAlert:error];
        [self refreshRoomSettings];
        
    };
    
    // Set the joinRule to INVITE if this is not already the case
    if (![mxRoomState.joinRule isEqualToString:kMXRoomJoinRuleInvite])
    {
        NSLog(@"[RoomSettingsViewController] Update join rule for a public room");
        pendingOperation = [mxRoom setJoinRule:kMXRoomJoinRuleInvite success:^{
            
            MXStrongifyAndReturnIfNil(self);
            self->pendingOperation = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                // Pursue the operation
                [self removeFromRoomsDirectory];
                
            });
            
        } failure:^(NSError *error) {
            
            NSLog(@"[RoomSettingsViewController] Update join rule for a public room failed");
            failure(error);
            
        }];
    }
    else if (!self->mxRoom.summary.isEncrypted)
    {
        // Turn on the encryption if it is not already enabled
        NSLog(@"[RoomSettingsViewController] Enable encrytion");
        self->pendingOperation = [self->mxRoom enableEncryptionWithAlgorithm:kMXCryptoMegolmAlgorithm success:^{
            
            MXStrongifyAndReturnIfNil(self);
            self->pendingOperation = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                // Pursue the operation
                [self removeFromRoomsDirectory];
                
            });
            
        } failure:^(NSError *error) {
            
            NSLog(@"[RoomSettingsViewController] Enabling encrytion failed. Error: %@", error);
            failure(error);
            
        }];
    }
    else
    {
        // Remove the room from the rooms directory
        self->pendingOperation = [self->mxRoom setDirectoryVisibility:kMXRoomDirectoryVisibilityPrivate success:^{
            
            MXStrongifyAndReturnIfNil(self);
            self->pendingOperation = nil;
            [self stopActivityIndicator];
            [self refreshRoomSettings];
            
        } failure:failure];
    }
}

- (void)toggleRoomAccessRule:(UISwitch*)theSwitch
{
    // Prompt the user before opening the room to the external users
    MXWeakify(self);
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"warning", @"Vector", nil)
                                                       message:NSLocalizedStringFromTable(@"room_settings_allow_external_users_to_join_prompt_msg", @"Tchap", nil)
                                                preferredStyle:UIAlertControllerStyleAlert];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"yes"]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       MXStrongifyAndReturnIfNil(self);
                                                       self->currentAlert = nil;
                                                       [self allowExternalsToJoin];
                                                       
                                                   }]];
    
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       MXStrongifyAndReturnIfNil(self);
                                                       self->currentAlert = nil;
                                                       // Reset the switch change
                                                       theSwitch.on = NO;
                                                       
                                                   }]];
    
    [currentAlert mxk_setAccessibilityIdentifier:@"RoomSettingsVCRoomAccessAlert"];
    [self presentViewController:currentAlert animated:YES completion:nil];
}

- (void)allowExternalsToJoin
{
    [self startActivityIndicator];
    MXWeakify(self);
    
    pendingOperation = [self->mxRoom sendStateEventOfType:RoomStateService.roomAccessRulesStateEventType
                                                  content:@{
                                                            RoomStateService.roomAccessRulesContentRuleKey:
                                                                RoomStateService.roomAccessRuleUnrestricted
                                                            }
                                                 stateKey:@""
                                                  success:^(NSString *eventId) {
                                                      
                                                      MXStrongifyAndReturnIfNil(self);
                                                      self->pendingOperation = nil;
                                                      [self stopActivityIndicator];
                                                      [self refreshRoomSettings];
                                                      
                                                  }
                                                  failure:^(NSError *error){
                                                      
                                                      NSLog(@"[RoomSettingsViewController] Update room access rule failed");
                                                      MXStrongifyAndReturnIfNil(self);
                                                      self->pendingOperation = nil;
                                                      [self stopActivityIndicator];
                                                      // Alert user
                                                      [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                      [self refreshRoomSettings];
                                                      
                                                  }];
}

@end


