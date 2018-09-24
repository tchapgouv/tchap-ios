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

/// List the different result cases
enum DiscussionSearchResult {
    case joinedDiscussion(roomID: String)
    case pendingInvite(roomID: String)
    case noDiscussion
}

/// `DiscussionServiceError` represent errors reported by DiscussionService.
enum DiscussionServiceError: Error {
    case invalidReceivedInvite
}


/// `DiscussionService` is used to find the direct chat which is the most suitable discussion with a Tchap user.
/// The aim is to handle only one discussion by Tchap user, and prevent the client from creating multiple one-one with the same user.
final class DiscussionService {
    
    // MARK: Private
    private let session: MXSession
    
    // MARK: - Public
    
    init(session: MXSession) {
        self.session = session
    }
    
    /// Returns the identifier of the current discussion for a given user ID, if any.
    /// The returned discussion may be a pending invite from this user.
    ///
    /// - Parameters:
    ///   - userID: The user identifier to search for. This identifier is a matrix id or an email address.
    ///   - includeInvite: Tell whether the pending invitations have to be considered or not.
    ///   - autoJoin: When the current discussion is a pending invite, this boolean tells whether we must join it automatically before returning.
    ///   - completion: A closure called when the operation complete. Provide the discussion id (if any) when succeed.
    func getDiscussionIdentifier(for userID: String, includeInvite: Bool = true, autoJoin: Bool = true, completion: @escaping (MXResponse<DiscussionSearchResult>) -> Void) {
        guard let roomIDsList = self.session.directRooms[userID] else {
            // There is no discussion for the moment with this user
            completion(.success(.noDiscussion))
            return
        }
        
        // We review all the existing direct chats and order them according to the combination of the members's membership.
        // We consider the following combinations (the first membership is the current user's one):
        // 1. join-join
        // 2. invite-join
        // 3. join-invite
        // 4. join-left (or invite-left)
        // The case left-x isn't possible because we ignore for the moment the left rooms.
        var joinedDiscussions = [String]()
        var receivedInvites = [String]()
        var sentInvites = [String]()
        var leftDiscussions = [String]()
        var membersError: Error?
        
        let group = DispatchGroup()
        
        for roomID in roomIDsList {
            guard let room: MXRoom = self.session.room(withRoomId: roomID) else { continue }
            
            if MXTools.isMatrixUserIdentifier(userID) {
                let isPendingInvite = (room.summary.membership == .invite)
                
                if includeInvite || !isPendingInvite {
                    group.enter()
                    room.members { response in
                        switch response {
                        case .success(let roomMembers):
                            if let member = roomMembers?.member(withUserId: userID) {
                                switch member.membership {
                                case .join:
                                    if !isPendingInvite {
                                        // the other user is present in this room (join-join)
                                        joinedDiscussions.append(roomID)
                                    } else {
                                        // I am invited by the other member (invite-join)
                                        receivedInvites.append(roomID)
                                    }
                                case .invite:
                                    // the other user is invited (join-invite)
                                    sentInvites.append(roomID)
                                case .leave:
                                    // the other member has left this room
                                    // and I can be invite or join
                                    leftDiscussions.append(roomID)
                                default: break
                                }
                            }
                            group.leave()
                        case .failure(let error):
                            // We did not optimize the error handling here because this is an unexpected error in our use case.
                            // We should improve the error handling by breaking the loop for.
                            membersError = error
                            group.leave()
                        }
                    }
                }
            } else {
                // Consider here the user id is an email.
                // The room is a discussion created to invite this user by email.
                // Add it to the sent invites list
                sentInvites.append(roomID)
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            if let membersError = membersError {
                completion(.failure(membersError))
                return
            }
            
            // Select the most suitable array
            if !joinedDiscussions.isEmpty {
                print("[DiscussionService] user: \(userID) found a join-join discussion")
                self.getOldestRoomID(joinedDiscussions) { roomID in
                    completion(.success(.joinedDiscussion(roomID: roomID)))
                }
            } else if !receivedInvites.isEmpty {
                print("[DiscussionService] user: \(userID) found an invite-join discussion")
                
                if autoJoin {
                    self.joinPendingInvite(receivedInvites, completion: { (response) in
                        switch response {
                        case .success (let roomID):
                            print("[DiscussionService] user: \(userID) join a pending invite")
                            completion(.success(.joinedDiscussion(roomID: roomID)))
                        case .failure(let error):
                            print("[DiscussionService] user: \(userID) failed to join a pending invite")
                            switch error {
                            case let serviceError as DiscussionServiceError:
                                switch serviceError {
                                case .invalidReceivedInvite:
                                    // Fallback on other listed rooms, if any.
                                    if !sentInvites.isEmpty {
                                        print("[DiscussionService] user: \(userID) found a join-invite discussion")
                                        self.getOldestRoomID(sentInvites) { roomID in
                                            completion(.success(.joinedDiscussion(roomID: roomID)))
                                        }
                                    } else if !leftDiscussions.isEmpty {
                                        print("[DiscussionService] user: \(userID) found a join|invite-left discussion")
                                        self.getOldestRoomID(leftDiscussions) { roomID in
                                            completion(.success(.joinedDiscussion(roomID: roomID)))
                                        }
                                    } else {
                                        completion(.success(.noDiscussion))
                                    }
                                }
                            default:
                                completion(.failure(error))
                            }
                        }
                    })
                } else {
                    self.getOldestRoomID(receivedInvites) { roomID in
                        completion(.success(.pendingInvite(roomID: roomID)))
                    }
                }
            } else if !sentInvites.isEmpty {
                print("[DiscussionService] user: \(userID) found a join-invite discussion")
                self.getOldestRoomID(sentInvites) { roomID in
                    completion(.success(.joinedDiscussion(roomID: roomID)))
                }
            } else if !leftDiscussions.isEmpty {
                print("[DiscussionService] user: \(userID) found a join|invite-left discussion")
                self.getOldestRoomID(leftDiscussions) { roomID in
                    completion(.success(.joinedDiscussion(roomID: roomID)))
                }
            } else {
                completion(.success(.noDiscussion))
            }
        }
    }
    
    // MARK: - Private
    
    private func getOldestRoomID(_ roomIDs: [String], completion: @escaping (String) -> Void) {
        guard roomIDs.count > 1 else {
            completion(roomIDs[0])
            return
        }
        
        // Look for the oldest created room in the provided list
        // Return the first item by default
        var discussionID = roomIDs[0]
        var discussionCreationTS: UInt64 = UInt64.max
        
        let group = DispatchGroup()
        
        for roomID in roomIDs {
            guard let room: MXRoom = self.session.room(withRoomId: roomID) else { continue }
            
            group.enter()
            room.state { roomState in
                if let event = roomState?.stateEvents(with: MXEventType.roomCreate)?.first, event.originServerTs < discussionCreationTS {
                    discussionCreationTS = event.originServerTs
                    discussionID = roomID
                }
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            completion(discussionID)
        }
    }
    
    // Join the oldest pending invite by ignoring empty room
    private func joinPendingInvite(_ pendingInvites: [String], completion: @escaping (MXResponse<String>) -> Void) {
        self.getOldestRoomID(pendingInvites) { roomID in
            // Join the selected discussion
            self.session.joinRoom(roomID) { [weak self] response in
                guard let sself = self else {
                    return
                }
                
                switch response {
                case .success:
                    completion(.success(roomID))
                case .failure(let error):
                    // Check whether we failed to join an empty room
                    let nsError = error as NSError
                    if let message = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
                        if message == "No known servers" {
                            print("[DiscussionService] Ignore a pending invite to an empty room")
                            let updatedInvites = pendingInvites.filter { $0 != roomID }
                            if !updatedInvites.isEmpty {
                                // Loop to join another pending invite
                                sself.joinPendingInvite(updatedInvites, completion: completion)
                            } else {
                                completion(.failure(DiscussionServiceError.invalidReceivedInvite))
                            }
                            
                            // Remove this invalid invite from the user's rooms
                            sself.session.leaveRoom(roomID, completion: { response in
                            })
                            return
                        }
                    }
                    completion(.failure(error))
                }
            }
        }
    }
}
