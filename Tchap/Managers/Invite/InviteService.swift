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

enum InviteServiceError: Error {
    case unknown
}

/// `InviteService` is used to invite someone to join Tchap
final class InviteService: InviteServiceType {
    
    // MARK: Private
    private let session: MXSession
    
    private let discussionFinder: DiscussionFinderType
    private let thirdPartyIDResolver: ThirdPartyIDResolverType
    private let userService: UserServiceType
    private let roomService: RoomServiceType
    
    // MARK: - Public
    init(session: MXSession) {
        self.session = session
        self.discussionFinder = DiscussionFinder(session: session)
        self.thirdPartyIDResolver = ThirdPartyIDResolver(credentials: self.session.matrixRestClient.credentials)
        self.userService = UserService(session: session)
        self.roomService = RoomService(session: session)
    }
    
    func sendEmailInvite(to email: String, completion: @escaping (MXResponse<InviteServiceResult>) -> Void) {
        // Start the invite process by checking whether a Tchap account has been created for this email.
        self.discoverUser(with: email, completion: { [weak self] (response) in
            switch response {
            case .success(let result):
                switch result {
                case .bound(let userID):
                    completion(.success(.inviteIgnoredForDiscoveredUser(userID: userID)))
                case .unbound:
                    // Pursue the invite process by checking whether an invite has been already sent
                    self?.discussionFinder.getDiscussionIdentifier(for: email) { [weak self] (response) in
                        guard let self = self else {
                            return
                        }
                        
                        switch response {
                        case .success(let result):
                            switch result {
                            case .joinedDiscussion(let roomID):
                                // There is already a discussion with this email
                                // We do not re-invite the NoTchapUser except if
                                // the email is bound to the external instance (for which the invites may expire).
                                self.userService.isEmailBoundToTheExternalHost(email) { [weak self] (response) in
                                    switch response {
                                    case .success(let isExternal):
                                        if isExternal {
                                            // Leave this empty discussion, we will invite again this email.
                                            // We don't have a way for the moment to check if the invite expired or not...
                                            self?.session.leaveRoom(roomID) { [weak self] (response) in
                                                switch response {
                                                case .success:
                                                    // Send the new invite
                                                    self?.createDiscussion(with: email, completion: completion)
                                                case .failure:
                                                    // Ignore the error, notify the user that the invite has been already sent
                                                    completion(.success(.inviteAlreadySent(roomID: roomID)))
                                                }
                                            }
                                        } else {
                                            // Notify the user that the invite has been already sent
                                            completion(.success(.inviteAlreadySent(roomID: roomID)))
                                        }
                                    case .failure:
                                        // Ignore the error, notify the user that the invite has been already sent
                                        completion(.success(.inviteAlreadySent(roomID: roomID)))
                                    }
                                }
                            case .noDiscussion:
                                // Send the invite if the email is authorized
                                self.createDiscussion(with: email, completion: completion)
                            default:
                                break
                            }
                        case .failure(let error):
                            NSLog("[InviteService] sendEmailInvite failed")
                            completion(MXResponse.failure(error))
                        }
                    }
                }
            case .failure(let error):
                completion(MXResponse.failure(error))
            }
        })
    }
    
    // MARK: - Private
    
    // Check whether a Tchap account has been created for this email. The closure returns a nil identifier when no account exists.
    private func discoverUser(with email: String, completion: @escaping (MXResponse<ThirdPartyIDResolveResult>) -> Void) {
        if let lookup3pidsOperation = self.thirdPartyIDResolver.lookup(address: email, medium: .email, identityServer: self.session.matrixRestClient.identityServer, completion: completion) {
            lookup3pidsOperation.maxRetriesTime = 0
        } else {
            NSLog("[InviteService] discoverUser failed")
            completion(MXResponse.failure(InviteServiceError.unknown))
        }
    }
    
    private func createDiscussion(with email: String, completion: @escaping (MXResponse<InviteServiceResult>) -> Void) {
        self.userService.isEmailAuthorized(email) { [weak self] (response) in
            switch response {
            case .success(let isAuthorized):
                if isAuthorized {
                    guard let identityServer = self?.session.matrixRestClient.identityServer,
                        let identityServerURL = URL(string: identityServer),
                        let identityServerHost = identityServerURL.host else {
                        return
                    }
                    
                    let thirdPartyId = MXInvite3PID()
                    thirdPartyId.medium = MX3PID.Medium.email.identifier
                    thirdPartyId.address = email
                    thirdPartyId.identityServer = identityServerHost
                    
                    _ = self?.roomService.createDiscussionWithThirdPartyID(thirdPartyId, completion: { (response) in
                        switch response {
                        case .success(let roomID):
                            completion(.success(.inviteHasBeenSent(roomID: roomID)))
                        case .failure(let error):
                            NSLog("[InviteService] createDiscussion failed")
                            completion(MXResponse.failure(error))
                        }
                    })
                } else {
                    completion(.success(.inviteIgnoredForUnauthorizedEmail))
                }
                
            case .failure(let error):
                completion(MXResponse.failure(error))
            }
        }
    }
}
