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
}

final class RegistrationCoordinator: RegistrationCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    
    private let registrationFormViewController: RegistrationFormViewController
    private let activityIndicatorPresenter: ActivityIndicatorPresenterType
    private let registrationFormErrorPresenter: ErrorPresenter
    
    private let restClientBuilder: RestClientBuilder
    private var registrationService: RegistrationServiceType?
    
    // MARK: Public
    
    weak var delegate: RegistrationCoordinatorDelegate?
    
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    init(router: NavigationRouterType) {
        self.navigationRouter = router
        
        let registrationViewModel = RegistrationFormViewModel()
        let registrationFormViewController = RegistrationFormViewController.instantiate(viewModel: registrationViewModel)
        registrationFormViewController.tc_removeBackTitle()
        self.registrationFormViewController = registrationFormViewController
        
        self.activityIndicatorPresenter = ActivityIndicatorPresenter()
        self.registrationFormErrorPresenter = AlertErrorPresenter(viewControllerPresenter: registrationFormViewController)
        self.restClientBuilder = RestClientBuilder()
    }
    
    // MARK: - Public methods
    
    func start() {
        self.registrationFormViewController.delegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.registrationFormViewController
    }
    
    // MARK: - Private methods
    
    private func showEmailValidationSentAndPerformRegistration(with userEmail: String, sessionId: String, password: String, threePIDCredentials: ThreePIDCredentials) {
        
        guard let registrationService = self.registrationService else {
            let errorPresentable = ErrorPresentableImpl(title: TchapL10n.errorTitleDefault, message: TchapL10n.errorMessageDefault)
            self.registrationFormErrorPresenter.present(errorPresentable: errorPresentable)
            return
        }
        
        self.registerLoginNotification()
        
        let registrationEmailSentViewController = RegistrationEmailSentViewController.instantiate(userEmail: userEmail)
        registrationEmailSentViewController.delegate = self
        self.navigationRouter.push(registrationEmailSentViewController, animated: true, popCompletion: {
            // Cancel any pending registration request
            registrationService.cancelPendingRegistration()
        })
        
        let registrationEmailSentErrorPresenter = AlertErrorPresenter(viewControllerPresenter: registrationEmailSentViewController)
        
        let deviceDisplayName = UIDevice.current.name
        
        registrationService.register(withEmailCredentials: threePIDCredentials, sessionId: sessionId, password: password, deviceDisplayName: deviceDisplayName) { (registrationResult) in
            switch registrationResult {
            case .success:
                // NOTE: Do not call delegate directly for the moment, wait for NSNotification.Name.legacyAppDelegateDidLogin
                print("[RegistrationCoordinator] User did authenticate with success")
            case .failure(let error):
                let authenticationErrorPresentableMaker = AuthenticationErrorPresentableMaker()
                if let errorPresentable = authenticationErrorPresentableMaker.errorPresentable(from: error) {
                    registrationEmailSentErrorPresenter.present(errorPresentable: errorPresentable)
                }
            }
        }
    }
    
    private func validateRegistrationForm(with email: String, password: String) {
        
        let registrationFormViewControllerView: UIView = self.registrationFormViewController.view
        
        self.registrationFormViewController.setUserInteraction(enabled: false)
        self.activityIndicatorPresenter.presentActivityIndicator(on: registrationFormViewControllerView, animated: true)
        
        let removeActivityIndicator: (() -> Void) = {
            self.activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
            self.registrationFormViewController.setUserInteraction(enabled: true)
        }
        
        // Create rest client from email address
        self.restClientBuilder.build(from: email) { [unowned self] (restClientBuilderResult) in
            switch restClientBuilderResult {
            case .success(let restClient):
                let registrationService = RegistrationService(accountManager: MXKAccountManager.shared(), restClient: restClient)
                
                // Initialize a registration session (in order to define a session Id)
                registrationService.initRegistrationSession(completion: { (initResult) in
                    
                    switch initResult {
                    case .success(let sessionId):
                        // Validate email
                        registrationService.submitRegistrationEmailVerification(to: email, sessionId: sessionId) { (emailVerificationResult) in
                            
                            removeActivityIndicator()
                            
                            switch emailVerificationResult {
                            case .success(let threePIDCredentials):
                                self.showEmailValidationSentAndPerformRegistration(with: email, sessionId: sessionId, password: password, threePIDCredentials: threePIDCredentials)
                            case .failure(let error):
                                let authenticationErrorPresentableMaker = AuthenticationErrorPresentableMaker()
                                if let errorPresentable = authenticationErrorPresentableMaker.errorPresentable(from: error) {
                                    self.registrationFormErrorPresenter.present(errorPresentable: errorPresentable)
                                }
                            }
                        }
                    case .failure(let error):
                        let authenticationErrorPresentableMaker = AuthenticationErrorPresentableMaker()
                        if let errorPresentable = authenticationErrorPresentableMaker.errorPresentable(from: error) {
                            self.registrationFormErrorPresenter.present(errorPresentable: errorPresentable)
                        }
                    }
                })
                
                self.registrationService = registrationService
            case .failure(let error):
                removeActivityIndicator()
                
                let authenticationErrorPresentableMaker = AuthenticationErrorPresentableMaker()
                if let errorPresentable = authenticationErrorPresentableMaker.errorPresentable(from: error) {
                    self.registrationFormErrorPresenter.present(errorPresentable: errorPresentable)
                }
            }
        }
    }
    
    private func registerLoginNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(userDidLogin), name: NSNotification.Name.legacyAppDelegateDidLogin, object: nil)
    }
    
    private func unregisterLoginNotification() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.legacyAppDelegateDidLogin, object: nil)
    }
    
    @objc private func userDidLogin() {
        self.unregisterLoginNotification()
        
        if let userId = MXKAccountManager.shared().accounts.last?.mxCredentials.userId {
            self.didAuthenticate(with: userId)
        }
    }
    
    private func didAuthenticate(with userId: String) {
        self.delegate?.registrationCoordinatorDidRegisterUser(self)
    }
}

// MARK: - RegistrationViewControllerDelegate
extension RegistrationCoordinator: RegistrationFormViewControllerDelegate {
    
    func registrationFormViewController(_ registrationViewController: RegistrationFormViewController, didTapNextButtonWith mail: String, password: String) {
        // Local registration form succeed, validate email now
        self.validateRegistrationForm(with: mail, password: password)
    }
}

// MARK: - RegistrationViewControllerDelegate
extension RegistrationCoordinator: RegistrationEmailSentViewControllerDelegate {
    
    func registrationEmailSentViewControllerDidTapEmailNotReceivedButton(_ registrationEmailSentViewController: RegistrationEmailSentViewController) {
        self.navigationRouter.popModule(animated: true)
    }
}
