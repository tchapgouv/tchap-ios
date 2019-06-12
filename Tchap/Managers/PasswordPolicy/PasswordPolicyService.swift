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

/// `PasswordPolicyService` is used to apply a password policy.
final class PasswordPolicyService: PasswordPolicyServiceType {
    
    /// The current HttpClient
    private let policy: PasswordPolicyType
    
    // MARK: - Public
    init(policy: PasswordPolicyType) {
        self.policy = policy
    }
    
    func verify(_ password: String) -> PasswordPolicyVerificationResult {
        // Check first the password length
        if password.count < policy.minLength {
            return .unauthorized(reason: .tooShort(minLength: policy.minLength))
        }
        
        if policy.isDigitRequired, password.rangeOfCharacter(from: CharacterSet.decimalDigits) == nil {
            return .unauthorized(reason: .no_digit)
        }
        
        if policy.isSymbolRequired {
            let pwd = password.filter { !"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".contains($0) }
            if pwd.count == 0 {
                return .unauthorized(reason: .no_symbol)
            }
        }
        
        if policy.isUppercaseRequired, password.rangeOfCharacter(from: CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")) == nil {
            return .unauthorized(reason: .no_uppercase)
        }
        
        if policy.isLowercaseRequired, password.rangeOfCharacter(from: CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz")) == nil {
            return .unauthorized(reason: .no_lowercase)
        }
        
        return .authorized
    }
}
