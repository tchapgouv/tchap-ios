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

/// `AuthenticationService` implementation of `AuthenticationServiceType` is used to authenticate a user on Tchap platforms.
final class AuthenticationService: AuthenticationServiceType {
    
    // MARK: - Properties
    
    private let accountManager: MXKAccountManager
    private let restClientBuilder: RestClientBuilder
    
    private var authenticationRestClient: MXRestClient?
    private var authenticationOperation: MXHTTPOperation?
    
    // MARK: - Setup
    
    init(accountManager: MXKAccountManager) {
        self.accountManager = accountManager
        self.restClientBuilder = RestClientBuilder()
    }
    
    // MARK: - Public
    
    // MARK: Authentication
    
    func authenticate(with email: String, password: String, completion: @escaping (MXResponse<String>) -> Void) {
        
        self.cancelPendingAuthentication()
        
        self.restClientBuilder.build(from: email) { (restClientBuilderResult) in
            switch restClientBuilderResult {
            case .success(let restClient):
                
                guard let identityServer = restClient.identityServer else {
                    completion(MXResponse.failure(AuthenticationServiceError.identityServerURLBuildFailed))
                    return
                }
                
                self.authenticationOperation = self.authenticate(using: restClient, email: email, password: password, completion: { (authenticationResult) in
                    switch authenticationResult {
                    case .success(let credentials):
                        do {
                            try self.addAccount(for: credentials, identityServerURL: identityServer)
                            completion(MXResponse.success(credentials.userId))
                        } catch {
                            completion(MXResponse.failure(error))
                        }
                    case .failure(let error):
                        completion(MXResponse.failure(error))
                    }
                })
                
                self.authenticationRestClient = restClient
                
            case .failure(let error):
                completion(MXResponse.failure(error))
            }
        }
    }
    
    func cancelPendingAuthentication() {
        self.authenticationOperation?.cancel()
        self.authenticationRestClient = nil
    }
    
    // MARK: Authentication
    
    private func authenticate(using restClient: MXRestClient, email: String, password: String, completion: @escaping (MXResponse<MXCredentials>) -> Void) -> MXHTTPOperation {
        
        let loginParameters: [String: Any] = [
            "type": MXLoginFlowType.password.identifier,
            "identifier": [
                "type": kMXLoginIdentifierTypeThirdParty,
                "medium": MX3PID.Medium.email.identifier,
                "address": email
            ],
            "password": password,
            // Patch: add the old login api parameters for an email address (medium and address),
            // to keep logging in against old HS.
            "medium": MX3PID.Medium.email.identifier,
            "address": email
        ]
        
        return restClient.login(parameters: loginParameters) { [weak restClient] (response) in
            guard let restClient = restClient else {
                completion(MXResponse.failure(AuthenticationServiceError.deallocatedRestClient))
                return
            }
            
            switch response {
            case .success(let jsonResponse):
                
                guard let credentials = MXCredentials.model(fromJSON: jsonResponse) as? MXCredentials, credentials.userId != nil, credentials.accessToken != nil else {
                    let error = NSError(domain: MXKAuthErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: Bundle.mxk_localizedString(forKey: "not_supported_yet")])
                    completion(MXResponse.failure(error))
                    return
                }
                
                // Workaround: HS does not return the right URL. Use the one we used to make the request
                credentials.homeServer = restClient.homeserver
                // Report the certificate trusted by user (if any)
                credentials.allowedCertificate = restClient.allowedCertificate
                
                completion(MXResponse.success(credentials))
            case .failure(let error):
                completion(MXResponse.failure(error))
            }
        }
    }
    
    private func addAccount(for credentials: MXCredentials, identityServerURL: String) throws {
        // Sanity check: check whether the user is not already logged in with this id
        guard self.accountManager.account(forUserId: credentials.userId) == nil else {
            throw AuthenticationServiceError.userAlreadyLoggedIn
        }
        
        // Report the new account in account manager
        guard let account = MXKAccount(credentials: credentials) else {
            throw AuthenticationServiceError.failToCreateAccount
        }
        
        account.identityServerURL = identityServerURL
        self.accountManager.addAccount(account, andOpenSession: true)
    }
}
