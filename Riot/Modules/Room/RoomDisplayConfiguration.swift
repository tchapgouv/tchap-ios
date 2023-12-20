// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
        // Tchap: allow VoIP for Pre-prod and Dev version
        if ["fr.gouv.btchap", "fr.gouv.tchap.dev"].contains(BuildSettings.baseBundleIdentifier)
        {
            return true
        }
        // Tchap: actually, only allow VoIP for DINUM homeServer.
        let allowedHomeServersForCalls = [BuildSettings.serverUrlPrefix + "agent.dinum.tchap.gouv.fr"]
        let callsAreEnabled = allowedHomeServersForCalls.contains(account.identityServerURL)
        return callsAreEnabled
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
