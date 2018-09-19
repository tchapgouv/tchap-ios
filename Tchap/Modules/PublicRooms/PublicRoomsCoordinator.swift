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
}

final class PublicRoomsCoordinator: PublicRoomsCoordinatorType {
    
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
        self.router = NavigationRouter()
        self.session = session
        
        let publicRoomServers = PublicRoomsCoordinator.getPublicRoomServers()
        let publicRoomService = PublicRoomService(homeServersStringURL: publicRoomServers, session: self.session)
        let publicRoomDataSource = PublicRoomsDataSource(session: self.session, publicRoomService: publicRoomService)
        let publicRoomsViewController = PublicRoomsViewController.instantiate(dataSource: publicRoomDataSource)
        self.publicRoomsViewController = publicRoomsViewController
        
        publicRoomsViewController.navigationItem.leftBarButtonItem = MXKBarButtonItem(title: TchapL10n.actionCancel, style: .plain) { [weak self] in
            self?.didCancel()
        }
        
        self.router.setRootModule(publicRoomsViewController)
    }
    
    // MARK: - Public methods
    
    func start() {
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
}
