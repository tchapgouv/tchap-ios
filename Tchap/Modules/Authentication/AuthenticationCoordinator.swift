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

protocol AuthenticationCoordinatorDelegate: class {
    func authenticationCoordinator(coordinator: AuthenticationCoordinatorType, didAuthenticateWithUserId userId: String)
}

final class AuthenticationCoordinator: NSObject, AuthenticationCoordinatorType {
    
    // MARK: - Constants
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let router: RootRouterType
    private let authenticationViewController: AuthenticationViewController
    
    // MARK: Public
    
    weak var delegate: AuthenticationCoordinatorDelegate?
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    init(router: RootRouterType) {
        self.router = router
        self.authenticationViewController = AuthenticationViewController.instantiate()
    }
    
    // MARK: - Public methods
    
    func start() {
//        self.authenticationViewController.delegate = self
        self.router.setRootModule(self.authenticationViewController)
        
        self.registerLogintNotification()
    }
    
    func toPresentable() -> UIViewController {
        return self.authenticationViewController
    }
    
    // MARK: - Private methods
    
    private func registerLogintNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(userDidLogin), name: NSNotification.Name.legacyAppDelegateDidLogin, object: nil)
    }
    
    private func unregisterLoginNotification() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.legacyAppDelegateDidLogin, object: nil)
    }
    
    @objc private func userDidLogin() {
        self.unregisterLoginNotification()
        
//        if let userId = MXKAccountManager.shared().accounts.last?.mxSession.myUser.userId {
            self.didAuthenticate(with: "")
//        }
    }
    
    private func didAuthenticate(with userId: String) {
//        self.router.dismissModule(animated: true, completion: nil)
        self.delegate?.authenticationCoordinator(coordinator: self, didAuthenticateWithUserId: userId)
    }
    
//    deinit {
//        self.authenticationViewController.delegate = nil
//    }
}

// MARK: - MXKAuthenticationViewControllerDelegate
extension AuthenticationCoordinator: MXKAuthenticationViewControllerDelegate {

    func authenticationViewController(_ authenticationViewController: MXKAuthenticationViewController!, didLogWithUserId userId: String!) {
        self.didAuthenticate(with: userId)
    }
}
