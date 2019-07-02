/*
 Copyright 2018 New Vector Ltd
 
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

import UIKit
import RxSwift

/// Protocol describing a service to perform room operations.
protocol RoomServiceType {
    
    /// Create a room.
    ///
    /// - Parameters:
    ///   - visibility: Room visibility, public or private.
    ///   - name: Room name.
    ///   - avatarURL: Room avatar MXC URL.
    ///   - inviteUserIds: The array of Matrix user ids to invite.
    ///   - isFederated: Tell whether a public room can be joined from the other federated servers.
    ///   - roomAccessRule: Tell whether the external users are allowed to join this room or not.
    ///   - completion: A closure called when the operation completes. Provide the room id when succeed.
    /// - Returns: A Single of MXCreateRoomResponse.
    func createRoom(visibility: MXRoomDirectoryVisibility, name: String, avatarURL: String?, inviteUserIds: [String], isFederated: Bool, accessRule: RoomAccessRule) -> Single<String>
    
    /// Create a direct chat by inviting a third party identifier.
    ///
    /// - Parameters:
    ///   - thirdPartyID: the third party identifier to invite.
    ///   - completion: A closure called when the operation complete. Provide the discussion id when succeed.
    func createDiscussionWithThirdPartyID(_ thirdPartyID: MXInvite3PID, completion: @escaping (MXResponse<String>) -> Void) -> MXHTTPOperation
}
