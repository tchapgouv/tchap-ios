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

enum PasswordPolicyServiceError: Error {
    case unknown
}

/// `PasswordPolicyService` is used to apply the server's policy.
final class PasswordPolicyService: PasswordPolicyServiceType {
    
    /// The current HttpClient
    private let httpClient: MXHTTPClient
    
    private var passwordPolicy: PasswordPolicyType?
    
    // MARK: - Public
    init(homeServer: String) {
        self.httpClient = MXHTTPClient(baseURL: "\(homeServer)/\(kMXAPIPrefixPathUnstable)", accessToken: nil, andOnUnrecognizedCertificateBlock: nil)
    }
    
    func verifyPassword(_ passwword: String, completion: @escaping (MXResponse<PasswordPolicyVerificationResult>) -> Void) -> MXHTTPOperation? {
        if let policy = self.passwordPolicy {
            completion(.success(self.verify(passwword, with: policy)))
            return nil
        } else {
            return self.getPasswordPolicy(completion: { (response) in
                switch response {
                case .success(let policy):
                    completion(.success(self.verify(passwword, with: policy)))
                    self.passwordPolicy = policy
                case .failure/*(let error)*/:
                    // Ignore this error for the moment (some servers did not support this request yet), validate by default the pwd
                    //completion(.failure(error))
                    completion(.success(.authorized))
                }
            })
        }
    }
    
    private func getPasswordPolicy(completion: @escaping (MXResponse<PasswordPolicyType>) -> Void) -> MXHTTPOperation? {
        return httpClient.request(withMethod: "GET", path: "password_policy", parameters: nil, success: { (response: [AnyHashable: Any]?) in
            NSLog("[PasswordPolicyService] password_policy resquest succeeded")
            guard let response = response else {
                completion(.failure(PasswordPolicyServiceError.unknown))
                return
            }
            
            let minLength = response["m.minimum_length"] as? Int ?? FormRules.passwordMinLength
            let isDigitRequired = response["m.require_digit"] as? Bool ?? false
            let isSymbolRequired = response["m.require_symbol"] as? Bool ?? false
            let isUppercaseRequired = response["m.require_uppercase"] as? Bool ?? false
            let isLowercaseRequired = response["m.require_lowercase"] as? Bool ?? false
            
            let passwordPolicy = PasswordPolicy(minLength: minLength, isDigitRequired: isDigitRequired, isSymbolRequired: isSymbolRequired, isUppercaseRequired: isUppercaseRequired, isLowercaseRequired: isLowercaseRequired)
            
            completion(.success(passwordPolicy))
        }, failure: { (error: Error?) in
            NSLog("[PasswordPolicyService] password_policy resquest failed")
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(PasswordPolicyServiceError.unknown))
            }
        })
    }
    
    private func verify(_ password: String, with policy: PasswordPolicyType) -> PasswordPolicyVerificationResult {
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
