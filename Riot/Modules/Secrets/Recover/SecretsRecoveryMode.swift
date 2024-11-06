/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

@objc
enum SecretsRecoveryMode: Int {
    // Tchap : use only generated key as recovery mode
//    case passphraseOrKey
    case onlyKey
}
