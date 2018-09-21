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

final class AppCoordinator: AppCoordinatorType {
    
    // MARK: - Properties
  
    // MARK: Private
    
    private let rootRouter: RootRouterType
    
//    private weak var splitViewCoordinator: SplitViewCoordinatorType?
    private weak var homeCoordinator: HomeCoordinatorType?
    
    /// Main user Matrix session
    private var mainSession: MXSession? {
        return MXKAccountManager.shared().accounts.first?.mxSession
    }
  
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    init(router: RootRouterType) {
        self.rootRouter = router
    }
    
    // MARK: - Public methods
    
    func start() {
        // If main user exist, user is logged in
        if let mainSession = self.mainSession {
//            self.showSplitView(session: mainSession)
            self.showHome(session: mainSession)
        } else {
            self.showWelcome()
        }
    }
    
    // MARK: - Private methods
    
    private func showWelcome() {
        let welcomeCoordinator = WelcomeCoordinator(router: self.rootRouter)
        welcomeCoordinator.delegate = self
        welcomeCoordinator.start()
        self.add(childCoordinator: welcomeCoordinator)
    }
    
    // Disable usage of UISplitViewController for the moment
//    private func showSplitView(session: MXSession) {
//        let splitViewCoordinator = SplitViewCoordinator(router: self.rootRouter, session: session)
//        splitViewCoordinator.start()
//        self.add(childCoordinator: splitViewCoordinator)
//
//        self.registerLogoutNotification()
//    }
    
    func showHome(session: MXSession) {
        let homeCoordinator = HomeCoordinator(session: session)
        homeCoordinator.start()
        self.add(childCoordinator: homeCoordinator)
        
        self.rootRouter.setRootModule(homeCoordinator)
        
        self.homeCoordinator = homeCoordinator
        
        self.registerLogoutNotification()
    }
    
    private func registerLogoutNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(userDidLogout), name: NSNotification.Name.legacyAppDelegateDidLogout, object: nil)
    }
    
    private func unregisterLogoutNotification() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.legacyAppDelegateDidLogout, object: nil)
    }
    
    @objc private func userDidLogout() {
        self.unregisterLogoutNotification()
        
        self.showWelcome()
        
//        if let splitViewCoordinator = self.splitViewCoordinator {
//            self.remove(childCoordinator: splitViewCoordinator)
//        }
        
        if let homeCoordinator = self.homeCoordinator {
            self.remove(childCoordinator: homeCoordinator)
        }
    }
}

// MARK: - WelcomeCoordinatorDelegate
extension AppCoordinator: WelcomeCoordinatorDelegate {
    
    func welcomeCoordinatorUserDidAuthenticate(_ coordinator: WelcomeCoordinatorType) {
        if let mainSession = self.mainSession {
//            self.showSplitView(session: mainSession)
            self.showHome(session: mainSession)
            self.remove(childCoordinator: coordinator)
        } else {
            NSLog("[AppCoordinator] Did not find session for current user")
            // TODO: Present an error on
            // coordinator.toPresentable()
        }
    }
}
