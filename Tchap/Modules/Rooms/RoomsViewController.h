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

#import "RecentsViewController.h"

@protocol RoomsViewControllerDelegate;

/**
 The `RoomsViewController` screen is the view controller displayed when `Rooms` tab is selected.
 */
@interface RoomsViewController : RecentsViewController

/**
 The delegate for the view controller.
 */
@property (nonatomic, weak) id<RoomsViewControllerDelegate> roomsViewControllerDelegate;

/**
 Scroll the next room with missed notifications to the top.
 */
- (void)scrollToNextRoomWithMissedNotifications;

/**
 Creates and returns a new `RoomsViewController` object.
 
 @return An initialized `RoomsViewController` object.
 */
+ (instancetype)instantiate;

@end

@protocol RoomsViewControllerDelegate <NSObject>

- (void)roomsViewController:(RoomsViewController*)roomsViewController didSelectRoomWithID:(NSString*)roomID;
- (void)roomsViewController:(RoomsViewController*)roomsViewController didAcceptRoomInviteWithRoomID:(NSString*)roomID;
@end
