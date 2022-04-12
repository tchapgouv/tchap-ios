/*
 Copyright 2020 New Vector Ltd
 
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

enum RoomAccessByLinkViewModelError: Error {
    case roomNotFound
    case unknown
}

final class RoomAccessByLinkViewModel: RoomAccessByLinkViewModelType {
    
    // MARK: - Constants
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let roomId: String
    private var isForum: Bool?
    private var viewState: RoomAccessByLinkViewState?
    private var liveTimeline: MXEventTimeline?
    private var isEditable = false
    private var roomStateListener: Any?
    
    let titleViewModel: RoomTitleViewModel
    
    // MARK: Public

    weak var viewDelegate: RoomAccessByLinkViewModelViewDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, roomId: String, isForum: Bool?) {
        self.session = session
        self.roomId = roomId
        self.isForum = isForum
        
        let avatarImageViewModel: AvatarImageViewModel?
        let roomTitleViewModelBuilder = RoomTitleViewModelBuilder(session: session)
        if let room = self.session.room(withRoomId: roomId), let summary = room.summary {
            let roomTitleViewModel = roomTitleViewModelBuilder.build(fromRoomSummary: summary)
            avatarImageViewModel = roomTitleViewModel.avatarImageViewModel
        } else {
            avatarImageViewModel = nil
        }
        self.titleViewModel = RoomTitleViewModel(title: TchapL10n.roomSettingsRoomAccessByLinkTitle,
                                                 roomTypeImage: nil,
                                                 roomTypeImageTintColor: nil,
                                                 subtitle: nil,
                                                 roomMembersCount: nil,
                                                 avatarImageViewModel: avatarImageViewModel)
    }
    
    // MARK: - Public
    
    func process(viewAction: RoomAccessByLinkViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .enable:
            self.enable()
        case .disable:
            self.disable()
        case .releaseData:
            self.releaseData()
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        guard let room = self.session.room(withRoomId: roomId) else {
            MXLog.debug("[RoomAccessByLinkViewModel] loadData: unknown room")
            self.update(viewState: .error(RoomAccessByLinkViewModelError.roomNotFound))
            return
        }
        
        self.update(viewState: .loading)
        
        // Check whether we have to retrieve the room directory visibility
        if self.isForum == nil {
            room.getDirectoryVisibility(completion: { [weak self] (response) in
                guard let self = self else {
                    return
                }
                
                switch response {
                case .success(let visibility):
                    self.isForum = visibility == .public
                case .failure/*(let error)*/:
                // Ignore this error. We will prevent the edition of the option
                    self.isForum = nil
                }
                
                self.loadRoomLiveTimeline(room: room)
            })
        } else {
            self.loadRoomLiveTimeline(room: room)
        }
    }
    
    private func loadRoomLiveTimeline(room: MXRoom) {
        room.liveTimeline({ [weak self]  (eventTimeline) in
            guard let self = self else {
                return
            }
            
            if let timeline = eventTimeline,
                let state = timeline.state {
                self.liveTimeline = timeline
                self.addRoomStateListener()
                self.updateRoomState(state)
            } else {
                MXLog.debug("[RoomAccessByLinkViewModel] loadRoomLiveTimeline: unknown error")
                self.update(viewState: .error(RoomAccessByLinkViewModelError.unknown))
            }
        })
    }
    
    private func updateRoomState(_ roomState: MXRoomState) {
        guard let powerLevels = roomState.powerLevels,
            let userId = session.myUser.userId else {
                MXLog.debug("[RoomAccessByLinkViewModel] updateRoomState: unknown error")
                self.update(viewState: .error(RoomAccessByLinkViewModelError.unknown))
                return
            }
        
        let oneSelfPowerLevel = powerLevels.powerLevelOfUser(withUserID: userId)
        let isAdmin = oneSelfPowerLevel >= RoomPowerLevel.admin.rawValue
        
        self.isEditable = isAdmin && (self.isForum != nil && self.isForum == false)
        if roomState.joinRule == .public {
            let link: String
            let isUnrestrictedRoom: Bool
            if let alias = roomState.canonicalAlias {
                link = Tools.permalink(toRoom: alias)
                if let room = self.session.room(withRoomId: roomId), let summary = room.summary {
                    if case RoomAccessRule.unrestricted = summary.tc_roomAccessRule() {
                        isUnrestrictedRoom = true
                    } else {
                        isUnrestrictedRoom = false
                    }
                } else {
                    isUnrestrictedRoom = false
                }
            } else {
                link = TchapL10n.roomSettingsRoomAccessByLinkInvalid
                isUnrestrictedRoom = false
            }
            self.update(viewState: .enabled(roomLink: link, editable: self.isEditable, isUnrestrictedRoom: isUnrestrictedRoom))
        } else {
            self.update(viewState: .disabled(editable: self.isEditable))
        }
    }
    
    private func disable() {
        guard let room = self.session.room(withRoomId: roomId)  else {
            MXLog.debug("[RoomAccessByLinkViewModel] disable: unknown room")
            self.update(viewState: .error(RoomAccessByLinkViewModelError.roomNotFound))
            return
        }
        
        self.removeRoomStateListener()
        self.update(viewState: .loading)
        room.setJoinRule(.invite) { (response) in
            switch response {
            case .success:
                self.update(viewState: .disabled(editable: self.isEditable))
            case .failure(let error):
                self.update(viewState: .error(error))
            }
            self.addRoomStateListener()
        }
    }
    
    private func enable() {
        guard let room = self.session.room(withRoomId: roomId)  else {
            MXLog.debug("[RoomAccessByLinkViewModel] enable: unknown room")
            self.update(viewState: .error(RoomAccessByLinkViewModelError.roomNotFound))
            return
        }
        
        self.removeRoomStateListener()
        self.update(viewState: .loading)
        self.forbidGuestAccessToEnableAccessByLink(room)
    }
    
    private func forbidGuestAccessToEnableAccessByLink(_ room: MXRoom) {
        guard let roomState = self.liveTimeline?.state else {
            MXLog.debug("[RoomAccessByLinkViewModel] forbidGuestAccessToEnableAccessByLink: no timeline")
            self.update(viewState: .error(RoomAccessByLinkViewModelError.unknown))
            return
        }
        
        if roomState.guestAccess != .forbidden {
            room.setGuestAccess(.forbidden) { (response) in
                switch response {
                case .success:
                    self.checkCanonicalAliasToEnableAccessByLink(room)
                case .failure(let error):
                    self.update(viewState: .error(error))
                }
            }
        } else {
            self.checkCanonicalAliasToEnableAccessByLink(room)
        }
    }
    
    private func checkCanonicalAliasToEnableAccessByLink(_ room: MXRoom) {
        guard let roomState = self.liveTimeline?.state else {
            MXLog.debug("[RoomAccessByLinkViewModel] checkCanonicalAliasToEnableAccessByLink: no timeline")
            self.update(viewState: .error(RoomAccessByLinkViewModelError.unknown))
            return
        }
        
        if roomState.canonicalAlias == nil || !MXTools.isMatrixRoomAlias(roomState.canonicalAlias) {
            if let matrixIDComponents = UserIDComponents(matrixID: session.myUserId) {
                let roomAlias = "#" + RoomService.defaultAliasName(for: roomState.name) + ":" + matrixIDComponents.hostName
                room.addAlias(roomAlias) { (response) in
                    switch response {
                    case .success:
                        room.setCanonicalAlias(roomAlias) { (response) in
                            switch response {
                            case .success:
                                self.enableAccessByLink(room)
                            case .failure(let error):
                                self.update(viewState: .error(error))
                            }
                        }
                    case .failure(let error):
                        self.update(viewState: .error(error))
                    }
                }
            } else {
                MXLog.debug("[RoomAccessByLinkViewModel] checkCanonicalAliasToEnableAccessByLink: failed to set room alias")
                self.update(viewState: .error(RoomAccessByLinkViewModelError.unknown))
            }
        } else {
            self.enableAccessByLink(room)
        }
    }
    
    private func enableAccessByLink(_ room: MXRoom) {
        guard let roomState = self.liveTimeline?.state else {
            MXLog.debug("[RoomAccessByLinkViewModel] enableAccessByLink: no timeline")
            self.update(viewState: .error(RoomAccessByLinkViewModelError.unknown))
            return
        }
        
        room.setJoinRule(.public) { (response) in
            let rule = room.summary.tc_roomAccessRule()
            switch response {
            case .success:
                let link: String = Tools.permalink(toRoom: roomState.canonicalAlias)
                let isUnrestrictedRoom: Bool
                if case .unrestricted = rule {
                    isUnrestrictedRoom = true
                } else {
                    isUnrestrictedRoom = false
                }
                self.update(viewState: .enabled(roomLink: link, editable: self.isEditable, isUnrestrictedRoom: isUnrestrictedRoom))
            case .failure(let error):
                if let mxError = MXError(nsError: error), mxError.errcode == kMXErrCodeStringForbidden, case .unrestricted = rule {
                    let customError = NSError(domain: "RoomAccessByLinkViewModelErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: TchapL10n.roomSettingsRoomAccessByLinkForbidden])
                    self.update(viewState: .error(customError))
                } else {
                    self.update(viewState: .error(error))
                }
            }
            self.addRoomStateListener()
        }
    }
    
    private func releaseData() {
        self.removeRoomStateListener()
    }
    
    private func update(viewState: RoomAccessByLinkViewState) {
        self.viewState = viewState
        self.viewDelegate?.roomAccessByLinkViewModel(self, didUpdateViewState: viewState)
    }
    
    private func addRoomStateListener() {
        guard let timeline = self.liveTimeline,
              let state = timeline.state else {
                  MXLog.debug("[RoomAccessByLinkViewModel] addRoomStateListener: no timeline")
                  return
              }
        self.roomStateListener = timeline.listenToEvents([.roomCanonicalAlias, .roomJoinRules], { (event, direction, roomState) in
            // Consider only live events
            if direction == .forwards {
                self.updateRoomState(state)
            }
        })
    }
    
    private func removeRoomStateListener() {
        guard let timeline = self.liveTimeline,
              let roomStateListener = self.roomStateListener as? MXEventListener else {
                  MXLog.debug("[RoomAccessByLinkViewModel] removeRoomListener: nothing to do")
                  return
              }
        timeline.remove(roomStateListener)
        self.roomStateListener = nil
    }
}
