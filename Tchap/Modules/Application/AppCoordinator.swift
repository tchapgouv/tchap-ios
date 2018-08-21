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
    
    private weak var splitViewCoordinator: SplitViewCoordinatorType?
    
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
            self.showSplitView(session: mainSession)
        } else {
            self.showAuthentication()
        }
    }
    
    // MARK: - Private methods
    
    private func showAuthentication() {
        let authenticationCoordinator = AuthenticationCoordinator(router: self.rootRouter)
        authenticationCoordinator.delegate = self
        authenticationCoordinator.start()
        self.add(childCoordinator: authenticationCoordinator)
    }
    
    private func showSplitView(session: MXSession) {
        let splitViewCoordinator = SplitViewCoordinator(router: self.rootRouter, session: session)
        splitViewCoordinator.start()
        self.add(childCoordinator: splitViewCoordinator)
        
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
        
        self.showAuthentication()                
        
        if let splitViewCoordinator = self.splitViewCoordinator {
            self.remove(childCoordinator: splitViewCoordinator)
        }
    }
}

// MARK: - AuthenticationCoordinatorDelegate
extension AppCoordinator: AuthenticationCoordinatorDelegate {
    
    func authenticationCoordinator(coordinator: AuthenticationCoordinatorType, didAuthenticateWithUserId userId: String) {
        
        if let mainSession = self.mainSession {
            self.showSplitView(session: mainSession)
            self.remove(childCoordinator: coordinator)
        } else {
            NSLog("[AppCoordinator] Did not find session for userId")
            // TODO: Present an error on
            // coordinator.toPresentable()
        }
    }
}
