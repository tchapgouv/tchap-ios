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

import UIKit
import RxSwift

// Internal structure used to store room creation parameters
struct RoomServiceCreationParameters {
    let visibility: MXRoomDirectoryVisibility
    let accessRule: RoomAccessRule
    let preset: MXRoomPreset
    let name: String?
    let alias: String?
    let inviteUserIDs: [String]?
    let inviteThirdPartyIDs: [MXInvite3PID]?
    let isFederated: Bool
    let historyVisibility: MXRoomHistoryVisibility?
    let powerLevelContentOverride: [String: Any]?
    let isDirect: Bool
}

enum RoomServiceError: Error {
    case invalidAvatarURL
    case directRoomCreationFailed
}

/// `RoomService` implementation of `RoomServiceType` is used to perform room operations.
final class RoomService: NSObject, RoomServiceType {
    
    // MARK: - Constants
    
    @objc static let roomAccessRuleRestricted = RoomAccessRule.restricted.identifier
    @objc static let roomAccessRuleUnrestricted = RoomAccessRule.unrestricted.identifier
    @objc static let roomAccessRuleDirect = RoomAccessRule.direct.identifier
    
    @objc static let roomAccessRulesStateEventType = "im.vector.room.access_rules"
    @objc static let roomAccessRulesContentRuleKey = "rule"

    // MARK: - Properties
    
    private let session: MXSession
    private var createdRoom: MXRoom?
    
    // MARK: - Setup
    
    @objc init(session: MXSession) {
        self.session = session
    }
    
    // MARK: - Public
    
    func createRoom(visibility: MXRoomDirectoryVisibility, name: String, avatarURL: String?, inviteUserIds: [String], isFederated: Bool, accessRule: RoomAccessRule) -> Single<String> {
        return self.createRoom(visibility: visibility, name: name, inviteUserIds: inviteUserIds, isFederated: isFederated, accessRule: accessRule)
        .flatMap { roomID in
            guard let avatarURL = avatarURL else {
                return Single.just(roomID)
            }
            
            return self.setAvatar(with: avatarURL, for: roomID)
            .map {
                return roomID
            }
        }
    }
    
    func createDiscussionWithThirdPartyID(_ thirdPartyID: MXInvite3PID, completion: @escaping (MXResponse<String>) -> Void) -> MXHTTPOperation {
        let roomServiceCreationParameters = RoomServiceCreationParameters(visibility: .private,
                                                            accessRule: .direct,
                                                            preset: .trustedPrivateChat,
                                                            name: nil,
                                                            alias: nil,
                                                            inviteUserIDs: nil,
                                                            inviteThirdPartyIDs: [thirdPartyID],
                                                            isFederated: true,
                                                            historyVisibility: nil,
                                                            powerLevelContentOverride: nil,
                                                            isDirect: true)
        return self.createRoom(with: roomServiceCreationParameters, completion: completion)
    }
    
    @objc func createDiscussion(with userID: String, success: @escaping ((String) -> Void), failure: @escaping ((Error) -> Void)) -> MXHTTPOperation {
        let roomServiceCreationParameters = RoomServiceCreationParameters(visibility: .private,
                                                            accessRule: .direct,
                                                            preset: .trustedPrivateChat,
                                                            name: nil,
                                                            alias: nil,
                                                            inviteUserIDs: [userID],
                                                            inviteThirdPartyIDs: nil,
                                                            isFederated: true,
                                                            historyVisibility: nil,
                                                            powerLevelContentOverride: nil,
                                                            isDirect: true)
        return self.createRoom(with: roomServiceCreationParameters, completion: { (response) in
            switch response {
            case .success(let roomID):
                success(roomID)
            case.failure(let error):
                failure(error)
            }
        })
    }
        
    // MARK: - Private
    
    private func setAvatar(with url: String, for roomID: String) -> Single<Void> {
        guard let avatarUrl = URL(string: url) else {
            return Single.error(RoomServiceError.invalidAvatarURL)
        }
        
        return Single.create { (single) -> Disposable in
            let httpOperation = self.session.matrixRestClient.setAvatar(ofRoom: roomID, avatarUrl: avatarUrl) { (response) in
                switch response {
                case .success:
                    single(.success(Void()))
                case .failure(let error):
                    single(.error(error))
                }
            }
            
            httpOperation.maxNumberOfTries = 0
            
            return Disposables.create {
                httpOperation.cancel()
            }
        }
    }
    
    private func createRoom(visibility: MXRoomDirectoryVisibility, name: String, inviteUserIds: [String], isFederated: Bool, accessRule: RoomAccessRule) -> Single<String> {
        
        return Single.create { (single) -> Disposable in
            let httpOperation = self.createRoom(visibility: visibility, name: name, inviteUserIds: inviteUserIds, isFederated: isFederated, accessRule: accessRule) { (response) in
                switch response {
                case .success(let roomID):
                    single(.success(roomID))
                case .failure(let error):                    
                    single(.error(error))
                }
            }
            
            httpOperation.maxNumberOfTries = 0
            
            return Disposables.create {
                httpOperation.cancel()
            }
        }
    }
    
