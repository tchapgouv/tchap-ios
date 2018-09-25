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

protocol RoomPreviewCoordinatorDelegate: class {
    func roomPreviewCoordinatorDidCancel(_ coordinator: RoomPreviewCoordinatorType)
    func roomPreviewCoordinator(_ coordinator: RoomPreviewCoordinatorType, didJoinRoomWithId roomID: String, onEventId evenId: String?)
}

final class RoomPreviewCoordinator: NSObject, RoomPreviewCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let publicRoom: MXPublicRoom
    
    private let roomViewController: RoomViewController
    private let activityIndicatorPresenter: ActivityIndicatorPresenterType
    private let roomsErrorPresenter: ErrorPresenter
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: RoomPreviewCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, publicRoom: MXPublicRoom) {
        self.session = session
        self.publicRoom = publicRoom
        
        self.roomViewController = RoomViewController.instantiate()
        self.activityIndicatorPresenter = ActivityIndicatorPresenter()
        self.roomsErrorPresenter = AlertErrorPresenter(viewControllerPresenter: roomViewController)
        
        super.init()
    }
    
    // MARK: - Public methods
    
    func start() {
        self.roomViewController.tc_removeBackTitle()
        
        let roomPreviewData: RoomPreviewData
        
        if publicRoom.worldReadable {
            roomPreviewData = RoomPreviewData(roomId: publicRoom.roomId, andSession: self.session)
            
            // Try to get more information about the room before opening its preview
            roomPreviewData.peek(inRoom: { [weak self] succeeded in
                if succeeded {
                    self?.roomViewController.displayRoomPreview(roomPreviewData)
                }
            })
        } else {
            roomPreviewData = RoomPreviewData(publicRoom: publicRoom, andSession: self.session)
        }
        
        self.roomViewController.displayRoomPreview(roomPreviewData)
        self.roomViewController.delegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.roomViewController.toPresentable()
    }
    
    // MARK: - Private methods
    
    private func didCancel() {
        self.delegate?.roomPreviewCoordinatorDidCancel(self)
    }
    
    private func joinRoom(with roomPreviewData: RoomPreviewData) {
        
        let roomIdOrAlias: String
        let eventId = roomPreviewData.eventId
        let signURL: URL?
        
        // We promote here join by room alias instead of room id when an alias is available, in order to handle federated room.
        if let firstRoomAlias = roomPreviewData.roomAliases.first {
            roomIdOrAlias = firstRoomAlias
        } else {
            roomIdOrAlias = roomPreviewData.roomId
        }
        
        // Note in case of simple link to a room the signUrl param is nil
        if let signUrlString = roomPreviewData.emailInvitation?.signUrl {
            signURL = URL(string: signUrlString)
        } else {
            signURL = nil
        }
        
        self.activityIndicatorPresenter.presentActivityIndicator(on: roomViewController.view, animated: false)
        
        self.session.joinRoom(roomIdOrAlias, withSignUrl: signURL) { [weak self] response in
            guard let sself = self else {
                return
            }
            
            sself.activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
            
            switch response {
            case .success(let room):
                sself.delegate?.roomPreviewCoordinator(sself, didJoinRoomWithId: room.roomId, onEventId: eventId)
            case .failure(let error):
                let errorPresentable = sself.joinRoomErrorPresentable(from: error)
                sself.roomsErrorPresenter.present(errorPresentable: errorPresentable)
            }
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

// MARK: - RoomViewControllerDelegate
extension RoomPreviewCoordinator: RoomViewControllerDelegate {
    
    func roomViewControllerShowRoomDetails(_ roomViewController: RoomViewController!) {
    }
    
    func roomViewController(_ roomViewController: RoomViewController!, showMemberDetails roomMember: MXRoomMember!) {
    }
    
    func roomViewController(_ roomViewController: RoomViewController!, showRoom roomID: String!) {
    }
    
    func roomViewControllerPreviewDidTapJoin(_ roomViewController: RoomViewController!) {
        guard let roomPreviewData = roomViewController.roomPreviewData else {
            return
        }
        self.joinRoom(with: roomPreviewData)
    }
    
    func roomViewControllerPreviewDidTapCancel(_ roomViewController: RoomViewController!) {
        self.didCancel()
    }
}
