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

enum AccountValidityServiceError: Error {
    case unknown
}

/// Service used to manage Tchap accounts validity
final class AccountValidityService: AccountValidityServiceType {
    
    /// The current HttpClient
    private let httpClient: MXHTTPClient
    
    // MARK: - Public
    init(credentials: MXCredentials) {
        guard let homeServer = credentials.homeServer,
            let accessToken = credentials.accessToken else {
                fatalError("credentials should be defined")
        }
        self.httpClient = MXHTTPClient(baseURL: "\(homeServer)/\(kMXAPIPrefixPathUnstable)", accessToken: accessToken, andOnUnrecognizedCertificateBlock: nil)
    }
    
    func requestRenewalEmail(completion: @escaping (MXResponse<Void>) -> Void) -> MXHTTPOperation? {
        return httpClient.request(withMethod: "POST", path: "account_validity/send_mail", parameters: nil, success: { (response: [AnyHashable: Any]?) in
            NSLog("[AccountValidityService] request renewal email succeeded")
            completion(.success(Void()))
        }, failure: { (error: Error?) in
            NSLog("[AccountValidityService] request renewal email failed")
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(AccountValidityServiceError.unknown))
            }
        })
    }
}
