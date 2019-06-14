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

/// `RegistrationService` implementation of `RegistrationServiceType` is used to register a user on Tchap platforms.
final class RegistrationService: RegistrationServiceType {
    
    // MARK: - Constants
    
    private enum Constants {
        static let registrationRetryInterval: TimeInterval = 10.0
    }
    
    // MARK: - Properties
    
    private let accountManager: MXKAccountManager
    private let restClient: MXRestClient
    private let passwordPolicyGetter: PasswordPolicyGetterType
    
    private var passwordPolicyService: PasswordPolicyServiceType?
    
    private var registrationOperation: MXHTTPOperation?
    
    // MARK: - Setup
    
    init(accountManager: MXKAccountManager, restClient: MXRestClient) {
        guard let homeServer = restClient.credentials.homeServer else {
                fatalError("homeserver should be defined")
        }
        self.accountManager = accountManager
        self.restClient = restClient
        self.passwordPolicyGetter = PasswordPolicyGetter(homeServer: homeServer)
    }
    
    // MARK: - Public
    
    func setupRegistrationSession(completion: @escaping (MXResponse<String>) -> Void) {
        self.restClient.getRegisterSession(completion: { (response) in
            switch response {
            case .success(let authenticationSession):
                if let sessionId = authenticationSession.session {
                    completion(MXResponse.success(sessionId))
                } else {
                    let error = NSError(domain: MXKAuthErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: Bundle.mxk_localizedString(forKey: "not_supported_yet")])
                    completion(MXResponse.failure(error))
                }
                
            case .failure(let error):
                completion(MXResponse.failure(error))
            }
        })
    }
    
    func validateRegistrationParametersAndRequestEmailVerification(password: String?, email: String, sessionId: String, completion: @escaping (MXResponse<ThreePIDCredentials>) -> Void) {
        // Validate first the password (if any)
        if let password = password {
            self.validatePassword(passwword: password) { (response) in
                switch response {
                case .success(let result):
                    switch result {
                    case .authorized:
                        // Pursue by requesting an email to validate the email address
                        self.requestEmailVerification(to: email, sessionId: sessionId, using: self.restClient, completion: completion)
                    case .unauthorized(let reason):
                        completion(.failure(RegistrationServiceError.invalidPassword(reason: reason)))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            self.requestEmailVerification(to: email, sessionId: sessionId, using: self.restClient, completion: completion)
        }
    }
    
    func register(withEmailCredentials threePIDCredentials: ThreePIDCredentials, sessionId: String?, password: String?, deviceDisplayName: String, completion: @escaping (MXResponse<String>) -> Void) {
        
        guard let identityServer = self.restClient.identityServer else {
            completion(MXResponse.failure(RegistrationServiceError.identityServerURLBuildFailed))
            return
        }
        
        var authParameters: [String: Any] = [
            "threepid_creds": [
                "client_secret": threePIDCredentials.clientSecret,
                "id_server": threePIDCredentials.identityServerHost,
                "sid": threePIDCredentials.sid
            ],
            "type": kMXLoginFlowTypeEmailIdentity
        ]
        
        // Check whether a sessionId is provided
        if let sessionId = sessionId {
            authParameters["session"] = sessionId
        }
        
        var registrationParameters: [String: Any] = [
            "auth": authParameters,
            "initial_device_display_name": deviceDisplayName
        ]
        
        // Check whether a password is provided
        if let password = password {
            registrationParameters["password"] = password
            registrationParameters["bind_email"] = true
        }
        
        // Cancel pending registration request
        self.cancelPendingRegistration()
        self.registrationOperation = self.register(using: self.restClient, parameters: registrationParameters) { [unowned self] (registrationResult) in
            
            self.registrationOperation = nil
            switch registrationResult {
            case .success(let credentials):
                if let userId = credentials.userId {
                    do {
                        try self.addAccount(for: credentials, identityServerURL: identityServer)
                        completion(MXResponse.success(userId))
                    } catch {
                        completion(MXResponse.failure(error))
                    }
                } else {
                    completion(MXResponse.failure(AuthenticationServiceError.failToCreateAccount))
                }
            case .failure(let error):
                completion(MXResponse.failure(error))
            }
        }
    }
    
    func cancelPendingRegistration() {
        self.registrationOperation?.cancel()
        self.registrationOperation = nil
    }
    
    // MARK: - Private
    
    private func webAppAppBaseStringURL(from homeServer: String) -> String {
        // For the moment we use the homeserver url, this base url should be updated later with the actual web app url.
        return homeServer
    }
    
    private func buildNextLink(webAppBaseStringURL: String, clientSecret: String, homeServerStringURL: String, identityServerStringURL: String, sessionId: String) -> String? {
        
        let percentEncode: ((String) -> String?) = { stringToEncode in
            stringToEncode.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        }
        
        guard let webAppBaseStringURLEncoded = percentEncode(webAppBaseStringURL),
            let clientSecretURLEncoded = percentEncode(clientSecret),
            let homeServerStringURLEncoded = percentEncode(homeServerStringURL),
            let identityServerStringURLEncoded = percentEncode(identityServerStringURL),
            let sessionIdURLEncoded = percentEncode(sessionId) else {
                return nil
        }
        
        return "\(webAppBaseStringURLEncoded)/#/register?client_secret=\(clientSecretURLEncoded)&hs_url=\(homeServerStringURLEncoded)&is_url=\(identityServerStringURLEncoded)&session_id=\(sessionIdURLEncoded)"
    }
    
    private func validatePassword(passwword: String, completion: @escaping (MXResponse<PasswordPolicyVerificationResult>) -> Void) {
        if let passwordPolicyService = self.passwordPolicyService {
            completion(.success(passwordPolicyService.verify(passwword)))
        } else {
            _ = self.passwordPolicyGetter.passwordPolicy(completion: { (response) in
                switch response {
                case .success(let policy):
                    let passwordPolicyService = PasswordPolicyService(policy: policy)
                    completion(.success(passwordPolicyService.verify(passwword)))
                    self.passwordPolicyService = passwordPolicyService
                case .failure/*(let error)*/:
                    // Ignore this error for the moment (some servers did not support this request yet), validate by default the pwd
                    //completion(.failure(error))
                    completion(.success(.authorized))
                }
            })
        }
    }
    
    private func requestEmailVerification(to email: String, sessionId: String, using restClient: MXRestClient, completion: @escaping (MXResponse<ThreePIDCredentials>) -> Void) {
        
        guard let homeServer = restClient.homeserver, let homeServerURL = URL(string: homeServer) else {
            completion(MXResponse.failure(RegistrationServiceError.homeServerURLBuildFailed))
            return
        }
        
        let identityServerURL = homeServerURL
        
        let email3PID: MXK3PID = MXK3PID(medium: kMX3PIDMediumEmail, andAddress: email)
        
        guard let clientSecret = email3PID.clientSecret else {
            completion(MXResponse.failure(RegistrationServiceError.missingClientSecret))
            return
        }
        
        let webAppBaseStringURL = self.webAppAppBaseStringURL(from: homeServer)
        
        let homeServerURLString = homeServerURL.absoluteString
        guard let nextLink: String = self.buildNextLink(webAppBaseStringURL: webAppBaseStringURL, clientSecret: clientSecret, homeServerStringURL: homeServerURLString, identityServerStringURL: homeServerURLString, sessionId: sessionId) else {
            completion(MXResponse.failure(RegistrationServiceError.nextLinkBuildFailed))
            return
        }
        
        email3PID.requestValidationToken(withMatrixRestClient: restClient, isDuringRegistration: true, nextLink: nextLink, success: {
            guard let sid = email3PID.sid, let identityServerHost = identityServerURL.host else {
                completion(MXResponse.failure(RegistrationServiceError.validationTokenFailed))
                return
            }
            
            let threePIDCredentials = ThreePIDCredentials(clientSecret: clientSecret,
                                                          sid: sid,
                                                          identityServerHost: identityServerHost)
            
            completion(MXResponse.success(threePIDCredentials))
            
        }, failure: { (error) in
            if let error = error {
                completion(MXResponse.failure(error))
            } else {
                completion(MXResponse.failure(RegistrationServiceError.validationTokenFailed))
            }
        })
    }
    
    private func register(using restClient: MXRestClient, parameters: [String: Any], completion: @escaping (MXResponse<MXCredentials>) -> Void) -> MXHTTPOperation {
        return restClient.register(parameters: parameters) { [weak restClient] (response) in
            guard let restClient = restClient else {
                completion(MXResponse.failure(RegistrationServiceError.deallocatedRestClient))
                return
            }
            
            switch response {
            case .success(let jsonResponse):
                
                guard let loginResponse = MXLoginResponse(fromJSON: jsonResponse), loginResponse.userId != nil, loginResponse.accessToken != nil else {
                    let error = NSError(domain: MXKAuthErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: Bundle.mxk_localizedString(forKey: "not_supported_yet")])
                    completion(MXResponse.failure(error))
                    return
                }
                
                // Build credentials
                let credentials = MXCredentials(loginResponse: loginResponse, andDefaultCredentials: restClient.credentials)
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
            throw RegistrationServiceError.userAlreadyLoggedIn
        }
        
        // Report the new account in account manager
        guard let account = MXKAccount(credentials: credentials) else {
            throw RegistrationServiceError.failToCreateAccount
        }
        
        account.identityServerURL = identityServerURL
        account.antivirusServerURL = credentials.homeServer
        self.accountManager.addAccount(account, andOpenSession: true)
    }
}
