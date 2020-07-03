/*
 Copyright 2018-2020 Vector Creations Ltd
 
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

#import <MatrixKit/MatrixKit.h>

/**
 List the different secure backup banners that could be displayed.
 */
typedef NS_ENUM(NSInteger, SecureBackupBannerDisplay)
{
    SecureBackupBannerDisplayNone,
    SecureBackupBannerDisplaySetup
};

/**
 List the different cross-signing banners that could be displayed.
 */
typedef NS_ENUM(NSInteger, CrossSigningBannerDisplay)
{
    CrossSigningBannerDisplayNone,
    CrossSigningBannerDisplaySetup
};

/**
 Action identifier used when the user tapped on the directory change button.
 
 The `userInfo` is nil.
 */
extern NSString *const kRoomsDataSourceTapOnDirectoryServerChange;

/**
 'RoomsDataSource' class inherits from 'MXKInterleavedRecentsDataSource' to define the Riot recents source
 shared between all the applications tabs.
 */
@interface RoomsDataSource : MXKInterleavedRecentsDataSource

@property (nonatomic) NSInteger crossSigningBannerSection;
@property (nonatomic) NSInteger secureBackupBannerSection;
@property (nonatomic) NSInteger invitesSection;
@property (nonatomic) NSInteger conversationSection;

@property (nonatomic, readonly) NSArray* invitesCellDataArray;
@property (nonatomic, readonly) NSArray* conversationCellDataArray;

@property (nonatomic, readonly) SecureBackupBannerDisplay secureBackupBannerDisplay;
@property (nonatomic, readonly) CrossSigningBannerDisplay crossSigningBannerDisplay;

/**
 Refresh the rooms data source and notify its delegate.
 */
- (void)forceRefresh;

/**
 Tell whether the sections are shrinkable. NO by default.
 */
@property (nonatomic) BOOL areSectionsShrinkable;

- (void)registerKeyBackupStateDidChangeNotification;
- (void)unregisterKeyBackupStateDidChangeNotification;

/**
 Get the sticky header view for the specified section.
 
 @param section the section  index
 @param frame the drawing area for the header of the specified section.
 @return the sticky header view.
 */
- (UIView *)viewForStickyHeaderInSection:(NSInteger)section withFrame:(CGRect)frame;

/**
 Get the height of the section header view.
 
 @param section the section  index
 @return the header height.
 */
- (CGFloat)heightForHeaderInSection:(NSInteger)section;

/**
 The current number of rooms with missed notifications, including the invites.
 */
@property (nonatomic, readonly) NSUInteger missedConversationsCount;

/**
 The current number of rooms with unread highlighted messages.
 */
@property (nonatomic, readonly) NSUInteger missedHighlightConversationsCount;

@end
