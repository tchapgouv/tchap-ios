/*
 Copyright 2015 OpenMarket Ltd

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

<<<<<<< HEAD:Tchap/Modules/Room/Views/BubbleCells/Antivirus/Clear/RoomAttachmentAntivirusScanStatusBubbleCell.h
#import "RoomIncomingAttachmentBubbleCell.h"
=======
#import "RecentsViewController.h"
#import "RecentsDataSource.h"
>>>>>>> v1.9.0:Riot/Modules/Home/HomeViewController.h

/**
 `RoomAttachmentAntivirusScanStatusBubbleCell` displays room attachment antivirus scan status with sender's information.
 */
@interface RoomAttachmentAntivirusScanStatusBubbleCell : RoomIncomingAttachmentBubbleCell

+ (instancetype)instantiate;

@property (nonatomic, readonly) RecentsDataSourceMode recentsDataSourceMode;

@end
