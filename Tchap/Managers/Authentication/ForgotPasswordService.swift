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

enum ForgotPasswordServiceError: Error {
    case invalidPassword(reason: PasswordPolicyRejectionReason)
}

/// `ForgotPasswordService` implementation of `ForgotPasswordServiceType` is used to perform reset password requests on Tchap platforms.
final class ForgotPasswordService: ForgotPasswordServiceType {
    
    // MARK: - Properties
        
    private let restClient: MXRestClient
    private let passwordPolicyService: PasswordPolicyServiceType
    
    // MARK: - Setup
    
    init(restClient: MXRestClient) {
        guard let homeServer = restClient.credentials.homeServer else {
            fatalError("homeserver should be defined")
        }
        self.restClient = restClient
        self.passwordPolicyService = PasswordPolicyService(homeServer: homeServer)
    }
    
    // MARK: - Public
    
    func validateParametersAndRequestForgotPasswordEmail(password: String?, email: String, completion: @escaping (MXResponse<ThreePIDCredentials>) -> Void) -> MXHTTPOperation {
        // Create an empty operation that will be mutated later
        let operation = MXHTTPOperation()
        
        // Validate first the password (if any)
        if let password = password {
            let operation1 = self.passwordPolicyService.verifyPassword(password) { (response) in
                switch response {
                case .success(let result):
                    switch result {
                    case .authorized:
                        // Pursue by requesting an email to validate the email address
                        let operation2 = self.requestForgotPasswordEmail(to: email, using: self.restClient, completion: completion)
                        operation.mutate(to: operation2)
                    case .unauthorized(let reason):
                        completion(.failure(ForgotPasswordServiceError.invalidPassword(reason: reason)))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            operation.mutate(to: operation1)
        } else if let operation1 = self.requestForgotPasswordEmail(to: email, using: self.restClient, completion: completion) {
            operation.mutate(to: operation1)
        }
        
        return operation
    }
    
    func resetPassword(withEmailCredentials threePIDCredentials: ThreePIDCredentials, newPassword: String, completion: @escaping (MXResponse<Void>) -> Void) -> MXHTTPOperation {
        
        let resetPasswordParameters: [String: Any] = [
            "auth":
                ["threepid_creds":
                    [
                        "client_secret": threePIDCredentials.clientSecret,
                        "id_server": threePIDCredentials.identityServerHost,
                        "sid": threePIDCredentials.sid
                    ],
                 "type": kMXLoginFlowTypeEmailIdentity
            ],
            "new_password": newPassword
        ]
        
        return self.restClient.resetPassword(parameters: resetPasswordParameters, completion: completion)
    }
    
    // MARK: - Private
    
    private func requestForgotPasswordEmail(to email: String, using restClient: MXRestClient, completion: @escaping (MXResponse<ThreePIDCredentials>) -> Void) -> MXHTTPOperation? {
        guard let identityServer = restClient.identityServer,
            let identityServerURL = URL(string: identityServer),
            let identityServerHost = identityServerURL.host else {
                completion(MXResponse.failure(RegistrationServiceError.homeServerURLBuildFailed))
                return nil
        }
        
        guard let clientSecret = MXTools.generateSecret() else {
            completion(MXResponse.failure(RegistrationServiceError.homeServerURLBuildFailed))
            return nil
        }
        
        return restClient.forgetPassword(forEmail: email, clientSecret: clientSecret, sendAttempt: 1, success: { (sid) in
            guard let sid = sid else {
                completion(MXResponse.failure(RegistrationServiceError.validationTokenFailed))
                return
            }
            
            let threePIDCredentials = ThreePIDCredentials(clientSecret: clientSecret, sid: sid, identityServerHost: identityServerHost)
            completion(MXResponse.success(threePIDCredentials))
        }, failure: { error in
            if let error = error {
                completion(MXResponse.failure(error))
            } else {
                completion(MXResponse.failure(RegistrationServiceError.validationTokenFailed))
            }
        })
    }
}
