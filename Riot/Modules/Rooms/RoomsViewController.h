/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RecentsViewController.h"
@protocol RoomsViewControllerDelegate;

/**
 The `RoomsViewController` screen is the view controller displayed when `Rooms` tab is selected.
 */
@interface RoomsViewController : RecentsViewController

@property (nonatomic, weak) id<RoomsViewControllerDelegate> roomsViewDelegate;

+ (instancetype)instantiate;

/**
 Scroll the next room with missed notifications to the top.
 */
- (void)scrollToNextRoomWithMissedNotifications;


@end
