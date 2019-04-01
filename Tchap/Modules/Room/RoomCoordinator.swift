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
    func roomCoordinator(_ coordinator: RoomCoordinatorType, didSelectUserID userID: String)
    func roomCoordinator(_ coordinator: RoomCoordinatorType, didSelectRoomID roomID: String)
}

final class RoomCoordinator: NSObject, RoomCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let router: NavigationRouterType
    private let session: MXSession
    private let roomID: String?
    private let eventID: String?
    private let discussionTargetUserID: String?
    
    private let userService: UserServiceType
    private var foundDiscussionTargetUser: User?
    private let roomViewController: RoomViewController
    private var roomDataSource: RoomDataSource?
    private let activityIndicatorPresenter: ActivityIndicatorPresenterType
    private let errorPresenter: ErrorPresenter
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: RoomCoordinatorDelegate?
    
    // MARK: - Setup
    
    /// Used to present a room with known room
    convenience init(router: NavigationRouterType, session: MXSession, roomID: String, eventID: String?) {
        self.init(router: router, session: session, roomID: roomID, eventID: eventID, discussionTargetUserID: nil)
    }
    
    /// Used to present a room for a discussion with a target user
    convenience init(router: NavigationRouterType, session: MXSession, discussionTargetUserID: String) {
        self.init(router: router, session: session, roomID: nil, eventID: nil, discussionTargetUserID: discussionTargetUserID)
    }
    
    private init(router: NavigationRouterType, session: MXSession, roomID: String?, eventID: String?, discussionTargetUserID: String?) {
        self.router = router
        self.session = session
        self.roomID = roomID
        self.eventID = eventID
        self.discussionTargetUserID = discussionTargetUserID
        
        let userService = UserService(session: self.session)
        
        if let discussionTargetUserID = discussionTargetUserID {
            let discussionTargetUser: User
            
            // Try to find user in local session
            if let userFromSession = userService.getUserFromLocalSession(with: discussionTargetUserID) {
                discussionTargetUser = userFromSession
                self.foundDiscussionTargetUser = userFromSession
            } else {
                discussionTargetUser = userService.buildTemporaryUser(from: discussionTargetUserID)
            }
            
            // Use target user information to populate RoomViewController view
            self.roomViewController = RoomViewController.instantiate(withDiscussionTargetUser: discussionTargetUser, session: session)
        } else {
            self.roomViewController = RoomViewController.instantiate()
        }
        
        self.userService = userService
        self.activityIndicatorPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = AlertErrorPresenter(viewControllerPresenter: roomViewController)
    }
    
    // MARK: - Public methods
    
    func start() {
        self.roomViewController.delegate = self
        
        if let roomID = self.roomID {
            // Start flow for a known room
            self.start(with: roomID, eventID: self.eventID)
        } else if let discussionTargetUserID = self.discussionTargetUserID {
            // Start flow for a direct chat, try to find an existing room with target user
            self.start(with: discussionTargetUserID)
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.roomViewController
    }
    
    // MARK: - Private methods
    
    private func start(with roomID: String, eventID: String?) {
        
        // Present activity indicator when retrieving roomDataSource for given room ID
        self.activityIndicatorPresenter.presentActivityIndicator(on: roomViewController.view, animated: false)
        
        if let eventId = self.eventID {
            RoomDataSource.load(withRoomId: roomID, initialEventId: eventId, andMatrixSession: self.session) { (dataSource) in
                
                self.activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
                
                guard let roomDataSource = dataSource as? RoomDataSource else {
                    return
                }
                roomDataSource.markTimelineInitialEvent = true
                self.roomViewController.displayRoom(roomDataSource)
                self.roomViewController.hasRoomDataSourceOwnership = true
            }
        } else {
            let roomDataSourceManager: MXKRoomDataSourceManager = MXKRoomDataSourceManager.sharedManager(forMatrixSession: self.session)
            roomDataSourceManager.roomDataSource(forRoom: roomID, create: true, onComplete: { (roomDataSource) in
                
                self.activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
                
                if let roomDataSource = roomDataSource {
                    self.roomViewController.displayRoom(roomDataSource)
                }
            })
        }
    }
    
    private func start(with discussionTargetUserID: String) {
        
        // Hide input tool bar during find discussion process and show it again only in case on success. Avoid possibility to send text if a discussion fails to be initiated.
        self.roomViewController.forceHideInputToolBar = true
        self.activityIndicatorPresenter.presentActivityIndicator(on: roomViewController.view, animated: false)
        
        let removeActivityIndicator: (() -> Void) = {
            self.activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
        }
        
        let discussionFinder = DiscussionFinder(session: session)
        
        // Try to find an existing room with target user otherwise start a new discussion
        discussionFinder.getDiscussionIdentifier(for: discussionTargetUserID) { [weak self] response in
            guard let sself = self else {
                return
            }

            switch response {
            case .success(let result):
                switch result {
                case .joinedDiscussion(let roomID):
                    // Open the found discussion
                    removeActivityIndicator()
                    sself.roomViewController.forceHideInputToolBar = false
                    sself.start(with: roomID, eventID: nil)
                case .noDiscussion:
                    // Start a new discussion

                    // Try to search target user if not exist in local session
                    if let discussionTargetUserID = sself.discussionTargetUserID, sself.foundDiscussionTargetUser == nil {

                        sself.userService.findUser(with: discussionTargetUserID) { [weak self] (user) in
                            guard let sself = self else {
                                return
                            }

                            removeActivityIndicator()
                            sself.roomViewController.forceHideInputToolBar = false

                            if let user = user {
                                sself.foundDiscussionTargetUser = user
                                // Update RoomViewController with found target user
                                sself.roomViewController.displayNewDiscussion(withTargetUser: user, session: sself.session)
                            }
                        }
                    } else {
                        // User has already been found from local session no update needed
                        removeActivityIndicator()
                        sself.roomViewController.forceHideInputToolBar = false
                    }
                default:
                    removeActivityIndicator()
                }
            case .failure(let error):
                removeActivityIndicator()
                let errorPresentable = sself.openDiscussionErrorPresentable(from: error)
                sself.errorPresenter.present(errorPresentable: errorPresentable, animated: true)
            }
        }
    }
    
    private func currentRoomID() -> String? {
        let currentRoomID: String?
        
        if let roomID = self.roomID {
            currentRoomID = roomID
        } else if let roomDataSource = self.roomViewController.roomDataSource, let roomID = roomDataSource.roomId {
            // Handle case when create a new discussion without room and then room is created after sending first message
            currentRoomID = roomID
        } else {
            currentRoomID = nil
        }
        
        return currentRoomID
    }
    
    private func showRoomDetails(animated: Bool) {
        guard let roomID = self.currentRoomID() else {
            return
        }
        
        let roomDetailsCoordinator = RoomDetailsCoordinator(router: self.router, session: self.session, roomID: roomID)
        roomDetailsCoordinator.start()
        roomDetailsCoordinator.delegate = self
        self.add(childCoordinator: roomDetailsCoordinator)
        
        self.roomViewController.tc_removeBackTitle()
        
        self.router.push(roomDetailsCoordinator, animated: animated, popCompletion: { [weak self] in
            self?.remove(childCoordinator: roomDetailsCoordinator)
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
        self.delegate?.roomCoordinator(self, didSelectUserID: userID)
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
    
    func roomViewControllerShowRoomDetails(_ roomViewController: RoomViewController) {
        self.showRoomDetails(animated: true)
    }
    
    func roomViewController(_ roomViewController: RoomViewController, showMemberDetails roomMember: MXRoomMember) {
        self.showMemberDetails(roomMember, animated: true)
    }
    
    func roomViewController(_ roomViewController: RoomViewController, showRoom roomID: String) {
        self.delegate?.roomCoordinator(self, didSelectRoomID: roomID)
    }
    
    func roomViewControllerPreviewDidTapJoin(_ roomViewController: RoomViewController) {
    }
    
    func roomViewControllerPreviewDidTapCancel(_ roomViewController: RoomViewController) {
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
