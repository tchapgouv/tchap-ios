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

protocol ForgotPasswordCoordinatorDelegate: class {
    func forgotPasswordCoordinatorDidComplete(_ forgotPasswordCoordinator: ForgotPasswordCoordinator)
}

final class ForgotPasswordCoordinator: ForgotPasswordCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    
    private let activityIndicatorPresenter: ActivityIndicatorPresenterType
    private let forgotPasswordFormViewController: ForgotPasswordFormViewController
    private let forgotPasswordFormErrorPresenter: AlertErrorPresenter
    private let restClientBuilder: RestClientBuilder
    
    private var forgotPasswordService: ForgotPasswordServiceType?
    private var emailCredentials: ThreePIDCredentials?
    private var newPassword: String?
    private var resetPasswordOperation: MXHTTPOperation?
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: ForgotPasswordCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(router: NavigationRouterType) {
        self.navigationRouter = router
        
        self.restClientBuilder = RestClientBuilder()
        self.activityIndicatorPresenter = ActivityIndicatorPresenter()
        
        let forgotPasswordFormViewModel = ForgotPasswordFormViewModel()
        let forgotPasswordFormViewController = ForgotPasswordFormViewController.instantiate(viewModel: forgotPasswordFormViewModel)
        forgotPasswordFormViewController.tc_removeBackTitle()
        self.forgotPasswordFormViewController = forgotPasswordFormViewController
        
        self.forgotPasswordFormErrorPresenter = AlertErrorPresenter(viewControllerPresenter: forgotPasswordFormViewController)
    }
    
    // MARK: - Public methods
    
    func start() {
        self.forgotPasswordFormViewController.delegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.forgotPasswordFormViewController
    }
    
    // MARK: - Private methods
    
    private func showVerifyEmail(with email: String) {
        let forgotPasswordVerifyEmailViewController = ForgotPasswordVerifyEmailViewController.instantiate(userEmail: email)
        forgotPasswordVerifyEmailViewController.tc_removeBackTitle()
        forgotPasswordVerifyEmailViewController.delegate = self
        self.navigationRouter.push(forgotPasswordVerifyEmailViewController, animated: true, popCompletion: { [weak self] in
            self?.resetPasswordOperation?.cancel()
            self?.resetPasswordOperation = nil
        })
    }
    
    private func showCheckedEmail() {
        let forgotPasswordCheckedEmailViewController = ForgotPasswordCheckedEmailViewController.instantiate()
        forgotPasswordCheckedEmailViewController.tc_removeBackTitle()
        forgotPasswordCheckedEmailViewController.delegate = self
        self.navigationRouter.push(forgotPasswordCheckedEmailViewController, animated: true, popCompletion: nil)
    }
    
    private func validateForgotPasswordForm(with email: String, password: String) {
        
        let forgotPasswordFormViewControllerView: UIView = self.forgotPasswordFormViewController.view
        
        self.forgotPasswordFormViewController.setUserInteraction(enabled: false)
        self.activityIndicatorPresenter.presentActivityIndicator(on: forgotPasswordFormViewControllerView, animated: true)
        
        let removeActivityIndicator: (() -> Void) = {
            self.activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
            self.forgotPasswordFormViewController.setUserInteraction(enabled: true)
        }
        
        // Create rest client from email address
        self.restClientBuilder.build(fromEmail: email) { [weak self] (restClientBuilderResult) in
            guard let sself = self else {
                return
            }
            
            switch restClientBuilderResult {
            case .success(let restClient):
                let forgotPasswordService = ForgotPasswordService(restClient: restClient)
                
                // Validate email
                _ = forgotPasswordService.submitForgotPasswordEmail(to: email) { (emailVerificationResult) in
                    
                    removeActivityIndicator()
                    
                    switch emailVerificationResult {
                    case .success(let threePIDCredentials):
                        sself.emailCredentials = threePIDCredentials
                        sself.newPassword = password
                        sself.showVerifyEmail(with: email)
                    case .failure(let error):
                        let errorPresentable = sself.formErrorPresentable(from: error)
                        sself.forgotPasswordFormErrorPresenter.present(errorPresentable: errorPresentable)
                    }
                }
                
                sself.forgotPasswordService = forgotPasswordService
            case .failure(let error):
                removeActivityIndicator()
                
                let errorPresentable = sself.formErrorPresentable(from: error)
                sself.forgotPasswordFormErrorPresenter.present(errorPresentable: errorPresentable)
            }
        }
    }
    
    private func formErrorPresentable(from error: Error) -> ErrorPresentable {
        let errorTitle: String = TchapL10n.errorTitleDefault
        let errorMessage: String
        
        let nsError = error as NSError
        
        if let matrixErrorCode = nsError.userInfo[kMXErrorCodeKey] as? String, matrixErrorCode == kMXErrCodeStringThreePIDNotFound {
            errorMessage = TchapL10n.forgotPasswordFormErrorEmailNotFound
        } else {
            errorMessage = TchapL10n.errorMessageDefault
        }
        
        return ErrorPresentableImpl(title: errorTitle, message: errorMessage)
    }
    
    private func verifyEmailErrorPresentable(from error: Error) -> ErrorPresentable {
        let errorTitle: String = TchapL10n.errorTitleDefault
        let errorMessage: String
        
        let nsError = error as NSError
        
        if let matrixErrorCode = nsError.userInfo[kMXErrorCodeKey] as? String, matrixErrorCode == kMXErrCodeStringUnauthorized {
            errorMessage = TchapL10n.forgotPasswordVerifyEmailErrorEmailNotVerified
        } else {
            errorMessage = TchapL10n.errorMessageDefault
        }
        
        return ErrorPresentableImpl(title: errorTitle, message: errorMessage)
    }
}

