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
enum DiscussionFinderResult {
    case joinedDiscussion(roomID: String)
    case pendingInvite(roomID: String)
    case noDiscussion
}

/// Protocol describing a service used to find the direct chat which is the most suitable discussion with a Tchap user.
/// The aim is to handle only one discussion by Tchap user, and prevent the client from creating multiple one-one with the same user.
protocol DiscussionFinderType {
    
    /// Returns the identifier of the current discussion for a given user ID, if any.
    /// The returned discussion may be a pending invite from this user.
    ///
    /// - Parameters:
    ///   - userID: The user identifier to search for. This identifier is a matrix id or an email address.
    ///   - includeInvite: Tell whether the pending invitations have to be considered or not.
    ///   - autoJoin: When the current discussion is a pending invite, this boolean tells whether we must join it automatically before returning.
    ///   - completion: A closure called when the operation complete. Provide the discussion id (if any) when succeed.
    func getDiscussionIdentifier(for userID: String, includeInvite: Bool, autoJoin: Bool, completion: @escaping (MXResponse<DiscussionFinderResult>) -> Void)
}

// DiscussionFinderType default implementation
extension DiscussionFinderType {
    func getDiscussionIdentifier(for userID: String, completion: @escaping (MXResponse<DiscussionFinderResult>) -> Void) {
        return self.getDiscussionIdentifier(for: userID, includeInvite: true, autoJoin: true, completion: completion)
    }
}
