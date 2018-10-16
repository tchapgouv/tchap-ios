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
    
    /// Build a User by parsing Matrix user id.
    ///
    /// - Parameter userId: The Matrix user id to parse
    /// - Returns: A Tchap User.
    func buildUser(from userId: String) -> User
    
    /// Try to find an MXUser from session or remote search with Matrix user id and build a Tchap user. Otherwise build a User by parsing Matrix user id if no MXUser is found.
    ///
    /// - Parameters:
    ///   - userId: The Matrix user id.
    ///   - completion: A closure called when the operation completes. Provide the Tchap user.
    func findOrBuildUser(from userId: String, completion: @escaping ((User) -> Void))
}
