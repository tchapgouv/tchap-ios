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

enum UserServiceError: Error {
    case unknown
}

/// `UserService` implementation of `UserServiceType` is used to handle Tchap users.
@objcMembers
final class UserService: NSObject, UserServiceType {
    
    // MARK: - Constants
    
    private enum Constants {
        static let searchUsersLimit: UInt = 50
        static let preprod_external_prefix: String = "e."
        static let external_prefix: String = "agent.externe."
        static let userInfoKeyExpired = "expired"
        static let userInfoKeyDeactivated = "deactivated"
    }
    
    // MARK: - Properties
    
    private let session: MXSession
    private let thirdPartyIDPlatformInfoResolver: ThirdPartyIDPlatformInfoResolverType
    private let httpClient: MXHTTPClient
    
    // MARK: - Setup
    
    init(session: MXSession) {
        guard let homeServer = session.matrixRestClient.credentials.homeServer else {
            fatalError("credentials should be defined")
        }
        self.session = session
        let serverUrlPrefix = BuildSettings.serverUrlPrefix
        let identityServerURLs = IdentityServersURLGetter(currentIdentityServerURL: session.matrixRestClient?.identityServer).identityServerUrls
        self.thirdPartyIDPlatformInfoResolver = ThirdPartyIDPlatformInfoResolver(identityServerUrls: identityServerURLs, serverPrefixURL: serverUrlPrefix)
        
        /// The current HttpClient
        self.httpClient = MXHTTPClient(baseURL: "\(homeServer)/\(kMXAPIPrefixPathUnstable)", authenticated: true, andOnUnrecognizedCertificateBlock: nil)
        
        super.init()
        
        self.httpClient.tokenProviderHandler = { [weak self] (error, success, failure) in
            // swiftlint:disable force_unwrapping
            guard let accessToken = self?.session.matrixRestClient.credentials.accessToken else {
                failure!(error)
                return
            }
            success!(accessToken)
            // swiftlint:enable force_unwrapping
        }
    }
    
    // MARK: - Public
    
    func getUserFromLocalSession(with userId: String) -> User? {
        let user: User?
        
        if let matrixUser = self.session.user(withUserId: userId) {
            user = self.buildUser(from: matrixUser)
        } else {
            user = nil
        }
        
        return user
    }
    
    func findUser(with userId: String, completion: @escaping ((User?) -> Void)) {
        
        if let user = self.getUserFromLocalSession(with: userId) {
            completion(user)
        } else {
            // Retrieve display name and avatar url from user profile
            self.session.matrixRestClient.profile(forUser: userId) { (response) in
                switch response {
                case .success(let (displayName, avatarUrl)):
                    if let displayName = displayName {
                        let user = User(userId: userId, displayName: displayName, avatarStringURL: avatarUrl)
                        completion(user)
                    } else {
                        completion(nil)
                    }
                case .failure(let error):
                    MXLog.debug("Get profile failed for user id \(userId) with error: \(error)")
                    completion(nil)
                }
            }
        }
    }
    
    func buildTemporaryUser(from userId: String) -> User {
        let displayName = UserService.displayName(from: userId)
        return User(userId: userId, displayName: displayName, avatarStringURL: nil)
    }
    
    func isUserId(_ firstUserId: String, onTheSameHostAs secondUserId: String) -> Bool {
        guard let firstUserHostName = self.hostName(for: firstUserId),
            let secondUserHostName = self.hostName(for: secondUserId) else {
                return false
        }
        return firstUserHostName == secondUserHostName
    }
    
