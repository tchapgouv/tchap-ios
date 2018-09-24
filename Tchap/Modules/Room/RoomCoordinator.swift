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

protocol RoomCoordinatorDelegate: class {
    func roomCoordinator(_ coordinator: RoomCoordinatorType, didSelectRoomID roomID: String)
    func roomCoordinator(_ coordinator: RoomCoordinatorType, didSelectUserID userID: String)
}

final class RoomCoordinator: NSObject, RoomCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let router: NavigationRouterType
    private let session: MXSession
    private let roomID: String
    
    private let roomViewController: RoomViewController
    private var roomDataSource: RoomDataSource?
    private let activityIndicatorPresenter: ActivityIndicatorPresenterType
    private let errorPresenter: ErrorPresenter
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: RoomCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(router: NavigationRouterType, session: MXSession, roomID: String) {
        self.router = router
        self.session = session
        self.roomID = roomID
        self.roomViewController = RoomViewController.instantiate()
        self.activityIndicatorPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = AlertErrorPresenter(viewControllerPresenter: roomViewController)
    }
    
    // MARK: - Public methods
    
    func start() {
        self.roomViewController.delegate = self
        
        // Present activity indicator when retrieving roomDataSource for given room ID
        self.activityIndicatorPresenter.presentActivityIndicator(on: roomViewController.view, animated: false)
        
        let roomDataSourceManager: MXKRoomDataSourceManager = MXKRoomDataSourceManager.sharedManager(forMatrixSession: self.session)
        roomDataSourceManager.roomDataSource(forRoom: self.roomID, create: true, onComplete: { (roomDataSource) in
            
            self.activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
            
            if let roomDataSource = roomDataSource {
                self.roomViewController.displayRoom(roomDataSource)
            }
        })
    }
    
    func toPresentable() -> UIViewController {
        return self.roomViewController
    }
    
    // MARK: - Private methods
    
    private func showRoomDetails(animated: Bool) {
        let roomDetailsCoordinator = RoomDetailsCoordinator.init(router: self.router, session: self.session, roomID: self.roomID)
        roomDetailsCoordinator.start()
        roomDetailsCoordinator.delegate = self
        self.add(childCoordinator: roomDetailsCoordinator)
        
        self.roomViewController.tc_removeBackTitle()
        
        self.router.push(roomDetailsCoordinator, animated: animated, popCompletion: {
            self.remove(childCoordinator: roomDetailsCoordinator)
        })
    }
    
    private func showMemberDetails(_ member: MXRoomMember, animated: Bool) {
        guard let roomMemberDetailsViewController = RoomMemberDetailsViewController.instantiate() else {
            fatalError("[RoomCoordinator] Member details can not be loaded")
        }
        // Set delegate to handle action on member (start chat, mention)
        roomMemberDetailsViewController.delegate = self
        roomMemberDetailsViewController.enableMention = (self.roomViewController.inputToolbarView != nil)
        roomMemberDetailsViewController.enableVoipCall = false
        
        roomMemberDetailsViewController.display(member, withMatrixRoom: session.room(withRoomId: self.roomID))
        
        self.roomViewController.tc_removeBackTitle()
        
        self.router.push(roomMemberDetailsViewController, animated: animated, popCompletion: nil)
    }
    
    private func didSelectUserID(_ userID: String, completion: (() -> Void)?) {
        self.activityIndicatorPresenter.presentActivityIndicator(on: self.roomViewController.view, animated: true)
        
        let discussionService = DiscussionService(session: session)
        discussionService.getDiscussionIdentifier(for: userID) { [weak self] response in
            guard let sself = self else {
                return
            }
            
            sself.activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
            
            switch response {
            case .success(let result):
                switch result {
                case .joinedDiscussion(let roomID):
                    // Open the current discussion
                    sself.delegate?.roomCoordinator(sself, didSelectRoomID: roomID)
                case .noDiscussion:
                    // Let the delegate handle this user for who no discussion exists.
                    sself.delegate?.roomCoordinator(sself, didSelectUserID: userID)
                default:
                    break
                }
            case .failure(let error):
                let errorPresentable = sself.openDiscussionErrorPresentable(from: error)
                sself.errorPresenter.present(errorPresentable: errorPresentable, animated: true)
            }
            
            completion?()
        }
    }
    
    private func openDiscussionErrorPresentable(from error: Error) -> ErrorPresentable {
        let errorTitle: String = TchapL10n.errorTitleDefault
        let errorMessage: String
        
        let nsError = error as NSError
        
        if let message = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
            errorMessage = message
        } else {
            errorMessage = TchapL10n.errorMessageDefault
        }
        
        return ErrorPresentableImpl(title: errorTitle, message: errorMessage)
    }
}

// MARK: - RoomViewControllerDelegate
extension RoomCoordinator: RoomViewControllerDelegate {
    func roomViewControllerShowRoomDetails(_ roomViewController: RoomViewController!) {
        self.showRoomDetails(animated: true)
    }
    
    func roomViewController(_ roomViewController: RoomViewController!, showMemberDetails roomMember: MXRoomMember!) {
        self.showMemberDetails(roomMember, animated: true)
    }
    
    func roomViewController(_ roomViewController: RoomViewController!, showRoom roomID: String!) {
        self.delegate?.roomCoordinator(self, didSelectRoomID: roomID)
    }
}

// MARK: - RoomMemberDetailsViewControllerDelegate
extension RoomCoordinator: MXKRoomMemberDetailsViewControllerDelegate {
    func roomMemberDetailsViewController(_ roomMemberDetailsViewController: MXKRoomMemberDetailsViewController!, mention member: MXRoomMember!) {
        self.roomViewController.mention(member)
    }
    
    func roomMemberDetailsViewController(_ roomMemberDetailsViewController: MXKRoomMemberDetailsViewController!, startChatWithMemberId matrixId: String!, completion: (() -> Void)?) {
        self.didSelectUserID(matrixId, completion: completion)
    }
}

// MARK: - RoomDetailsCoordinatorDelegate
extension RoomCoordinator: RoomDetailsCoordinatorDelegate {
    func roomDetailsCoordinator(_ coordinator: RoomDetailsCoordinatorType, mention member: MXRoomMember) {
        self.roomViewController.mention(member)
    }
    
    func roomDetailsCoordinator(_ coordinator: RoomDetailsCoordinatorType, didSelectRoomID roomID: String) {
        self.delegate?.roomCoordinator(self, didSelectRoomID: roomID)
    }
    
    func roomDetailsCoordinator(_ coordinator: RoomDetailsCoordinatorType, didSelectUserID userID: String) {
        self.delegate?.roomCoordinator(self, didSelectUserID: userID)
    }
}
