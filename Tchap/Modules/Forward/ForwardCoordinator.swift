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

final class ForwardCoordinator: NSObject, ForwardCoordinatorType {
    
    private let router: NavigationRouterType
    private let forwardViewController: ForwardViewController
    private let session: MXSession
    private let messageText: String?
    private let fileUrl: URL?
    private weak var roomsCoordinator: RoomsCoordinatorType?
    private var errorPresenter: ErrorPresenter!

    var childCoordinators: [Coordinator] = []

    // MARK: - Setup
    
    init(session: MXSession, messageText: String?, fileUrl: URL?) {
        self.router = NavigationRouter(navigationController: TCNavigationController())
        self.session = session
        self.messageText = messageText
        self.fileUrl = fileUrl

        let viewController = ForwardViewController.instantiate(with: Variant1Style.shared)
        self.forwardViewController = viewController
        
        self.errorPresenter = AlertErrorPresenter(viewControllerPresenter: viewController)

        super.init()
        
        viewController.delegate = self
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
    
    private func errorPresentable(from error: Error) -> ErrorPresentable {
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

// MARK: - ForwardViewControllerDelegate

extension ForwardCoordinator: ForwardViewControllerDelegate {
    func forwardControllerCancelButtonClicked(_ viewController: ForwardViewController) {
        self.router.dismissModule(animated: true, completion: nil)
    }
    
    func forwardController(_ viewController: ForwardViewController, searchBar: UISearchBar, textDidChange searchText: String) {
        self.roomsCoordinator?.updateSearchText(searchText)
    }
    
    func forwardController(_ viewController: ForwardViewController, searchBarCancelButtonClicked searchBar: UISearchBar) {
        searchBar.text = ""
        self.roomsCoordinator?.updateSearchText(searchBar.text)
        searchBar.resignFirstResponder()
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
                let error = NSError(domain: "ForwardCoordinatorErrorDomain", code: 0)
                self.didForwardTo(roomID: roomID, error: error)
            }
        })
    }
    
    private func didForwardTo(roomID: String, response: String? = nil, error: Error? = nil) {
        self.forwardViewController.stopActivityIndicator()

        if let error = error {
            self.errorPresenter.present(errorPresentable: errorPresentable(from: error), animated: true)
        } else {
            self.router.dismissModule(animated: true, completion: nil)
        }
    }
}
