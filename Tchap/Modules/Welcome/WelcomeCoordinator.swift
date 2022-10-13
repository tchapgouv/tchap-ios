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
    private func updateAuthServiceForDirectAuthentication() async {
        let authService = AuthenticationService.shared
        authService.reset()
        do {
            try await authService.startFlow(.login)
        } catch {
            MXLog.error("[WelcomeCoordinator] Unable to start flow for login.")
        }
    }
    
    @MainActor private func showRegistration() async {
        let authenticationService = AuthenticationService.shared
        do {
            try await authenticationService.startFlow(.register)
        } catch {
            MXLog.error("[WelcomeCoordinator] showRegistration error")
        }
        guard let registrationWizard = authenticationService.registrationWizard else {
            return
        }
        let parameters = AuthenticationVerifyEmailCoordinatorParameters(registrationWizard: registrationWizard,
                                                                        homeserver: authenticationService.state.homeserver)
        let coordinator = AuthenticationVerifyEmailCoordinator(parameters: parameters)
        coordinator.callback = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .cancel:
                MXLog.warning("[WelcomeCoordinator] Registration cancelled")
                self.cancelRegisterFlow()
            case .completed(let registrationResult):
                switch registrationResult {
                case .success:
                    self.delegate?.welcomeCoordinatorUserDidAuthenticate(self)
                case .flowResponse:
                    MXLog.warning("[WelcomeCoordinator] flowResponse")
                }
            }
        }
        
        coordinator.start()
        add(childCoordinator: coordinator)
        
        if navigationRouter.modules.isEmpty {
            navigationRouter.setRootModule(coordinator, popCompletion: nil)
        } else {
            navigationRouter.push(coordinator, animated: true) { [weak self] in
                self?.remove(childCoordinator: coordinator)
            }
        }
    }
    
    /// Cancels the registration flow, returning to the Welcome screen.
    private func cancelRegisterFlow() {
        navigationRouter.popAllModules(animated: false)
    }
}

// MARK: - WelcomeViewControllerDelegate
extension WelcomeCoordinator: WelcomeViewControllerDelegate {
    @MainActor func welcomeViewControllerDidTapLoginButton(_ welcomeViewController: WelcomeViewController) {
        Task {
            await self.showAuthentication()
        }
    }
    
    @MainActor func welcomeViewControllerDidTapRegisterButton(_ welcomeViewController: WelcomeViewController) {
        Task {
            await self.showRegistration()
        }
    }
}