    func isAccountDeactivated(for userId: String, completion: @escaping ((MXResponse<Bool>) -> Void)) -> MXHTTPOperation? {
        return self.getUsersInfo(for: [userId]) { (response) in
            switch response {
            case .success(let usersInfo):
                if let deactivated = usersInfo[userId]?.deactivated {
                    completion(.success(deactivated))
                } else {
                    completion(.failure(UserServiceError.unknown))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Temporary version used in ObjectiveC.
    func isAccountDeactivated(for userId: String, success: @escaping ((Bool) -> Void), failure: ((Error) -> Void)?) -> MXHTTPOperation? {
        return self.isAccountDeactivated(for: userId) { (response) in
            switch response {
            case .success(let value):
                success(value)
            case .failure(let error):
                failure?(error)
            }
        }
    }
    
    func isAccountExpired(for userId: String, completion: @escaping ((MXResponse<Bool>) -> Void)) -> MXHTTPOperation? {
        return self.getUsersInfo(for: [userId]) { (response) in
            switch response {
            case .success(let usersInfo):
                if let expired = usersInfo[userId]?.expired {
                    completion(.success(expired))
                } else {
                    completion(.failure(UserServiceError.unknown))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Tells whether a Matrix identifier corresponds to an external Tchap user.
    /// Note: invalid identifier will be considered as external.
    ///
    /// - Parameters:
    ///   - userId: The Matrix user id.
    /// - Returns: true if the user is external.
    static func isExternalUser(for userId: String) -> Bool {
        guard let matrixIDComponents = UserIDComponents(matrixID: userId) else {
            return true
        }
        return UserService.isExternalServer(matrixIDComponents.hostName)
    }
    
    static func isExternalServer(_ hostName: String) -> Bool {
        return hostName.starts(with: Constants.preprod_external_prefix)
            || hostName.starts(with: Constants.external_prefix)
    }
    
    func isEmailAuthorized(_ email: String, completion: @escaping (MXResponse<Bool>) -> Void) {
        self.thirdPartyIDPlatformInfoResolver.resolvePlatformInformation(address: email, medium: kMX3PIDMediumEmail, success: { (resolveResult) in
            switch resolveResult {
            case .authorizedThirdPartyID(info: _):
                completion(.success(true))
            case .unauthorizedThirdPartyID:
                completion(.success(false))
            }
        }, failure: { (error) in
            if let error = error {
                completion(MXResponse.failure(error))
            }
        })
    }
    // Temporary version used in ObjectiveC.
    func isEmailAuthorized(_ email: String, success: @escaping ((Bool) -> Void), failure: ((Error) -> Void)?) {
        self.isEmailAuthorized(email) { (response) in
            switch response {
            case .success(let value):
                success(value)
            case .failure(let error):
                failure?(error)
            }
        }
    }
    
    func isEmailBoundToTheExternalHost(_ email: String, completion: @escaping (MXResponse<Bool>) -> Void) {
        self.thirdPartyIDPlatformInfoResolver.resolvePlatformInformation(address: email, medium: kMX3PIDMediumEmail, success: { (resolveResult) in
            switch resolveResult {
            case .authorizedThirdPartyID(info: let thirdPartyIDPlatformInfo):
                completion(.success(UserService.isExternalServer(thirdPartyIDPlatformInfo.hostname)))
            case .unauthorizedThirdPartyID:
                completion(.success(false))
            }
        }, failure: { (error) in
            if let error = error {
                completion(MXResponse.failure(error))
            }
        })
    }
    // Temporary version used in ObjectiveC.
    func isEmailBoundToTheExternalHost(_ email: String, success: @escaping ((Bool) -> Void), failure: ((Error) -> Void)?) {
        self.isEmailBoundToTheExternalHost(email) { (response) in
            switch response {
            case .success(let value):
                success(value)
            case .failure(let error):
                failure?(error)
            }
        }
    }
    
    func isEmailBound(_ email: String, to hostName: String, completion: @escaping (MXResponse<Bool>) -> Void) {
        self.thirdPartyIDPlatformInfoResolver.resolvePlatformInformation(address: email, medium: kMX3PIDMediumEmail, success: { (resolveResult) in
            switch resolveResult {
            case .authorizedThirdPartyID(info: let thirdPartyIDPlatformInfo):
                completion(.success(thirdPartyIDPlatformInfo.hostname == hostName))
            case .unauthorizedThirdPartyID:
                completion(.success(false))
            }
        }, failure: { (error) in
            if let error = error {
                completion(MXResponse.failure(error))
            }
        })
    }
    // Temporary version used in ObjectiveC.
    func isEmailBound(_ email: String, to hostName: String, success: @escaping ((Bool) -> Void), failure: ((Error) -> Void)?) {
        self.isEmailBound(email, to: hostName) { (response) in
            switch response {
            case .success(let value):
                success(value)
            case .failure(let error):
                failure?(error)
            }
        }
    }
    
    /// Build a display name from the tchap user identifier.
    /// We don't extract the domain for the moment in order to not display unexpected information.
    /// For example in case of "@jean.martin-modernisation.fr:matrix.org", this will return "Jean Martin".
    /// In case of an external user identifier, we return the local part of the id which corresponds to their email.
    ///
    /// - Parameter
    ///   - userId: The user id to parse
    /// - Returns: displayName without domain, an empty string if the id is not valid.
    static func displayName(from userId: String) -> String {
        let displayName: String
        let isExternal = isExternalUser(for: userId)
        
        if let name = DisplayNameComponents(userId: userId, isExternal: isExternal)?.name {
            displayName = name
        } else {
            // This case happen only if given user id is not a valid Matrix id
            displayName = ""
        }
        
        return displayName
    }
    
    func hostName(for userId: String) -> String? {
        guard let matrixIDComponents = UserIDComponents(matrixID: userId) else {
            return nil
        }
        return matrixIDComponents.hostName
    }
    
    func hostDisplayName(for userId: String) -> String? {
        guard let hostname = self.hostName(for: userId) else {
            return nil
        }
        return HomeServerComponents(hostname: hostname).displayName
    }
    
    // Temporary version used in ObjectiveC.
    func getUsersInfo(for userIds: [String], success: @escaping ((Dictionary<String, UserStatusInfoType>) -> Void), failure: ((Error) -> Void)?) -> MXHTTPOperation? {
        return self.getUsersInfo(for: userIds) { (response) in
            switch response {
            case .success(let value):
                success(value)
            case .failure(let error):
                failure?(error)
            }
        }
    }
    
    func getUsersInfo(for userIds: [String], completion: @escaping (Result<[String: UserStatusInfoType], Error>) -> Void) -> MXHTTPOperation? {
        return httpClient.request(withMethod: "POST",
                                  path: "users/info",
                                  parameters: ["user_ids": userIds],
                                  success: { (response: [AnyHashable: Any]?) in
                                    MXLog.debug("[UserService] users info resquest succeeded")
                                    guard let response = response as? [String: [String: Bool]] else {
                                        completion(.failure(UserServiceError.unknown))
                                        return
                                    }
                                    
                                    let usersInfo = response.mapValues {
                                        UserStatusInfo(expired: $0[Constants.userInfoKeyExpired] ?? false,
                                                       deactivated: $0[Constants.userInfoKeyDeactivated] ?? false)
                                    }
                                    
                                    completion(.success(usersInfo))
        },
                                  failure: { (error: Error?) in
                                    MXLog.debug("[UserService] users info resquest failed")
                                    if let error = error {
                                        completion(.failure(error))
                                    } else {
                                        completion(.failure(UserServiceError.unknown))
                                    }
        })
    }
    
    // MARK: - Private
    
    private func buildUser(from mxUser: MXUser) -> User {
        
        let displayName: String
        let userId: String = mxUser.userId
        
        if let matrixUserDisplayName = mxUser.displayname, matrixUserDisplayName.isEmpty == false {
            displayName = matrixUserDisplayName
        } else {
            displayName = UserService.displayName(from: userId)
        }
        
        return User(userId: userId, displayName: displayName, avatarStringURL: mxUser.avatarUrl)
    }
}
