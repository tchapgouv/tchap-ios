// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

// Configuration settings file format documentation can be found at:
// https://help.apple.com/xcode/#/dev745c5c974

class LocationWithoutSenderInfoPlainCell: LocationPlainCell {
    override func setupViews() {
        super.setupViews()
        
        roomCellContentView?.showSenderInfo = false
    }
}
