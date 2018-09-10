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
        static let homeServerSubDomain = "matrix"
        static let webAppSubDomain = "chat"
        static let registrationRetryInterval: TimeInterval = 10.0
    }
    
    // MARK: - Properties
    
    private let accountManager: MXKAccountManager
    private let restClient: MXRestClient
    
    private var registrationOperation: MXHTTPOperation?
    private var registrationRetryTimer: Timer?
    
    // MARK: - Setup
    
    init(accountManager: MXKAccountManager, restClient: MXRestClient) {
        self.accountManager = accountManager
        self.restClient = restClient
    }
    
    // MARK: - Public
    
    func submitRegistrationEmailVerification(to email: String, completion: @escaping (MXResponse<ThreePIDCredentials>) -> Void) {
        self.submitRegistrationEmailVerification(to: email, using: self.restClient, completion: completion)
    }
    
    func register(with threePIDCredentials: ThreePIDCredentials, password: String, deviceDisplayName: String, completion: @escaping (MXResponse<String>) -> Void) {
        
        guard let identityServer = self.restClient.identityServer else {
            completion(MXResponse.failure(RegistrationServiceError.identityServerURLBuildFailed))
            return
        }
        
        let registrationParameters: [String: Any] = [
            "auth":
                ["threepid_creds":
                    [
                        "client_secret": threePIDCredentials.clientSecret,
                        "id_server": threePIDCredentials.identityServerHost,
                        "sid": threePIDCredentials.sid
                    ],
                 "type": kMXLoginFlowTypeEmailIdentity
            ],
            "password": password,
            "bind_email": true,
            "initial_device_display_name": deviceDisplayName
        ]
        
        self.registerUntilEmailValidated(with: registrationParameters, using: self.restClient, completion: { (registrationResult) in
            switch registrationResult {
            case .success(let credentials):
                do {
                    try self.addAccount(for: credentials, identityServerURL: identityServer)
                    completion(MXResponse.success(credentials.userId))
                } catch {
                    self.cancelPendingRegistration()
                    completion(MXResponse.failure(error))
                }
            case .failure(let error):
                self.cancelPendingRegistration()
                completion(MXResponse.failure(error))
            }
        })
    }
    
    func cancelPendingRegistration() {
        self.registrationOperation?.cancel()
        self.registrationOperation = nil
        self.registrationRetryTimer?.invalidate()
        self.registrationRetryTimer = nil
    }
    
    // MARK: - Private
    
    private func webAppAppBaseStringURL(from homeServer: String) -> String {
        return homeServer.replacingOccurrences(of: Constants.homeServerSubDomain, with: Constants.webAppSubDomain)
    }
    
    private func buildNextLink(webAppBaseStringURL: String, clientSecret: String, homeServerStringURL: String, identityServerStringURL: String) -> String? {
        
        let percentEncode: ((String) -> String?) = { stringToEncode in
            stringToEncode.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        }
        
        guard let webAppBaseStringURLEncoded = percentEncode(webAppBaseStringURL),
            let clientSecretURLEncoded = percentEncode(clientSecret),
            let homeServerStringURLEncoded = percentEncode(homeServerStringURL),
            let identityServerStringURLEncoded = percentEncode(identityServerStringURL) else {
                return nil
        }
        
        return "\(webAppBaseStringURLEncoded)/#/register?client_secret=\(clientSecretURLEncoded)&hs_url=\(homeServerStringURLEncoded)&is_url=\(identityServerStringURLEncoded)"
    }
    
    func submitRegistrationEmailVerification(to email: String, using restClient: MXRestClient, completion: @escaping (MXResponse<ThreePIDCredentials>) -> Void) {
        
        guard let homeServer = restClient.homeserver, let homeServerURL = URL(string: restClient.homeserver) else {
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
        
        guard let nextLink: String = self.buildNextLink(webAppBaseStringURL: webAppBaseStringURL, clientSecret: clientSecret, homeServerStringURL: homeServerURL.absoluteString, identityServerStringURL: identityServerURL.absoluteString) else {
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
    
    private func registerUntilEmailValidated(with parameters: [String: Any], using restClient: MXRestClient, completion: @escaping (MXResponse<MXCredentials>) -> Void) {
        
        // Cancel pending registration request
        self.cancelPendingRegistration()
        
        let registerOperation = self.register(using: restClient, parameters: parameters) { [unowned self] (registrationResult) in
            
            switch registrationResult {
            case .success(let credentials):
                completion(MXResponse.success(credentials))
            case .failure(let error):
                
                // MXError unauthorized, retry registration until email validation is done
                if let mxError = MXError(nsError: error), mxError.errcode == kMXErrCodeStringUnauthorized {
                    
                    if #available(iOS 10.0, *) {
                        self.registrationRetryTimer = Timer.scheduledTimer(withTimeInterval: Constants.registrationRetryInterval, repeats: false, block: { [weak self] _ in
                            self?.registerUntilEmailValidated(with: parameters, using: restClient, completion: completion)
                        })
                    } else {
                        // TODO: Support iOS 10.0 min
                    }
                    
                } else {
                    completion(MXResponse.failure(error))
                }
            }
        }
        
        self.registrationOperation = registerOperation
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
        self.accountManager.addAccount(account, andOpenSession: true)
    }
}
