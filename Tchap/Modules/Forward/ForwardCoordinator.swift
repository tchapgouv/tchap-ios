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
    /**
     Called once the coordinator finished forward process
     
     @param coordinator caller of this method
     @param roomID ID of the room the event has been forwarded to
     @param error instance of the error if an error occured. Nil otherwise
     */
    func forwardCoordinator(_ coordinator: ForwardCoordinatorType, didForwardTo roomID: String, error: Error?)
    
    /**
     Called if the coordinator canceled event forwarding process
     
     @param coordinator caller of this method
     */
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
        MXKRoomDataSourceManager.sharedManager(forMatrixSession: session)?.roomDataSource(forRoom: roomID, create: true, onComplete: { (dataSource) in
            if let dataSource = dataSource {
                self.forwardViewController.startActivityIndicator()
                if let text = self.messageText {
                    dataSource.sendTextMessage(text) { (response) in
                        self.didForwardTo(roomID: roomID, response: response)
                    } failure: { (error) in
                        self.didForwardTo(roomID: roomID, error: error)
                    }
                } else if let url = self.fileUrl,
                          let mimeType = MXKUTI(localFileURL: url)?.mimeType {
                    dataSource.sendFile(url, mimeType: mimeType) { (response) in
                        self.didForwardTo(roomID: roomID, response: response)
                    } failure: { (error) in
                        self.didForwardTo(roomID: roomID, error: error)
                    }
                }
            } else {
                self.router.dismissModule(animated: true) {
                    self.delegate?.forwardCoordinatorDidCancel(self)
                }
            }
        })
    }
    
    private func didForwardTo(roomID: String, response: String? = nil, error: Error? = nil) {
        self.forwardViewController.stopActivityIndicator()
        self.router.dismissModule(animated: true) {
            self.delegate?.forwardCoordinator(self, didForwardTo: roomID, error: error)
        }
    }
}
