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

protocol RegistrationCoordinatorDelegate: class {
    func registrationCoordinatorDidRegisterUser(_ coordinator: RegistrationCoordinatorType)
    func registrationCoordinatorDidCancelRegistration(_ coordinator: RegistrationCoordinatorType)
}

final class RegistrationCoordinator: RegistrationCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let registrationFormViewController: RegistrationFormViewController
    private let navigationRouter: NavigationRouterType
    private let authenticationService: AuthenticationServiceType
    private let activityIndicatorPresenter: ActivityIndicatorPresenterType
    private let registrationFormErrorPresenter: ErrorPresenter
    
    // MARK: Public
    
    weak var delegate: RegistrationCoordinatorDelegate?
    
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    init(router: NavigationRouterType) {
        self.navigationRouter = router
        self.authenticationService = AuthenticationService(accountManager: MXKAccountManager.shared())
        let registrationViewModel = RegistrationFormViewModel()
        let registrationFormViewController = RegistrationFormViewController.instantiate(viewModel: registrationViewModel)
        registrationFormViewController.tc_removeBackTitle()
        self.registrationFormViewController = registrationFormViewController
        self.activityIndicatorPresenter = ActivityIndicatorPresenter()
        self.registrationFormErrorPresenter = AlertErrorPresenter(viewControllerPresenter: registrationFormViewController)
    }
    
    // MARK: - Public methods
    
    func start() {
        self.registrationFormViewController.delegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.registrationFormViewController
    }
    
    // MARK: - Private methods
    
    private func didRegister(with userId: String) {
        self.delegate?.registrationCoordinatorDidRegisterUser(self)
    }
    
    private func register(with mail: String, password: String) {
        self.registrationFormViewController.setUserInteraction(enabled: false)
        self.activityIndicatorPresenter.presentActivityIndicator(on: self.registrationFormViewController.view, animated: true)
        
        self.authenticationService.register(with: mail,
                                            password: password,
                                            deviceDisplayName: UIDevice.current.name) { (response) in
            
            self.activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
            self.registrationFormViewController.setUserInteraction(enabled: true)
            
            switch response {
            case .success(let email):
                self.showEmailSent(with: email)
            case .failure(let error):
                // Display error on RegistrationFormViewController
                // TODO: Handle specific registration errors
                let authenticationErrorPresentableMaker = AuthenticationErrorPresentableMaker()
                if let errorPresentable = authenticationErrorPresentableMaker.errorPresentable(from: error) {
                    self.registrationFormErrorPresenter.present(errorPresentable: errorPresentable)
                }
            }
        }
    }
    
    private func showEmailSent(with userEmail: String) {
        let registrationEmailSentViewController = RegistrationEmailSentViewController.instantiate(userEmail: userEmail)
        registrationEmailSentViewController.delegate = self
        self.navigationRouter.push(registrationEmailSentViewController, animated: true, popCompletion: nil)
    }
}

// MARK: - RegistrationViewControllerDelegate
extension RegistrationCoordinator: RegistrationFormViewControllerDelegate {
    
    func registrationFormViewController(_ registrationViewController: RegistrationFormViewController, didTapNextButtonWith mail: String, password: String) {
        self.register(with: mail, password: password)
    }
}

// MARK: - RegistrationViewControllerDelegate
extension RegistrationCoordinator: RegistrationEmailSentViewControllerDelegate {
    
    func registrationEmailSentViewControllerDidTapEmailNotReceivedButton(_ registrationEmailSentViewController: RegistrationEmailSentViewController) {
        self.delegate?.registrationCoordinatorDidCancelRegistration(self)
    }
}
