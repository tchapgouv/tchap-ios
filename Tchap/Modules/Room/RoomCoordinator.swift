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
    func roomCoordinatorShowRoom(_ coordinator: RoomCoordinatorType, roomID: String)
    func roomCoordinatorStartChat(_ coordinator: RoomCoordinatorType, userID: String)
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
    private let roomsErrorPresenter: ErrorPresenter
    
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
        self.roomsErrorPresenter = AlertErrorPresenter(viewControllerPresenter: roomViewController)
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
}

// MARK: - RoomViewControllerDelegate
extension RoomCoordinator: RoomViewControllerDelegate {
    func roomViewControllerShowRoomDetails(_ roomViewController: RoomViewController!) {
        self.showRoomDetails(animated: true)
    }
    
    func roomViewController(_ roomViewController: RoomViewController!, showMemberDetails roomMember: MXRoomMember!) {
        self.showMemberDetails(roomMember, animated: true)
    }
}

// MARK: - RoomMemberDetailsViewControllerDelegate
extension RoomCoordinator: MXKRoomMemberDetailsViewControllerDelegate {
    func roomMemberDetailsViewController(_ roomMemberDetailsViewController: MXKRoomMemberDetailsViewController!, mention member: MXRoomMember!) {
        self.roomViewController.mention(member)
    }
    
    func roomMemberDetailsViewController(_ roomMemberDetailsViewController: MXKRoomMemberDetailsViewController!, startChatWithMemberId matrixId: String!, completion: (() -> Void)?) {
        //TODO create a service to get the right discussion
        // call delegate ShowRoom or StartChat according to the result
        
        completion?()
    }
}

// MARK: - RoomDetailsCoordinatorDelegate
extension RoomCoordinator: RoomDetailsCoordinatorDelegate {
    func roomDetailsCoordinatorMentionMember(_ coordinator: RoomDetailsCoordinatorType, roomMember: MXRoomMember) {
        self.roomViewController.mention(roomMember)
    }
    
    func roomDetailsCoordinatorShowRoom(_ coordinator: RoomDetailsCoordinatorType, roomID: String) {
        self.delegate?.roomCoordinatorShowRoom(self, roomID: roomID)
    }
    
    func roomDetailsCoordinatorStartChat(_ coordinator: RoomDetailsCoordinatorType, userID: String) {
        self.delegate?.roomCoordinatorStartChat(self, userID: userID)
    }
}