    private func createRoom(visibility: MXRoomDirectoryVisibility, name: String, inviteUserIds: [String], isFederated: Bool, accessRule: RoomAccessRule, completion: @escaping (MXResponse<String>) -> Void) -> MXHTTPOperation {
        
        let preset: MXRoomPreset
        let historyVisibility: MXRoomHistoryVisibility?
        let alias: String?
        
        if visibility == .public {
            preset = .publicChat
            historyVisibility = .worldReadable
            // In case of a public room, the room alias is mandatory.
            // That's why, we deduce the room alias from the room name.
            alias = RoomService.defaultAliasName(for: name)
        } else {
            preset = .privateChat
            historyVisibility = .invited
            alias = nil
        }
        
        let roomServiceCreationParameters = RoomServiceCreationParameters(visibility: visibility,
                                                            accessRule: accessRule,
                                                            preset: preset,
                                                            name: name,
                                                            alias: alias,
                                                            inviteUserIDs: inviteUserIds,
                                                            inviteThirdPartyIDs: nil,
                                                            isFederated: isFederated,
                                                            historyVisibility: historyVisibility,
                                                            powerLevelContentOverride: nil,
                                                            isDirect: false)
        
        return self.createRoom(with: roomServiceCreationParameters, completion: completion)
    }
    
    private func createRoom(with roomServiceCreationParameters: RoomServiceCreationParameters, completion: @escaping (MXResponse<String>) -> Void) -> MXHTTPOperation {
        
        var parameters: [String: Any] = [:]
        
        if let name = roomServiceCreationParameters.name {
            parameters["name"] = name
        }
        
        parameters["visibility"] = roomServiceCreationParameters.visibility.identifier
        
        if let alias = roomServiceCreationParameters.alias {
            parameters["room_alias_name"] = alias
        }
        
        if let inviteUserIDs = roomServiceCreationParameters.inviteUserIDs {
            parameters["invite"] = inviteUserIDs
        }
        if let inviteThirdPartyIDs = roomServiceCreationParameters.inviteThirdPartyIDs?.compactMap({$0.dictionary}), inviteThirdPartyIDs.isEmpty == false {
            parameters["invite_3pid"] = inviteThirdPartyIDs
        }
        
        parameters["preset"] = roomServiceCreationParameters.preset.identifier
        
        if roomServiceCreationParameters.isFederated == false {
            parameters["creation_content"] = [ "m.federate": false ]
        }
        
        var initialStates: Array<[AnyHashable: Any]> = []
        
        let roomAccessRulesStateEvent = self.roomAccessRulesStateEvent(with: roomServiceCreationParameters.accessRule)
        initialStates.append(roomAccessRulesStateEvent.jsonDictionary())
        
        if let historyVisibility = roomServiceCreationParameters.historyVisibility {
            let historyVisibilityStateEvent = self.historyVisibilityStateEvent(with: historyVisibility)
            initialStates.append(historyVisibilityStateEvent.jsonDictionary())
        }
        
        parameters["initial_state"] = initialStates
        
        if let powerLevelContentOverride = roomServiceCreationParameters.powerLevelContentOverride {
            parameters["power_level_content_override"] = powerLevelContentOverride
        }
        
        if roomServiceCreationParameters.isDirect {
            parameters["is_direct"] = true
        }
        
        return self.session.createRoom(parameters: parameters, completion: { (response) in
            switch response {
            case .success(let room):
                if roomServiceCreationParameters.isDirect,
                    roomServiceCreationParameters.inviteUserIDs == nil,
                    let address = roomServiceCreationParameters.inviteThirdPartyIDs?.first?.address {
                    // Force this room to be direct for the invited 3pid, the matrix-ios-sdk don't do that by default for the moment.
                    self.createdRoom = room
                    room.setIsDirect(true, withUserId: address, success: {
                        if let roomID = self.createdRoom?.roomId {
                            completion(.success(roomID))
                        } else {
                            completion(.failure(RoomServiceError.directRoomCreationFailed))
                        }
                        self.createdRoom = nil
                    }, failure: { (error) in
                        MXLog.debug("[RoomService] setIsDirect failed")
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.failure(RoomServiceError.directRoomCreationFailed))
                        }
                        self.createdRoom = nil
                    })
                } else {
                    completion(.success(room.roomId))
                }
            case.failure(let error):
                completion(.failure(error))
            }
        })
    }
    
    static func defaultAliasName(for roomName: String) -> String {
        var alias = roomName.trimmingCharacters(in: .whitespacesAndNewlines).filter { "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".contains($0) }
        
        if alias.isEmpty {
            alias = randomString(length: 11)
        } else {
            alias.append(randomString(length: 11))
        }
        
        return alias
    }
    
    private static func randomString(length: Int) -> String {
        let letters = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890")
        return String((0..<length).map { _ in
            return letters.randomElement() ?? Character("A")
        })
    }
    
    private func historyVisibilityStateEvent(with historyVisibility: MXRoomHistoryVisibility) -> MXEvent {
        let stateEventJSON: [AnyHashable: Any] = [
            "state_key": "",
            "type": MXEventType.roomHistoryVisibility.identifier,
            "content": [
                "history_visibility": historyVisibility.identifier
            ]
        ]
        
        guard let stateEvent = MXEvent(fromJSON: stateEventJSON) else {
            fatalError("[RoomService] history event could not be created")
        }
        return stateEvent
    }
    
    private func roomAccessRulesStateEvent(with accessRule: RoomAccessRule) -> MXEvent {
        let stateEventJSON: [AnyHashable: Any] = [
            "state_key": "",
            "type": RoomService.roomAccessRulesStateEventType,
            "content": [
                RoomService.roomAccessRulesContentRuleKey: accessRule.identifier
            ]
        ]
        
        guard let stateEvent = MXEvent(fromJSON: stateEventJSON) else {
            fatalError("[RoomService] access rule event could not be created")
        }
        return stateEvent
    }
}
