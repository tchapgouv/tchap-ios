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

enum RoomStateServiceError: Error {
    case unknownRoom
}

final class RoomStateService: RoomStateServiceType {
    
    // MARK: - Constants
    
    private enum Constants {
        static let roomAccessRulesStateEventType: String = "im.vector.room.access_rules"
    }
    
    // MARK: - Properties
    
    private let session: MXSession
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
    }
    
    // MARK: - Public
    
    func historyVisibilityStateEvent(with historyVisibility: MXRoomHistoryVisibility) -> MXEvent {
        
        let stateEventJSON: [AnyHashable: Any] = [
            "state_key": "",
            "type": MXEventType.roomHistoryVisibility.identifier,
            "content": [
                "history_visibility": historyVisibility.identifier
            ]
        ]
        
        guard let stateEvent = MXEvent(fromJSON: stateEventJSON) else {
            fatalError("[RoomStateService] history event could not be created")
        }
        return stateEvent
    }
    
    func roomAccessRulesStateEvent(with accessRule: RoomAccessRule) -> MXEvent {
        
        let stateEventJSON: [AnyHashable: Any] = [
            "state_key": "",
            "type": Constants.roomAccessRulesStateEventType,
            "content": [
                "rule": accessRule.identifier
            ]
        ]
        
        guard let stateEvent = MXEvent(fromJSON: stateEventJSON) else {
            fatalError("[RoomStateService] access rule event could not be created")
        }
        return stateEvent
    }
    
    func getRoomAccessRule(for roomID: String, completion: @escaping (MXResponse<RoomAccessRule>) -> Void) {
        guard let room = self.session.room(withRoomId: roomID) else {
            completion(.failure(RoomStateServiceError.unknownRoom))
            return
        }
        
        room.state { (roomState) in
            guard let roomState = roomState else {
                completion(.failure(RoomStateServiceError.unknownRoom))
                return
            }
            
            if let accessRule = self.roomAccessRule(from: roomState) {
                completion(.success(accessRule))
            } else if room.isDirect {
                // TODO add the right state event to this discussion
                completion(.success(.direct))
            } else {
                // The room is considered as restricted by default
                completion(.success(.restricted))
            }
        }
    }
    
    func getRoomAccessRule(for roomID: String) -> RoomAccessRule? {
        guard let room = self.session.room(withRoomId: roomID) else {
            return nil
        }
        
        if let roomState = room.dangerousSyncState {
            if let accessRule = self.roomAccessRule(from: roomState) {
                return accessRule
            } else if room.isDirect {
                // TODO add the right state event to this discussion
                return .direct
            } else {
                // The room is considered as restricted by default
                return .restricted
            }
        } else {
            return nil
        }
    }
    
    // MARK: - Private
    
    private func roomAccessRule(from roomState: MXRoomState) -> RoomAccessRule? {
        guard let roomAccessRulesEvents = roomState.stateEvents(with: .custom(Constants.roomAccessRulesStateEventType)),
            var accessRuleStateEvent = roomAccessRulesEvents.last else {
                return nil
        }
        
        // Consider the most recent state event if multiple events exist
        for event in roomAccessRulesEvents where accessRuleStateEvent.originServerTs < event.originServerTs {
            accessRuleStateEvent = event
        }
        return self.roomAccessRule(from: accessRuleStateEvent)
    }
    
    private func roomAccessRule(from event: MXEvent) -> RoomAccessRule? {
        guard let content = event.content, let rule = content["rule"] as? String else {
            return nil
        }
        
        return RoomAccessRule(identifier: rule)
    }
}
