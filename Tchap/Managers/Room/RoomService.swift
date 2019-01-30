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
private struct RoomCreationParameters {
    let visibility: MXRoomDirectoryVisibility
    let preset: MXRoomPreset
    let name: String
    let alias: String?
    let inviteUserIDs: [String]
    let isFederated: Bool
    let historyVisibility: String?
}

enum RoomServiceError: Error {
    case invalidAvatarURL
}

/// `RoomService` implementation of `RoomServiceType` is used to perform room operations.
final class RoomService: RoomServiceType {
    
    // MARK: - Properties
    
    private let session: MXSession
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
    }
    
    // MARK: - Public
    
    func createRoom(visibility: MXRoomDirectoryVisibility, name: String, avatarURL: String?, inviteUserIds: [String], isFederated: Bool) -> Single<MXCreateRoomResponse> {
        return self.createRoom(visibility: visibility, name: name, inviteUserIds: inviteUserIds, isFederated: isFederated)
        .flatMap { createRoomResponse in
            guard let roomId = createRoomResponse.roomId, let avatarURL = avatarURL else {
                return Single.just(createRoomResponse)
            }
            
            return self.setAvatar(with: avatarURL, for: roomId)
            .map {
                return createRoomResponse
            }
        }
    }
    
    func setAvatar(with url: String, for roomId: String) -> Single<Void> {
        guard let avatarUrl = URL(string: url) else {
            return Single.error(RoomServiceError.invalidAvatarURL)
        }
        
        return Single.create { (single) -> Disposable in
            let httpOperation = self.session.matrixRestClient.setAvatar(ofRoom: roomId, avatarUrl: avatarUrl) { (response) in
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
    
    // MARK: - Private
    
    private func createRoom(visibility: MXRoomDirectoryVisibility, name: String, inviteUserIds: [String], isFederated: Bool) -> Single<MXCreateRoomResponse> {
        
        return Single.create { (single) -> Disposable in
            let httpOperation = self.createRoom(visibility: visibility, name: name, inviteUserIds: inviteUserIds, isFederated: isFederated) { (response) in
                switch response {
                case .success(let createRoomResponse):
                    single(.success(createRoomResponse))
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
    
    private func createRoom(visibility: MXRoomDirectoryVisibility, name: String, inviteUserIds: [String], isFederated: Bool, completion: @escaping (MXResponse<MXCreateRoomResponse>) -> Void) -> MXHTTPOperation {
        
        let preset: MXRoomPreset
        let historyVisibility: String?
        let alias: String?
        
        if visibility == .public {
            preset = .publicChat
            historyVisibility = kMXRoomHistoryVisibilityWorldReadable
            // In case of a public room, the room alias is mandatory.
            // That's why, we deduce the room alias from the room name.
            alias = self.defaultAlias(for: name)
        } else {
            preset = .privateChat
            historyVisibility = nil
            alias = nil
        }
        
        let roomCreationParameters = RoomCreationParameters(visibility: visibility,
                                                            preset: preset,
                                                            name: name,
                                                            alias: alias,
                                                            inviteUserIDs: inviteUserIds,
                                                            isFederated: isFederated,
                                                            historyVisibility: historyVisibility)
        
        return self.createRoom(with: roomCreationParameters, completion: completion)
    }
    
    private func createRoom(with roomCreationParameters: RoomCreationParameters, completion: @escaping (MXResponse<MXCreateRoomResponse>) -> Void) -> MXHTTPOperation {
        
        var parameters: [String: Any] = [:]
        
        parameters["name"] = roomCreationParameters.name
        
        parameters["visibility"] = roomCreationParameters.visibility.identifier
        
        if let alias = roomCreationParameters.alias {
            parameters["room_alias_name"] = alias
        }
        
        parameters["invite"] = roomCreationParameters.inviteUserIDs
        parameters["preset"] = roomCreationParameters.preset.identifier
        
        if roomCreationParameters.isFederated == false {
            parameters["creation_content"] = [ "m.federate": false ]
        }
        
        var initialStates: Array<[AnyHashable: Any]> = []
        
        if let historyVisibility = roomCreationParameters.historyVisibility {
            let historyVisibilityStateEvent = self.historyVisibilityStateEvent(with: historyVisibility)
            initialStates.append(historyVisibilityStateEvent.jsonDictionary())
        }
        
        if initialStates.isEmpty == false {
            parameters["initial_state"] = initialStates
        }
        
        return self.session.matrixRestClient.createRoom(parameters: parameters, completion: completion)
    }
    
    private func historyVisibilityStateEvent(with historyVisibility: String) -> MXEvent {
        
        let stateEventJSON: [AnyHashable: Any] = [
            "state_key": "",
            "type": MXEventType.roomHistoryVisibility.identifier,
            "content": [
                "history_visibility": historyVisibility
            ]
        ]
        
        guard let stateEvent = MXEvent(fromJSON: stateEventJSON) else {
            fatalError("[RoomService] history event could not be created")
        }
        return stateEvent
    }
    
    private func defaultAlias(for roomName: String) -> String {
        var alias = roomName.trimmingCharacters(in: .whitespacesAndNewlines).filter { "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".contains($0) }
        
        if alias.isEmpty {
            alias = self.randomString(length: 7)
        } else {
            alias.append(self.randomString(length: 7))
        }
        
        return alias
    }
    
    private func randomString(length: Int) -> String {
        let letters = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890")
        return String((0..<length).map { _ in
            return letters.randomElement() ?? Character("A")
        })
    }
}
