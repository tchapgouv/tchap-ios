// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objcMembers
class RoomDisplayConfiguration: NSObject {
    
// Tchap: handle call activation by homeServer
//    let callsEnabled: Bool
    private let _tchapCallsEnabled: Bool
    
    var callsEnabled: Bool {
        guard _tchapCallsEnabled,
              let account = MXKAccountManager.shared().activeAccounts.first
        else { return false }
        // Tchap: actually, only allow VoIP by homeServer.
        if (account.isFeatureActivated(BuildSettings.tchapFeatureVoiceOverIP) || account.isFeatureActivated(BuildSettings.tchapFeatureVideoOverIP)) {
            return true
        }
        else {
            return false
        }
    }
    
    let integrationsEnabled: Bool
    
    let jitsiWidgetRemoverEnabled: Bool

    let sendingPollsEnabled: Bool
    
    init(callsEnabled: Bool,
         integrationsEnabled: Bool,
         jitsiWidgetRemoverEnabled: Bool,
         sendingPollsEnabled: Bool) {
// Tchap: handle call activation by homeServer
//        self.callsEnabled = callsEnabled
        self._tchapCallsEnabled = callsEnabled
        self.integrationsEnabled = integrationsEnabled
        self.jitsiWidgetRemoverEnabled = jitsiWidgetRemoverEnabled
        self.sendingPollsEnabled = sendingPollsEnabled
        super.init()
    }
    
    static let `default`: RoomDisplayConfiguration = RoomDisplayConfiguration(callsEnabled: true,
                                                                              integrationsEnabled: true,
                                                                              jitsiWidgetRemoverEnabled: true,
                                                                              sendingPollsEnabled: true)
    
    static let forThreads: RoomDisplayConfiguration = RoomDisplayConfiguration(callsEnabled: false,
                                                                               integrationsEnabled: false,
                                                                               jitsiWidgetRemoverEnabled: false,
                                                                               sendingPollsEnabled: false)
}
