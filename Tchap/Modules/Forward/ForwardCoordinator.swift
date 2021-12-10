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
    private let event: MXEvent
    private var errorPresenter: ErrorPresenter?
    private var shareManager: ShareManager?

    var childCoordinators: [Coordinator] = []

    // MARK: - Setup
    
    init(session: MXSession, event: MXEvent) {
        let navController = RiotNavigationController()
        navController.navigationBar.isHidden = true
        self.router = NavigationRouter(navigationController: navController)
        self.session = session
        self.event = event
        
        super.init()
        
        self.initShareManager()
        
        guard let shareManager = shareManager else {
            return
        }
        
        self.errorPresenter = AlertErrorPresenter(viewControllerPresenter: shareManager.mainViewController())
    }
    
    // MARK: - Public
    
    func start() {
        guard let shareManager = shareManager else {
            return
        }
        
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
    
    private func initShareManager() {
        let shareItemProvider: SimpleShareItemProvider
        guard let msgType = event.content["msgtype"] as? String else {
            return
        }
        if msgType == kMXMessageTypeText {
            guard let body = event.content["body"] as? String else {
                return
            }
            shareItemProvider = SimpleShareItemProvider(withTextMessage: body)
        } else {
            guard let attachment = MXKAttachment(event: event,
                                                 andMediaManager: session.mediaManager) else {
                return
            }
            shareItemProvider = SimpleShareItemProvider(withAttachment: attachment)
        }
        
        self.shareManager = ShareManager(shareItemProvider: shareItemProvider, type: .forward)
        
        self.shareManager?.completionCallback = { result in
            self.router.dismissModule(animated: true, completion: nil)
        }
    }
}
