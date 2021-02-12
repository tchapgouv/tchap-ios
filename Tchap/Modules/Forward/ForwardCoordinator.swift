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
    private var errorPresenter: ErrorPresenter!
    private var recentsViewController: ForwardRecentListViewController!

    var childCoordinators: [Coordinator] = []

    // MARK: - Setup
    
    init(session: MXSession, messageText: String?, fileUrl: URL?) {
        self.router = NavigationRouter(navigationController: TCNavigationController())
        self.session = session
        self.messageText = messageText
        self.fileUrl = fileUrl
        let recentsViewController = ForwardRecentListViewController()
        recentsViewController.displayList(MXKRecentsDataSource(matrixSession: session))
        self.recentsViewController = recentsViewController

        let viewController = ForwardViewController.instantiate(with: Variant1Style.shared)
        self.forwardViewController = viewController
        
        self.errorPresenter = AlertErrorPresenter(viewControllerPresenter: viewController)

        super.init()
        
        viewController.delegate = self
        recentsViewController.delegate = self
    }
    
    // MARK: - Public
    
    func start() {
        self.forwardViewController.recentsViewController = self.recentsViewController
        
        self.router.setRootModule(forwardViewController)
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
        let patterns = searchText.isEmpty ? nil : [searchText]
        self.recentsViewController.dataSource.search(withPatterns: patterns)
    }
    
    func forwardController(_ viewController: ForwardViewController, searchBarCancelButtonClicked searchBar: UISearchBar) {
        searchBar.text = ""
        self.recentsViewController.dataSource.search(withPatterns: nil)
        searchBar.resignFirstResponder()
    }
}

// MARK: - MXKRecentListViewControllerDelegate

extension ForwardCoordinator: MXKRecentListViewControllerDelegate {
    func recentListViewController(_ recentListViewController: MXKRecentListViewController!, didSelectRoom roomId: String!, inMatrixSession mxSession: MXSession!) {
        MXKRoomDataSourceManager.sharedManager(forMatrixSession: session)?.roomDataSource(forRoom: roomId, create: true, onComplete: { (dataSource) in
            if let dataSource = dataSource {
                self.forwardViewController.startActivityIndicator()
                if let text = self.messageText {
                    dataSource.sendTextMessage(text) { (response) in
                        self.didForwardTo(roomId, response: response)
                    } failure: { (error) in
                        self.didForwardTo(roomId, error: error)
                    }
                } else if let url = self.fileUrl,
                          let mimeType = MXKUTI(localFileURL: url)?.mimeType {
                    dataSource.sendFile(url, mimeType: mimeType) { (response) in
                        self.didForwardTo(roomId, response: response)
                    } failure: { (error) in
                        self.didForwardTo(roomId, error: error)
                    }
                }
            } else {
                let error = NSError(domain: "ForwardCoordinatorErrorDomain", code: 0)
                self.didForwardTo(roomId, error: error)
            }
        })
    }
    
    private func didForwardTo(_ roomId: String, response: String? = nil, error: Error? = nil) {
        self.forwardViewController.stopActivityIndicator()

        if let error = error {
            self.errorPresenter.present(errorPresentable: errorPresentable(from: error), animated: true)
        } else {
            self.router.dismissModule(animated: true, completion: nil)
        }
    }
}
