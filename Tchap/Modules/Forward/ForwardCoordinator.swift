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
    private let session: MXSession
    private let shareItemProvider: SimpleShareItemProvider
    private let shareItemSender: ShareItemSender
    private var errorPresenter: ErrorPresenter!
    private var shareManager: ShareManager

    var childCoordinators: [Coordinator] = []

    // MARK: - Setup
    
    init(session: MXSession, shareItemProvider: SimpleShareItemProvider) {
        let navController = RiotNavigationController()
        navController.navigationBar.isHidden = true
        self.router = NavigationRouter(navigationController: navController)
        self.session = session
        self.shareItemProvider = shareItemProvider
        self.shareItemSender = ShareItemSender(shareItemProvider: self.shareItemProvider)
        
        self.shareManager = ShareManager(shareItemSender: shareItemSender, type: .forward)
        
        self.errorPresenter = AlertErrorPresenter(viewControllerPresenter: shareManager.mainViewController())
        
        super.init()
        
        self.shareManager.completionCallback = { result in
            self.router.dismissModule(animated: true, completion: nil)
        }
    }
    
    // MARK: - Public
    
    func start() {
        self.router.setRootModule(shareManager.mainViewController())
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
