/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

extension MXRecoveryService {
    
    var vc_availability: SecretsRecoveryAvailability {
        guard self.hasRecovery() else {
            return .notAvailable
        }
        // Tchap : use only generated key as recovery mode
//        let secretsRecoveryMode: SecretsRecoveryMode = self.usePassphrase() ? .passphraseOrKey : .onlyKey
        let secretsRecoveryMode: SecretsRecoveryMode = .onlyKey

        return .available(secretsRecoveryMode)
    }
}
