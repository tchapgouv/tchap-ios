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

/// Protocol describing a service to handle authentication.
protocol AuthenticationServiceType {
    
    /// Authenticate user on homeserver based on user mail.
    ///
    /// - Parameters:
    ///   - mail: The user mail.
    ///   - password: The user password.
    ///   - completion: A closure called when the operation is completed. Provide the authenticated user id when succeed.
    func authenticate(with mail: String, password: String, completion: @escaping (MXResponse<String>) -> Void)
}
