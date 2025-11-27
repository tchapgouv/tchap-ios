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

@objc extension MXRoom {
    
    /// Check whether the current user is\ the last administrator of the room.
    ///
    /// - Parameters:
    /// - success: A block object called when the operation succeeded.
    /// Provide a boolean telling whether the current user is the last admin.
    func tc_isCurrentUserLastAdministrator(_ completion: @escaping ((Bool) -> Void)) {
        self.state { roomState in
            guard let roomState, let currentUserId = self.mxSession.myUser.userId else {
                completion(false)
                return
            }
            
            let currentUserPowerLevel = roomState.powerLevelOfUser(withUserID: currentUserId)
            let isLastAdmin: Bool
            if currentUserPowerLevel >= RoomPowerLevel.admin.rawValue {
                let adminMembers = roomState.members.joinedMembers.filter({ roomState.powerLevelOfUser(withUserID: $0.userId) >= RoomPowerLevel.admin.rawValue })
                isLastAdmin = adminMembers.count == 1
            } else {
                isLastAdmin = false
            }
            
            completion(isLastAdmin)
        }
    }
}
