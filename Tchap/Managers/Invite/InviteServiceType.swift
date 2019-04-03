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

/// List the different result cases
enum InviteServiceResult {
    case inviteHasBeenSent(roomID: String)
    case inviteAlreadySent(roomID: String)
    case inviteIgnoredForDiscoveredUser(userID: String)
    case inviteIgnoredForUnauthorizedEmail
}

/// Protocol describing a service used to invite someone to join Tchap.
protocol InviteServiceType {
    
    /// Invite a contact by inviting him in a direct chat (if this is not already done).
    ///
    /// - Parameters:
    ///   - email: an email address.
    ///   - completion: A closure called when the operation complete. See InviteServiceResult values.
    func sendEmailInvite(to email: String, completion: @escaping (MXResponse<InviteServiceResult>) -> Void)
}
