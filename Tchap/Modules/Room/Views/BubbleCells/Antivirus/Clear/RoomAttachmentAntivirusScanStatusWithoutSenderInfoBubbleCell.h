/*
<<<<<<< HEAD:Tchap/Modules/Room/Views/BubbleCells/Antivirus/Clear/RoomAttachmentAntivirusScanStatusWithoutSenderInfoBubbleCell.h
 Copyright 2015 OpenMarket Ltd
=======
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
>>>>>>> v1.11.19:Riot/Modules/GlobalSearch/DataSources/UnifiedSearchRecentsDataSource.h

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomIncomingAttachmentWithoutSenderInfoBubbleCell.h"

/**
 `RoomAttachmentAntivirusScanStatusWithoutSenderInfoBubbleCell` displays room attachment antivirus scan status bubbles without sender's information.
 */
@interface RoomAttachmentAntivirusScanStatusWithoutSenderInfoBubbleCell : RoomIncomingAttachmentWithoutSenderInfoBubbleCell

+ (instancetype)instantiate;

@end
