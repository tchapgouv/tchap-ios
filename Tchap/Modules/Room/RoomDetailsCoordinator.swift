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

protocol RoomDetailsCoordinatorDelegate: class {
    func roomDetailsCoordinator(_ coordinator: RoomDetailsCoordinatorType, mention member: MXRoomMember)
    func roomDetailsCoordinator(_ coordinator: RoomDetailsCoordinatorType, didSelectRoomID roomID: String)
    func roomDetailsCoordinator(_ coordinator: RoomDetailsCoordinatorType, didSelectUserID userID: String)
}

final class RoomDetailsCoordinator: NSObject, RoomDetailsCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let router: NavigationRouterType
    private let session: MXSession
    private let roomID: String
    
    private let segmentedViewController: SegmentedViewController
    
    // MARK: Public
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: RoomDetailsCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(router: NavigationRouterType, session: MXSession, roomID: String) {
        self.router = router
        self.session = session
        self.roomID = roomID
        
        self.segmentedViewController = SegmentedViewController.instantiate()
    }
    
    // MARK: - Public methods
    
    func start() {
        guard let participantsViewController = RoomParticipantsViewController.instantiate(),
            let roomFilesViewController = RoomFilesViewController.instantiate(),
            let settingsViewController = RoomSettingsViewController.instantiate() else {
            fatalError("[RoomDetailsCoordinator] One tab could not be loaded")
        }
        
        let viewControllers = [participantsViewController, roomFilesViewController, settingsViewController]
        let titles = [TchapL10n.roomMembersTabTitle, TchapL10n.roomFilesTabTitle, TchapL10n.roomSettingsTabTitle]
        
        // members tab
        participantsViewController.delegate = self
        participantsViewController.enableMention = true
        participantsViewController.mxRoom = session.room(withRoomId: roomID)
        
        // Files tab
        // @TODO (async-state): This call should be synchronous. Every thing will be fine
        MXKRoomDataSource.load(withRoomId: self.roomID, andMatrixSession: self.session) { roomFilesDataSource in
            guard let roomFilesDataSource = roomFilesDataSource as? MXKRoomDataSource else {
                return
            }
            roomFilesDataSource.filterMessagesWithURL = true
            roomFilesDataSource.finalizeInitialization()
            // Give the data source ownership to the room files view controller.
            roomFilesViewController.hasRoomDataSourceOwnership = true
            roomFilesViewController.displayRoom(roomFilesDataSource)
        }
        
        // Settings tab
        settingsViewController.initWith(self.session, andRoomId: self.roomID)
        
        self.segmentedViewController.initWithTitles(titles, viewControllers: viewControllers, defaultSelected: 0)
        self.segmentedViewController.addMatrixSession(self.session)
        
        let titleView = RoomTitleView.instantiate()
        titleView?.mxRoom = session.room(withRoomId: roomID)
        self.segmentedViewController.navigationItem.titleView = titleView
        
    }
    
    func toPresentable() -> UIViewController {
        return self.segmentedViewController
    }
    
    // MARK: - Private methods
}

// MARK: - RoomParticipantsViewControllerDelegate
extension RoomDetailsCoordinator: RoomParticipantsViewControllerDelegate {
    func roomParticipantsViewController(_ roomParticipantsViewController: RoomParticipantsViewController!, mention member: MXRoomMember!) {
        self.delegate?.roomDetailsCoordinator(self, mention: member)
    }
    
    func roomParticipantsViewController(_ roomParticipantsViewController: RoomParticipantsViewController!, startChatWithMemberId matrixId: String!, completion: (() -> Void)?) {
        //TODO create a service to get the right discussion
        // call delegate ShowRoom or StartChat according to the result
        
        completion?()
    }
}
