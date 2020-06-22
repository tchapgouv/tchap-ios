/*
 Copyright 2016 OpenMarket Ltd
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

#import <MatrixKit/MatrixKit.h>

#import "DeviceTableViewCell.h"

@interface RoomMemberDetailsViewController : MXKRoomMemberDetailsViewController <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIView *roomMemberAvatarHeaderBackground;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *roomMemberAvatarHeaderBackgroundHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *memberHeaderView;
@property (weak, nonatomic) IBOutlet UIView *roomMemberAvatarMask;
@property (weak, nonatomic) IBOutlet UIImageView *memberBadge;

@property (weak, nonatomic) IBOutlet UILabel *roomMemberStatusLabel;

/**
 Creates and returns a new `RoomMemberDetailsViewController` object.
 
 @return An initialized `RoomMemberDetailsViewController` object.
 */
+ (instancetype)instantiate;

@end
