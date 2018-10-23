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

@import MatrixKit;

@protocol RoomViewControllerDelegate;
@class RoomPreviewData, User;

@interface RoomViewController : MXKRoomViewController

/**
 Preview data for a room invitation received by email, or a link to a room.
 */
@property (nonatomic, readonly, nullable) RoomPreviewData *roomPreviewData;

/**
 Tell whether a badge must be added next to the chevron (back button) showing number of unread rooms.
 YES by default.
 */
@property (nonatomic) BOOL showMissedDiscussionsBadge;

/**
 Tell whether input tool bar should be hidden in every case.
 NO by default.
 */
@property (nonatomic) BOOL forceHideInputToolBar;

/**
 The delegate for the view controller.
 */
@property (weak, nonatomic, nullable) id<RoomViewControllerDelegate> delegate;

/**
 Display the preview of a room that is unknown for the user.

 This room can come from an email invitation link or a simple link to a room.

 @param roomPreviewData the data for the room preview.
 */
- (void)displayRoomPreview:(nonnull RoomPreviewData*)roomPreviewData;

/**
 Display a new discussion with a target user without associated room.
 
 @param discussionTargetUser Direct chat target user.
 @param session The Matrix session.
 */
- (void)displayNewDiscussionWithTargetUser:(nonnull User*)discussionTargetUser session:(nonnull MXSession*)session;

/**
 Creates and returns a new `RoomViewController` object.
 
 @return An initialized `RoomViewController` object.
 */
+ (nonnull instancetype)instantiate;

/**
 Creates a new discussion with a target user without associated room and returns a new `RoomViewController` object.

 @param discussionTargetUser Direct chat target user.
 @param session The Matrix session.

 @return An initialized `RoomViewController` object.
 */
+ (nonnull instancetype)instantiateWithDiscussionTargetUser:(nonnull User*)discussionTargetUser session:(nonnull MXSession*)session;

@end


/**
 `RoomViewController` delegate.
 */
@protocol RoomViewControllerDelegate <NSObject>

/**
 Tells the delegate that the user wants to open the room details (members, files, settings).
 
 @param roomViewController the `RoomViewController` instance.
 */
- (void)roomViewControllerShowRoomDetails:(nonnull RoomViewController *)roomViewController;

/**
 Tells the delegate that the user wants to display the details of a room member.
 
 @param roomViewController the `RoomViewController` instance.
 @param roomMember the selected member
 */
- (void)roomViewController:(nonnull RoomViewController *)roomViewController showMemberDetails:(nonnull MXRoomMember *)roomMember;

/**
 Tells the delegate that the user wants to display another room.
 
 @param roomViewController the `RoomViewController` instance.
 @param roomID the selected roomId
 */
- (void)roomViewController:(nonnull RoomViewController *)roomViewController showRoom:(nonnull NSString *)roomID;

/**
 Tells the delegate that the user wants to join room from room preview.
 
 @param roomViewController the `RoomViewController` instance.
 */
- (void)roomViewControllerPreviewDidTapJoin:(nonnull RoomViewController *)roomViewController;

/**
 Tells the delegate that the user wants to cancel the room preview.
 
 @param roomViewController the `RoomViewController` instance.
 */
- (void)roomViewControllerPreviewDidTapCancel:(nonnull RoomViewController *)roomViewController;

@end
