/*
 Copyright 2019 New Vector Ltd
 
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

final class DiscussionDetailsCoordinator: NSObject, RoomDetailsCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let router: NavigationRouterType
    private let session: MXSession
    private let roomID: String
    
    private let memberDetailsViewController: RoomMemberDetailsViewController
    
    // MARK: Public
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    init(router: NavigationRouterType, session: MXSession, roomID: String) {
        self.router = router
        self.session = session
        self.roomID = roomID
        
        self.memberDetailsViewController = RoomMemberDetailsViewController.instantiate()
    }
    
    // MARK: - Public methods
    
    func start() {
        self.updateMemberDetails()
        self.registerRoomSummaryDidChangeNotification()
    }
    
    func toPresentable() -> UIViewController {
        return self.memberDetailsViewController
    }
    
    // MARK: - Private methods
    
    private func registerRoomSummaryDidChangeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(roomSummaryDidChange(notification:)), name: NSNotification.Name.mxRoomSummaryDidChange, object: nil)
    }
    
    @objc private func roomSummaryDidChange(notification: Notification) {
        guard let roomSummary = notification.object as? MXRoomSummary else {
            return
        }
        if roomSummary.roomId == roomID {
            self.updateMemberDetails()
        }
    }
    
    private func updateMemberDetails() {
        guard let room = session.room(withRoomId: roomID), let directUserID = room.directUserId else {
            return
        }
        
        room.members({ (roomMembers) in
            if let roomMembers = roomMembers, let member = roomMembers.member(withUserId: directUserID) {
                self.memberDetailsViewController.display(member, withMatrixRoom: room)
            }
        }, lazyLoadedMembers: { (roomMembers) in
            if let roomMembers = roomMembers, let member = roomMembers.member(withUserId: directUserID) {
                self.memberDetailsViewController.display(member, withMatrixRoom: room)
            }
        }, failure: { _ in })
    }
}
