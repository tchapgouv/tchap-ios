// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

protocol ForwardCoordinatorDelegate: class {
    func forwardCoordinator(_ coordinator: ForwardCoordinatorType, didSelectRoomWithID: String)
    func forwardCoordinatorDidCancel(_ coordinator: ForwardCoordinatorType)
}

final class ForwardCoordinator: NSObject, ForwardCoordinatorType {
    
    weak var delegate: ForwardCoordinatorDelegate?
    private let router: NavigationRouterType
    private let forwardViewController: ForwardViewController
    private let session: MXSession
    private let messageText: String?
    private let fileUrl: URL?
    private weak var roomsCoordinator: RoomsCoordinatorType?

    var childCoordinators: [Coordinator] = []

    // MARK: - Setup
    
    init(session: MXSession, messageText: String?, fileUrl: URL?) {
        self.router = NavigationRouter(navigationController: TCNavigationController())
        self.session = session
        self.messageText = messageText
        self.fileUrl = fileUrl
        
        let viewController = ForwardViewController.instantiate(with: Variant1Style.shared)
        self.forwardViewController = viewController
        
        super.init()
        
        viewController.searchBar.delegate = self
        self.forwardViewController.navigationItem.leftBarButtonItem = MXKBarButtonItem(title: TchapL10n.actionCancel, style: .plain) { [weak self] in
            self?.cancel()
        }
    }
    
    // MARK: - Public
    
    func start() {
        let roomsCoordinator = RoomsCoordinator(router: self.router, session: self.session)
        roomsCoordinator.delegate = self
        self.add(childCoordinator: roomsCoordinator)
        
        self.forwardViewController.roomsViewController = roomsCoordinator.toPresentable()
        
        self.router.setRootModule(forwardViewController)

        roomsCoordinator.start()
        self.roomsCoordinator = roomsCoordinator
    }
    
    func toPresentable() -> UIViewController {
        return self.router.toPresentable()
    }
    
    // MARK: - Private
    
    private func cancel() {
        self.router.dismissModule(animated: true) {
            self.delegate?.forwardCoordinatorDidCancel(self)
        }
    }
}

// MARK: - UISearchBarDelegate

extension ForwardCoordinator: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.roomsCoordinator?.updateSearchText(searchText)
    }
}

// MARK: - RoomsCoordinatorDelegate

extension ForwardCoordinator: RoomsCoordinatorDelegate {
    func roomsCoordinator(_ coordinator: RoomsCoordinatorType, didSelectRoomID roomID: String) {
        if let selectedRoom = MXRoom.load(from: self.session.store, withRoomId: roomID, matrixSession: self.session) as? MXRoom {
            if let text = self.messageText {
                var echo: MXEvent?
                self.forwardViewController.startActivityIndicator()
                selectedRoom.sendTextMessage(text, localEcho: &echo) { (response) in
                    self.forwardViewController.stopActivityIndicator()
                    print("\(response)")
                    self.router.dismissModule(animated: true) {
                        self.delegate?.forwardCoordinator(self, didSelectRoomWithID: roomID)
                    }
                }
            } else if let url = self.fileUrl,
                      let mimeType = MXKUTI(localFileURL: url)?.mimeType {
                var echo: MXEvent?
                self.forwardViewController.startActivityIndicator()
                selectedRoom.sendFile(localURL: url, mimeType: mimeType, localEcho: &echo) { (response) in
                    print("\(response)")
                    self.router.dismissModule(animated: true) {
                        self.delegate?.forwardCoordinator(self, didSelectRoomWithID: roomID)
                    }
                }
            } else {
                self.router.dismissModule(animated: true) {
                    self.delegate?.forwardCoordinator(self, didSelectRoomWithID: roomID)
                }
            }
        }
    }
}
