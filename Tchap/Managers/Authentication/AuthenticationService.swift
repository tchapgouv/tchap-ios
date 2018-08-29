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
    
    // MARK: - Setup
    
    init(accountManager: MXKAccountManager) {
        self.accountManager = accountManager
    }
    
    // MARK: - Public
    
    func authenticate(with mail: String, password: String, completion: @escaping (MXResponse<String>) -> Void) {
        
        self.resolveHomeServer(with: mail) { (resolveResult) in
            switch resolveResult {
            case .success(let homeServer):
                self.authenticate(with: homeServer, mail: mail, password: password, completion: { (authenticationResult) in
                    switch authenticationResult {
                    case .success(let credentials):
                        do {
                            try self.addAccount(for: credentials, identityServerURL: homeServer)
                            completion(MXResponse.success(credentials.userId))
                        } catch {
                            completion(MXResponse.failure(error))
                        }
                    case .failure(let error):
                        completion(MXResponse.failure(error))
                    }
                })
            case .failure(let error):
                completion(MXResponse.failure(error))
            }
        }
    }
    
    // MARK: - Private
    
    private func resolveHomeServer(with mail: String, completion: @escaping (MXResponse<String>) -> Void) {
        // Create a new resolver each time user wants to login because identityServerURLs should be shuffled.
        let thirdPartyIDPlatformInfoResolver = self.createThirdPartyIDPlatformInfoResolver()
        
        thirdPartyIDPlatformInfoResolver.resolvePlatformInformation(address: mail, medium: kMX3PIDMediumEmail, success: { (resolveResult) in
            switch resolveResult {
            case .authorizedThirdPartyID(info: let thirdPartyIDPlatformInfo):
                completion(MXResponse.success(thirdPartyIDPlatformInfo.homeServer))
            case .unauthorizedThirdPartyID:
                completion(MXResponse.failure(AuthenticationServiceError.unauthorizedThirdPartyID))
            }
        }, failure: { (error) in
            completion(MXResponse.failure(AuthenticationServiceError.thirdPartyIDResolveFailure(error: error)))
        })
    }
    
    private func createThirdPartyIDPlatformInfoResolver() -> ThirdPartyIDPlatformInfoResolver {
        guard let serverUrlPrefix = UserDefaults.standard.string(forKey: "serverUrlPrefix") else {
            fatalError("serverUrlPrefix should be defined")
        }
        let identityServerURLs = IdentityServersURLGetter(currentIdentityServerURL: nil).identityServerUrls
        let thirdPartyIDPlatformInfoResolver = ThirdPartyIDPlatformInfoResolver(identityServerUrls: identityServerURLs, serverPrefixURL: serverUrlPrefix)
        return thirdPartyIDPlatformInfoResolver
    }
    
    private func createRestClient(homeServerURL: URL, onUnrecognizedCertificate: @escaping MXHTTPClientOnUnrecognizedCertificate) -> MXRestClient {
        return MXRestClient(homeServer: homeServerURL) { (certificateData) -> Bool in
            onUnrecognizedCertificate(certificateData)
        }
    }
    
    private func onUnrecognizedCertificateAction(homeServerURL: URL) -> MXHTTPClientOnUnrecognizedCertificate {
        let onUnrecognizedCertificate: MXHTTPClientOnUnrecognizedCertificate = { (certificateData) -> Bool in
            
            let certificateFingerprint: String
            
            if let certificateData = certificateData {
                certificateFingerprint = (certificateData as NSData).mx_SHA256AsHexString()
            } else {
                certificateFingerprint = ""
            }
            
            print("[AuthenticationService] Unrecognize certificate for homeserver: \(homeServerURL.absoluteString)\nfingerprint: \(certificateFingerprint)")
            
            return false
        }
        
        return onUnrecognizedCertificate
    }
    
    private func authenticate(with homeServer: String, mail: String, password: String, completion: @escaping (MXResponse<MXCredentials>) -> Void) {
        guard let homeServerURL = URL(string: homeServer) else {
            completion(MXResponse.failure(AuthenticationServiceError.homeServerURLBuildFailed))
            return
        }
        
        let onUnrecognizedCertificate = self.onUnrecognizedCertificateAction(homeServerURL: homeServerURL)
        let restClient = self.createRestClient(homeServerURL: homeServerURL) { (certificateData) -> Bool in
            completion(MXResponse.failure(AuthenticationServiceError.unrecognizedCertificate))
            return onUnrecognizedCertificate(certificateData)
        }
        
        let loginParameters: [String: Any] = [
            "type" : MXLoginFlowType.password.identifier,
            "identifier" : [
                "type" : kMXLoginIdentifierTypeThirdParty,
                "medium" : MX3PID.Medium.email.identifier,
                "address" : mail
            ],
            "password" : password,
            // Patch: add the old login api parameters for an email address (medium and address),
            // to keep logging in against old HS.
            "medium" : MX3PID.Medium.email.identifier,
            "address" : mail
        ]
        
        restClient.login(parameters: loginParameters) { (response) in
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
    
    func addAccount(for credentials: MXCredentials, identityServerURL: String) throws {
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
