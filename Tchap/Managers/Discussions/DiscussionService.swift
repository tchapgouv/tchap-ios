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
    ///   - includeInvite: A boolean to tell us if pending invitations have to be consider or not.
    ///   - completion: A closure called when the operation complete. Provide the discussion id (if any) when succeed.
    func getDiscussionIdentifier(for userID: String, includeInvite: Bool = true, completion: @escaping (MXResponse<String?>) -> Void) {
        guard let roomIDsList = self.session.directRooms[userID] else {
            // There is no discussion for the moment with this user
            completion(MXResponse.success(nil))
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
                completion(MXResponse.failure(membersError))
                return
            }
            
            if !joinedDiscussions.isEmpty {
                print("[DiscussionService] user: \(userID) found join-join discussion")
                self.getOldestRoomID(joinedDiscussions, completion: completion)
            } else if !receivedInvites.isEmpty {
                print("[DiscussionService] user: \(userID) found invite-join discussion")
                self.getOldestRoomID(receivedInvites, completion: completion)
            } else if !sentInvites.isEmpty {
                print("[DiscussionService] user: \(userID) found join-invite discussion")
                self.getOldestRoomID(sentInvites, completion: completion)
            } else if !leftDiscussions.isEmpty {
                print("[DiscussionService] user: \(userID) found join|invite-left discussion")
                self.getOldestRoomID(leftDiscussions, completion: completion)
            }
        }
    }
    
    // MARK: - Private
    private func getOldestRoomID(_ roomIDs: [String], completion: @escaping (MXResponse<String?>) -> Void) {
        guard roomIDs.count > 1 else {
            completion(MXResponse.success(roomIDs[0]))
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
            completion(MXResponse.success(discussionID))
        }
    }
}
