/*
 Copyright 2019-2020 New Vector Ltd
 
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

import Foundation

enum RoomCategory {
    case directChat
    case restrictedPrivateRoom
    case unrestrictedPrivateRoom
    case forum
    case serverNotice
    case unknown
}

@objc extension MXRoomSummary {
    
    // MARK: - Constants
    
    private enum Constants {
        static let isFederatedKey = "isFederated"
        static let roomAccessRuleKey = "roomAccessRule"
        static let isServerNotice = "isServerNotice"
    }
    
    func tc_isServerNotice() -> Bool {
        if let isServerNotice = self.others[Constants.isServerNotice] as? Bool {
            return isServerNotice
        }
        
        guard let tags = self.room?.accountData.tags else {
            return false
        }
        let isServerNotice = tags[kMXRoomTagServerNotice] != nil
        // In order to hide the Tchap Info room in the Share extension, we have to store this value in the summary.
        // Indeed the room is not available in the summary there.
        // We save this flag only when it is true (= server notice)
        if isServerNotice {
            self.others[Constants.isServerNotice] = isServerNotice
            self.save(true)
        }
        return isServerNotice
    }
    
    /// Called to update the room summary on received state events.
    /// Store in the summary some additional information required for Tchap.
    ///
    /// - Parameters:
    ///   - roomSummary: the current room summary.
    ///   - stateEvents: a set of state events .
    ///
    /// - returns: YES if the room summary has changed.
    func tc_update(stateEvents: [MXEvent]) -> Bool {
        var updated = false
        
        // Note: we ignore malformed event content
        for event in stateEvents {
            if let type = event.type {
                if type == MXEventType.roomCreate.identifier {
                    // Check whether the room is federated or not.
                    if let createContent = MXRoomCreateContent(fromJSON: event.content) {
                        self.others[Constants.isFederatedKey] = createContent.isFederated
                        updated = true
                    }
                } else if type == RoomService.roomAccessRulesStateEventType {
                    if let rule = event.content[RoomService.roomAccessRulesContentRuleKey] as? String {
                        self.others[Constants.roomAccessRuleKey] = rule
                        updated = true
                    }
                }
            }
        }
        
        return updated
    }
    
    /// Tell whether users on other servers can join this room.
    func tc_isFederated() -> Bool {
        // Note: a room is federated by default
        let isFederated = self.others[Constants.isFederatedKey] as? Bool ?? true
        return isFederated
    }
    
    /// Get the current room access rule of the room
    @nonobjc func tc_roomAccessRule() -> RoomAccessRule {
        if let rule = self.others[Constants.roomAccessRuleKey] as? String {
            return RoomAccessRule(identifier: rule)
        } else if self.isDirect {
            // TODO add the right state event to this discussion
            return .direct
        } else {
            // The room is considered as restricted by default
            return .restricted
        }
    }
    
    /// Get the room category
    @nonobjc func tc_roomCategory() -> RoomCategory {
        let isJoinRulePublic = self.joinRule == kMXRoomJoinRulePublic
        let category: RoomCategory
        
        if tc_isServerNotice() {
            category = .serverNotice
        } else if self.isEncrypted {
            switch self.tc_roomAccessRule() {
            case .direct: category = .directChat
            case .restricted: category = .restrictedPrivateRoom
            case .unrestricted: category = .unrestrictedPrivateRoom
            default: category = .unknown
            }
        } else if isJoinRulePublic && self.membership != .invite {
            // Tchap: we consider as forum all the unencrypted rooms with a public join_rule
            // We exclude invitation here because the full room state is not available (we don't know if encryption is enabled or not)
            category = .forum
        } else {
            category = .unknown
        }
        return category
    }
    
    /// Get the current room access rule of the room
    func tc_roomAccessRuleIdentifier() -> String {
        return tc_roomAccessRule().identifier
    }
    
    @objc func tc_isForum() -> Bool {
        return tc_roomCategory() == .forum
    }
}
