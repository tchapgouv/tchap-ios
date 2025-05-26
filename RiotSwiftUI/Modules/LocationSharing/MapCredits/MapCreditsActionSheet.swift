//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct MapCreditsActionSheet {
    // Open URL action
    let openURL: (URL) -> Void
    
    // Map credits action sheet
    var sheet: ActionSheet {
        ActionSheet(title: Text(VectorL10n.locationSharingMapCreditsTitle),
                    buttons: [
                        .default(Text("© Etalab")) {
                            openURL(URL(string: "https://www.etalab.gouv.fr/")!)
                        },
                        .default(Text("© OpenMapTiles")) {
                            openURL(URL(string: "https://www.openmaptiles.org/")!)
                        },
                        .default(Text("© OpenStreetMap")) {
                            openURL(URL(string: "https://www.openstreetmap.org/copyright/")!)
                        },
                        .cancel()
                    ])
    }
}
