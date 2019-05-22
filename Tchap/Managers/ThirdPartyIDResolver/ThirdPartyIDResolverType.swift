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

/// Protocol describing a service used to discover Tchap users from third-party identifiers (for example: an email address).
protocol ThirdPartyIDResolverType {
    
    /// Retrieve a user matrix id from a 3rd party id.
    ///
    /// - Parameters:
    /// - address the id of the user in the 3rd party system.
    /// - medium the 3rd party system (ex: "email").
    /// - identityServer: the url of the identity server to proxy the request to if the homeserver is allowed to do so
    /// - completion: A block object called when the operation completes.
    /// - response: Provides the Matrix user id (or `nil` if the user is not found) on success.
    
    /// returns: a `MXHTTPOperation` instance.
    func lookup(address: String, medium: MX3PID.Medium, identityServer: String, completion: @escaping (MXResponse<String?>) -> Void) -> MXHTTPOperation?
    
    /// Retrieve user matrix ids from a list of 3rd party ids.
    ///
    /// - Parameters:
    /// - threepids: the list of 3rd party ids
    /// - identityServer: the url of the identity server to proxy the request to if the homeserver is allowed to do so
    /// - completion: A block object called when the operation completes.
    /// - response: Provides the user ID for each MX3PID submitted.
    ///
    /// - returns: a `MXHTTPOperation` instance.
    func bulkLookup(threepids: [(MX3PID.Medium, String)], identityServer: String, completion: @escaping (MXResponse<[(MX3PID.Medium, String, String)]?>) -> Void) -> MXHTTPOperation?
}
