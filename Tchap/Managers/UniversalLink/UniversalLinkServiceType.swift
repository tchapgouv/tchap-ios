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

/// List the different supported links
enum UniversalLinkServiceParsingResult {
    /// The universal link corresponds to a pending registration.
    /// "params" is the set of the parameters required to pursue the registration.
    case registrationLink(params: [String: String])
    /// The universal link corresponds to a room link.
    /// The room is defined by its identifier or an alias.
    /// An optional event id in this room may have been retrieved too
    case roomLink(_ roomIdOrAlias: String, eventID: String?)
}

/// Protocol describing a service to handle universal links.
protocol UniversalLinkServiceType {
    
    /// Handle the webpage url of a user activity if any.
    ///
    /// - Parameters:
    ///   - userActivity: The user activity.
    ///   - completion: A closure called when the operation complete. Provide the parsing result when succeed.
    /// - Returns: true to indicate that a universal link has been handled, or false when the url is not supported (or no url has been found).
    func handleUserActivity(_ userActivity: NSUserActivity, completion: @escaping (MXResponse<UniversalLinkServiceParsingResult>) -> Void) -> Bool
    
    /// Handle an url fragment.
    ///
    /// - Parameters:
    ///   - fragment: The url fragment to handle.
    ///   - completion: A closure called when the operation complete. Provide the parsing result when succeed.
    /// - Returns: true to indicate that the fragment has been handled, or false when the fragment is not supported.
    func handleFragment(_ fragment: String, completion: @escaping (MXResponse<UniversalLinkServiceParsingResult>) -> Void) -> Bool
}
