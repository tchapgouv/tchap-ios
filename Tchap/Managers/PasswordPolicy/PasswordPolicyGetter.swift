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

enum PasswordPolicyGetterError: Error {
    case unknown
}

/// `PasswordPolicyGetter` is used to retrieve the password policy forced by the server.
final class PasswordPolicyGetter: PasswordPolicyGetterType {
    
    /// The current HttpClient
    private let httpClient: MXHTTPClient
    
    // MARK: - Public
    init(homeServer: String) {
        self.httpClient = MXHTTPClient(baseURL: "\(homeServer)/\(kMXAPIPrefixPathUnstable)", accessToken: nil, andOnUnrecognizedCertificateBlock: nil)
    }
    
    func passwordPolicy(completion: @escaping (MXResponse<PasswordPolicyType>) -> Void) -> MXHTTPOperation? {
        return httpClient.request(withMethod: "GET", path: "password_policy", parameters: nil, success: { (response: [AnyHashable: Any]?) in
            NSLog("[PasswordPolicyGetter] password_policy resquest succeeded")
            guard let response = response else {
                completion(.failure(ThirdPartyIDResolverError.unknown))
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
            NSLog("[PasswordPolicyGetter] password_policy resquest failed")
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(ThirdPartyIDResolverError.unknown))
            }
        })
    }
}
