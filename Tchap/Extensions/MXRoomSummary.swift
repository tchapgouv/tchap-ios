/*
 Copyright 2019 New Vector Ltd
 
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

@objc extension MXRoomSummary {
    
    // MARK: - Constants
    
    private enum Constants {
        static let isFederatedKey = "isFederated"
        static let roomAccessRuleKey = "roomAccessRule"
        static let roomRetentionInDaysKey = "roomRetentionInDays"
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
                } else if type == RoomService.roomRetentionStateEventType {
                    if let maxLifetime = event.content[RoomService.roomRetentionContentMaxLifetimeKey] as? UInt64 {
                        self.others[Constants.roomRetentionInDaysKey] = Tools.numberOfDaysFromDuration(inMs: maxLifetime)
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
            return RoomAccessRule.direct
        } else {
            // The room is considered as restricted by default
            return RoomAccessRule.restricted
        }
    }
    
    /// Get the current room access rule of the room
    func tc_roomAccessRuleIdentifier() -> String {
        return tc_roomAccessRule().identifier
    }
    
    /// Get the room messages retention period in days
    func tc_roomRetentionPeriodInDays() -> uint {
        if let period = self.others[Constants.roomRetentionInDaysKey] as? uint {
            return period
        } else {
            return 365
        }
    }
}
