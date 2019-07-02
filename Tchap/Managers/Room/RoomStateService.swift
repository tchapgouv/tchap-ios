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
    
    func getRoomAccessRule(_ roomID: String, completion: @escaping (MXResponse<RoomAccessRule>) -> Void) {
        // TODO
    }
    
    // MARK: - Private
}
