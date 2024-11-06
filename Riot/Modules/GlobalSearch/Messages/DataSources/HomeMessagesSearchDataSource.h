/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

/**
 `HomeMessagesSearchDataSource` overrides `MXKSearchDataSource` to render search results
 by using the same bubble cell as the chat history `RoomViewController`.
 */
@interface HomeMessagesSearchDataSource : MXKSearchDataSource

@end