// MARK: - ForgotPasswordFormViewControllerDelegate
extension ForgotPasswordCoordinator: ForgotPasswordFormViewControllerDelegate {
    
    func forgotPasswordFormViewControllerDidTap(_ forgotPasswordFormViewController: ForgotPasswordFormViewController, didTapSendEmailButtonWith email: String, password: String) {                        
        self.validateForgotPasswordForm(with: email, password: password)
    }
}

// MARK: - ForgotPasswordVerifyEmailViewController
extension ForgotPasswordCoordinator: ForgotPasswordVerifyEmailViewControllerDelegate {
    
    func forgotPasswordVerifyEmailViewControllerDidTapConfirmationButton(_ forgotPasswordVerifyEmailViewController: ForgotPasswordVerifyEmailViewController) {
        guard let forgotPasswordService = self.forgotPasswordService, let emailCredentials = self.emailCredentials, let newPassord = newPassword else {
            return
        }
        
        forgotPasswordVerifyEmailViewController.setUserInteraction(enabled: false)
        self.activityIndicatorPresenter.presentActivityIndicator(on: forgotPasswordVerifyEmailViewController.view, animated: true)
        
        let errorPresenter = AlertErrorPresenter(viewControllerPresenter: forgotPasswordVerifyEmailViewController)
        
        self.resetPasswordOperation = forgotPasswordService.resetPassword(withEmailCredentials: emailCredentials, newPassword: newPassord) { [weak self] (response) in
            guard let sself = self else {
                return
            }
            
            sself.activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
            forgotPasswordVerifyEmailViewController.setUserInteraction(enabled: true)
            
            switch response {
            case .success:
                sself.showCheckedEmail()
            case .failure(let error):
                let errorPresentable = sself.verifyEmailErrorPresentable(from: error)
                errorPresenter.present(errorPresentable: errorPresentable)
            }
        }
    }
}

// MARK: - ForgotPasswordCheckedEmailViewController
extension ForgotPasswordCoordinator: ForgotPasswordCheckedEmailViewControllerDelegate {
    
    func forgotPasswordCheckedEmailViewControllerDidTapDoneButton(_ forgotPasswordCheckedEmailViewController: ForgotPasswordCheckedEmailViewController) {
        self.delegate?.forgotPasswordCoordinatorDidComplete(self)
    }
}
