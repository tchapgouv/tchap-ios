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
enum PasswordPolicyVerificationResult {
    case authorized
    case unauthorized(reason: PasswordPolicyRejectionReason)
}

/// Reasons of the password rejection
enum PasswordPolicyRejectionReason {
    case tooShort(minLength: Int)
    case noDigit
    case noSymbol
    case noUppercase
    case noLowercase
}


/// Protocol describing a service used to manage the password policy forced by the server.
protocol PasswordPolicyServiceType {
    
    /// Checks whether a given password complies with the current policy.
    ///
    /// - Parameters:
    /// - password: The password to check against the policy.
    /// - completion: A block object called when the operation completes.
    ///
    /// returns: a `MXHTTPOperation` instance.
    func verifyPassword(_ passwword: String, completion: @escaping (MXResponse<PasswordPolicyVerificationResult>) -> Void) -> MXHTTPOperation?
}
