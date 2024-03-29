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
enum ThirdPartyIDResolveResult {
    case bound(userID: String)
    case unbound
}

/// Protocol describing a service used to discover Tchap users from third-party identifiers (for example: an email address).
protocol ThirdPartyIDResolverType {
    
    /// Retrieve user matrix ids from a list of 3rd party ids.
    /// This method has been added to interact with the existing Objective C source code.
    ///
    /// - Parameters:
    /// - threepids: the list of 3rd party ids
    /// - success: A block object called when the operation succeeded.
    /// - failure: A block object called when the operation failed.
    ///
    /// - returns: a `MXHTTPOperation` instance.
    func bulkLookup(threepids: [[String]],
                    success: @escaping (([[String]]) -> Void),
                    failure: @escaping ((Error) -> Void)) -> MXHTTPOperation?
}
