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

protocol WelcomeCoordinatorDelegate: AnyObject {
    func welcomeCoordinatorUserDidAuthenticate(_ coordinator: WelcomeCoordinatorType)
}

final class WelcomeCoordinator: WelcomeCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    private let welcomeViewController: WelcomeViewController
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: WelcomeCoordinatorDelegate?
    
    // MARK: - Setup
    
    init() {
        let navController = RiotNavigationController()
        navController.modalPresentationStyle = .fullScreen
        self.navigationRouter = NavigationRouter(navigationController: navController)
        
        let welcomeViewController = WelcomeViewController.instantiate()
        welcomeViewController.vc_removeBackTitle()
        self.welcomeViewController = welcomeViewController        
    }
    
    // MARK: - Public methods
    
    func start() {
        self.navigationRouter.setRootModule(self.welcomeViewController, hideNavigationBar: true, animated: false, popCompletion: nil)
        self.welcomeViewController.delegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private methods
    
    @MainActor private func showAuthentication() async {
        let authService = AuthenticationService.shared
        await updateAuthServiceForDirectAuthentication()
        let parameters = AuthenticationLoginCoordinatorParameters(navigationRouter: self.navigationRouter,
                                                                  authenticationService: authService,
                                                                  loginMode: .password)
        let authenticationLoginCoordinator = AuthenticationLoginCoordinator(parameters: parameters)
        authenticationLoginCoordinator.callback = { [weak self] result in
            guard let self = self else { return }
            self.delegate?.welcomeCoordinatorUserDidAuthenticate(self)
        }
        authenticationLoginCoordinator.start()
        self.add(childCoordinator: authenticationLoginCoordinator)
        
        if navigationRouter.modules.isEmpty {
            navigationRouter.setRootModule(authenticationLoginCoordinator, popCompletion: nil)
        } else {
            navigationRouter.push(authenticationLoginCoordinator, animated: true) { [weak self] in
                self?.remove(childCoordinator: authenticationLoginCoordinator)
            }
        }
    }
    
    // Start login flow by updating AuthenticationService
    func updateAuthServiceForDirectAuthentication() async {
        let authService = AuthenticationService.shared
        authService.reset()
        do {
            try await authService.startFlow(.login)
        } catch {
            MXLog.error("[WelcomeCoordinator] Unable to start flow for login.")
        }
    }
    
    private func showRegistration() {
//        let registrationCoordinator = RegistrationCoordinator(router: self.navigationRouter)
//        registrationCoordinator.delegate = self
//        registrationCoordinator.start()
//
//        self.navigationRouter.push(registrationCoordinator, animated: true) {
//            self.remove(childCoordinator: registrationCoordinator)
//        }
//
//        self.add(childCoordinator: registrationCoordinator)
    }
}

// MARK: - WelcomeViewControllerDelegate
extension WelcomeCoordinator: WelcomeViewControllerDelegate {
    @MainActor func welcomeViewControllerDidTapLoginButton(_ welcomeViewController: WelcomeViewController) {
        Task {
            await self.showAuthentication()
        }
    }
    
    func welcomeViewControllerDidTapRegisterButton(_ welcomeViewController: WelcomeViewController) {
        self.showRegistration()
    }
}

// MARK: - AuthenticationCoordinatorDelegate
//extension WelcomeCoordinator: RegistrationCoordinatorDelegate {
//    
//    func registrationCoordinatorDidRegisterUser(_ coordinator: RegistrationCoordinatorType) {
//        self.delegate?.welcomeCoordinatorUserDidAuthenticate(self)
//    }
//    
//    func registrationCoordinatorShowAuthentication(_ coordinator: RegistrationCoordinatorType) {
//        self.navigationRouter.popToRootModule(animated: false)
//        self.showAuthentication()
//    }
//}
