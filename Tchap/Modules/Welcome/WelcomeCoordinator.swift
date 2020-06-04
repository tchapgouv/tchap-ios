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

protocol WelcomeCoordinatorDelegate: class {
    func welcomeCoordinatorUserDidAuthenticate(_ coordinator: WelcomeCoordinatorType)
}

final class WelcomeCoordinator: WelcomeCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let rootRouter: RootRouterType
    private let navigationRouter: NavigationRouterType
    private let welcomeViewController: WelcomeViewController
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: WelcomeCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(router: RootRouterType) {
        self.rootRouter = router
        self.navigationRouter = NavigationRouter(navigationController: TCNavigationController())
        
        let welcomeViewController = WelcomeViewController.instantiate()
        welcomeViewController.tc_removeBackTitle()
        self.welcomeViewController = welcomeViewController        
    }
    
    // MARK: - Public methods
    
    func start() {
        self.rootRouter.setRootModule(self.navigationRouter)
        self.navigationRouter.setRootModule(self.welcomeViewController, hideNavigationBar: true, animated: false, popCompletion: nil)
        self.welcomeViewController.delegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private methods
    
    private func showAuthentication() {
        let authenticationCoordinator = AuthenticationCoordinator(router: self.navigationRouter)
        authenticationCoordinator.delegate = self
        authenticationCoordinator.start()
        
        self.navigationRouter.push(authenticationCoordinator, animated: true) {
            self.remove(childCoordinator: authenticationCoordinator)
        }
        
        self.add(childCoordinator: authenticationCoordinator)
    }
    
    private func showRegistration() {
        let registrationCoordinator = RegistrationCoordinator(router: self.navigationRouter)
        registrationCoordinator.delegate = self
        registrationCoordinator.start()
        
        self.navigationRouter.push(registrationCoordinator, animated: true) {
            self.remove(childCoordinator: registrationCoordinator)
        }
        
        self.add(childCoordinator: registrationCoordinator)
    }
}

// MARK: - WelcomeViewControllerDelegate
extension WelcomeCoordinator: WelcomeViewControllerDelegate {
    func welcomeViewControllerDidTapLoginButton(_ welcomeViewController: WelcomeViewController) {
        self.showAuthentication()
    }
    
    func welcomeViewControllerDidTapRegisterButton(_ welcomeViewController: WelcomeViewController) {
        self.showRegistration()
    }
}

// MARK: - AuthenticationCoordinatorDelegate
extension WelcomeCoordinator: AuthenticationCoordinatorDelegate {

    func authenticationCoordinator(coordinator: AuthenticationCoordinatorType, didAuthenticateWithUserId userId: String) {
        self.delegate?.welcomeCoordinatorUserDidAuthenticate(self)
    }
}

// MARK: - AuthenticationCoordinatorDelegate
extension WelcomeCoordinator: RegistrationCoordinatorDelegate {
    
    func registrationCoordinatorDidRegisterUser(_ coordinator: RegistrationCoordinatorType) {
        self.delegate?.welcomeCoordinatorUserDidAuthenticate(self)
    }
    
    func registrationCoordinatorShowAuthentication(_ coordinator: RegistrationCoordinatorType) {
        self.navigationRouter.popToRootModule(animated: false)
        self.showAuthentication()
    }
}
