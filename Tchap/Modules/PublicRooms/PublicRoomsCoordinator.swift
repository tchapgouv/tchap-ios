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

protocol PublicRoomsCoordinatorDelegate: class {
    func publicRoomsCoordinatorDidCancel(_ publicRoomsCoordinator: PublicRoomsCoordinator)
    func publicRoomsCoordinator(_ publicRoomsCoordinator: PublicRoomsCoordinator, showRoomWithId roomId: String, onEventId eventId: String?)
}

final class PublicRoomsCoordinator: NSObject, PublicRoomsCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let router: NavigationRouterType
    private let session: MXSession
    
    private let publicRoomsViewController: PublicRoomsViewController
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: PublicRoomsCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.router = NavigationRouter(navigationController: TCNavigationController())
        self.session = session
        
        let publicRoomServers = PublicRoomsCoordinator.getPublicRoomServers()
        let publicRoomService = PublicRoomService(homeServersStringURL: publicRoomServers, session: self.session)
        let publicRoomDataSource = PublicRoomsDataSource(session: self.session, publicRoomService: publicRoomService)
        let publicRoomsViewController = PublicRoomsViewController.instantiate(dataSource: publicRoomDataSource)
        self.publicRoomsViewController = publicRoomsViewController
        
        super.init()
    }
    
    // MARK: - Public methods
    
    func start() {
        self.publicRoomsViewController.tc_removeBackTitle()
        self.router.setRootModule(self.publicRoomsViewController)
        self.publicRoomsViewController.delegate = self
        
        self.publicRoomsViewController.navigationItem.leftBarButtonItem = MXKBarButtonItem(title: TchapL10n.actionCancel, style: .plain) { [weak self] in
            self?.didCancel()
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.router.toPresentable()
    }
    
    // MARK: - Private methods
    
    private func didCancel() {
        self.delegate?.publicRoomsCoordinatorDidCancel(self)
    }
    
    private static func getPublicRoomServers() -> [String] {
        guard let publicRoomServers = UserDefaults.standard.stringArray(forKey: "roomDirectoryServers") else {
            return []
        }        
        return publicRoomServers
    }
    
    private func showRoomPreview(with publicRoom: MXPublicRoom) {
        let roomPreviewCoordinator = RoomPreviewCoordinator(session: self.session, publicRoom: publicRoom)
        roomPreviewCoordinator.start()
        roomPreviewCoordinator.delegate = self
        
        self.add(childCoordinator: roomPreviewCoordinator)
        
        self.router.push(roomPreviewCoordinator, animated: true) { [weak self] in
            self?.remove(childCoordinator: roomPreviewCoordinator)
        }
    }
}

// MARK: - PublicRoomsViewControllerDelegate
extension PublicRoomsCoordinator: PublicRoomsViewControllerDelegate {
    
    func publicRoomsViewController(_ publicRoomsViewController: PublicRoomsViewController, didSelect publicRoom: MXPublicRoom) {
        guard let publicRoomId = publicRoom.roomId else {
            return
        }
        
        // If room is joined ask the delegate to present the room
        if let knownRoom = self.session.room(withRoomId: publicRoomId), knownRoom.summary.membership == .join {
            self.delegate?.publicRoomsCoordinator(self, showRoomWithId: publicRoomId, onEventId: nil)
        } else {
            self.showRoomPreview(with: publicRoom)
        }
    }
}

// MARK: - RoomPreviewCoordinatorDelegate
extension PublicRoomsCoordinator: RoomPreviewCoordinatorDelegate {
    
    func roomPreviewCoordinatorDidCancel(_ coordinator: RoomPreviewCoordinatorType) {
        self.router.popModule(animated: true)
    }
    
    func roomPreviewCoordinator(_ coordinator: RoomPreviewCoordinatorType, didJoinRoomWithId roomID: String, onEventId eventId: String?) {
        self.delegate?.publicRoomsCoordinator(self, showRoomWithId: roomID, onEventId: eventId)
    }
}
