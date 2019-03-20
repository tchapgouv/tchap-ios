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

import Foundation

/// Protocol describing a service to handle Tchap users.
protocol UserServiceType {
    
    /// Try to find an MXUser from local session with Matrix user id and build a Tchap user.
    ///
    /// - Parameter userId: The Matrix user id.
    /// - Returns: A Tchap User or nil if user is not found in local session.
    func getUserFromLocalSession(with userId: String) -> User?
    
    /// Try to find an MXUser from session or remote search with Matrix user id and build a Tchap user.
    ///
    /// - Parameters:
    ///   - userId: The Matrix user id.
    ///   - completion: A closure called when the operation completes. Provide the Tchap user or nil if not found.
    func findUser(with userId: String, completion: @escaping ((User?) -> Void))
    
    /// Build a temporary User by parsing Matrix user id.
    ///
    /// - Parameter userId: The Matrix user id to parse
    /// - Returns: A Tchap User.
    func buildTemporaryUser(from userId: String) -> User
    
    /// Check if two users are on the same domain.
    ///
    /// - Parameters:
    ///   - firstUserId: First Matrix ID
    ///   - secondUserId: Second Matrix ID
    /// - Returns: true if the two Matrix IDs belong to the same domain.
    func isUserId(_ firstUserId: String, belongToSameDomainAs secondUserId: String) -> Bool
    
    /// Check whether the account associated to the provided userId has been deactivated.
    ///
    /// - Parameters:
    ///   - userId: The Matrix user id.
    ///   - completion: A closure called when the operation completes. Provide the answer or an error.
    func isAccountDeactivated(for userId: String, completion: @escaping ((MXResponse<Bool>) -> Void))
    
    /// Tells whether the provided Matrix identifier corresponds to an external Tchap user.
    /// Note: invalid identifier will be considered as external.
    ///
    /// - Parameters:
    ///   - userId: The Matrix user id.
    /// - Returns: true if the user is external.
    func isExternalUser(_ userId: String) -> Bool
}
