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

protocol RoomsCoordinatorDelegate: class {
    func roomsCoordinator(_ coordinator: RoomsCoordinatorType, didSelectRoomID roomID: String)
}

final class RoomsCoordinator: NSObject, RoomsCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let router: NavigationRouterType
    private let session: MXSession
    
    private let roomsViewController: RoomsViewController
    private let roomsDataSource: RoomsDataSource
    private let activityIndicatorPresenter: ActivityIndicatorPresenterType
    private let roomsErrorPresenter: ErrorPresenter
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: RoomsCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(router: NavigationRouterType, session: MXSession) {
        self.router = router
        self.session = session
        self.roomsViewController = RoomsViewController.instantiate()
        self.roomsDataSource = RoomsDataSource(matrixSession: self.session)
        self.roomsDataSource.finalizeInitialization()
        self.activityIndicatorPresenter = ActivityIndicatorPresenter()
        self.roomsErrorPresenter = AlertErrorPresenter(viewControllerPresenter: roomsViewController)
    }
    
    // MARK: - Public methods
    
    func start() {
        self.roomsViewController.displayList(self.roomsDataSource)
        self.roomsViewController.roomsViewControllerDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.roomsViewController
    }
    
    func updateSearchText(_ searchText: String?) {
        let pattern: [String]?
        if let searchText = searchText, !searchText.isEmpty {
            pattern = [searchText]
        } else {
            pattern = nil
        }
        self.roomsDataSource.search(withPatterns: pattern)
    }
    
    func scrollToRoom(with roomID: String, animated: Bool) {
        if let indexPath = self.roomsDataSource.cellIndexPath(withRoomId: roomID, andMatrixSession: self.session) {
            self.roomsViewController.recentsTableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.top, animated: animated)
        }
    }
    
    // MARK: - Private methods
    
    private func joinRoom(with roomID: String) {
        self.activityIndicatorPresenter.presentActivityIndicator(on: self.roomsViewController.view, animated: true)
        
        joinRoomByHandlingThirdPartyInvite(roomID: roomID) { [weak self] (response) in
            guard let sself = self else {
                return
            }
            
            sself.activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
            switch response {
            case .success:
                sself.delegate?.roomsCoordinator(sself, didSelectRoomID: roomID)
            case .failure(let error):
                let errorPresentable = sself.joinRoomErrorPresentable(from: error)
                sself.roomsErrorPresenter.present(errorPresentable: errorPresentable, animated: true)
            }
        }
    }
    
    private func joinRoomByHandlingThirdPartyInvite(roomID: String, completion: @escaping (MXResponse<MXRoom>) -> Void) {
        // When the user is invited by his email to a direct chat, the pending invite is not mark as direct by the SDK.
        // We will do that after joining the room according to the room access rule (available in the room state).
        // We check before joining the room if a third party invite has been accepted by the tchap user
        // (Do it before joining the room because the room state will be updated during the operation).
        // The invite sender will be used if the room is a direct chat.
        getPotentialThirdPartyInviteSenderID(roomID: roomID) { [weak self] (response) in
            guard let self = self else {
                return
            }
            
            let thirdPartyInviteSenderID: String?
            switch response {
            case .success(let userID):
                thirdPartyInviteSenderID = userID
            case .failure:
                thirdPartyInviteSenderID = nil
            }
            
            // Join now the wanted room
            self.session.joinRoom(roomID) { [weak self] (response) in
                guard let self = self else {
                    return
                }
                
                switch response {
                case .success(let room):
                    // Check whether we have to consider potentially this room as a direct.
                    if thirdPartyInviteSenderID != nil {
                        // Check the room access rule.
                        let rule = room.summary.tc_roomAccessRule()
                        if case RoomAccessRule.direct = rule {
                            // This new joined room is a direct one.
                            // Mark it as direct if this is not already done
                            if room.isDirect == false {
                                self.session.setRoom(roomID, directWithUserId: thirdPartyInviteSenderID, success: {
                                    NSLog("[RoomsCoordinator] joinRoomByHandlingThirdPartyInvite succeeded to mark direct this new joined room")
                                }, failure: { _ in
                                    NSLog("[RoomsCoordinator] joinRoomByHandlingThirdPartyInvite failed to mark direct this new joined room")
                                })
                            }
                        }
                    }
                    completion(.success(room))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Check in the room state if a third party invite has been accepted by the tchap user.
    /// The response provides on success the Matrix user id of the invite sender (or `nil` if this is not third party invite).
    private func getPotentialThirdPartyInviteSenderID(roomID: String, completion: @escaping (MXResponse<String?>) -> Void) {
        if let room = self.session.room(withRoomId: roomID) {
            let userID = self.session.myUser.userId
            
            // Note: We don't use here `room.members` because of https://github.com/matrix-org/synapse/issues/4985
            room.liveTimeline { (eventTimeline) in
                if let roomMembers = eventTimeline?.state.members,
                    let roomMember = roomMembers.member(withUserId: userID),
                    roomMember.thirdPartyInviteToken != nil {
                    NSLog("[RoomsCoordinator] getPotentialThirdPartyInviteSenderID: The current user has accepted a third party invite for this room")
                    completion(.success(roomMember.originalEvent.sender))
                } else {
                    completion(.success(nil))
                }
            }
        } else {
            // The session doesn't know this room, the current user has not been invited.
            completion(.success(nil))
        }
    }
    
    private func joinRoomErrorPresentable(from error: Error) -> ErrorPresentable {
        let errorTitle: String = Bundle.mxk_localizedString(forKey: "room_error_join_failed_title")
        let errorMessage: String
        
        let nsError = error as NSError
        
        if let message = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
            
            if message == "No known servers" {
                // minging kludge until https://matrix.org/jira/browse/SYN-678 is fixed
                // 'Error when trying to join an empty room should be more explicit'
                errorMessage = Bundle.mxk_localizedString(forKey: "room_error_join_failed_empty_room")
            } else {
                errorMessage = message
            }
        } else {
            errorMessage = TchapL10n.errorMessageDefault
        }
        
        return ErrorPresentableImpl(title: errorTitle, message: errorMessage)
    }
}

// MARK: - RoomsViewControllerDelegate
extension RoomsCoordinator: RoomsViewControllerDelegate {
    
    func roomsViewController(_ roomsViewController: RoomsViewController!, didSelectRoomWithID roomID: String!) {
        self.delegate?.roomsCoordinator(self, didSelectRoomID: roomID)
    }
    
    func roomsViewController(_ roomsViewController: RoomsViewController!, didAcceptRoomInviteWithRoomID roomID: String!) {
        self.joinRoom(with: roomID)
    }
}
