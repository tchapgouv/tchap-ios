/*
 Copyright 2019 New Vector Ltd
 
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

import UIKit

final class ChangePasswordNewPasswordViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var instructionsLabel: UILabel!
    @IBOutlet private weak var usernameFormTextField: FormTextField! // Is not visible, coverred by `usernameCoverageView` and only used to trigger password AutoFill.
    @IBOutlet private weak var usernameCoverageView: UIView!
    @IBOutlet private weak var passwordFormTextField: FormTextField!
    @IBOutlet private weak var confirmPasswordFormTextField: FormTextField!
    @IBOutlet private weak var validateButton: UIButton!
    
    // MARK: Private

    private var viewModel: ChangePasswordNewPasswordViewModelType!
    private var style: Style!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: ErrorPresenter!
    private var activityPresenter: ActivityIndicatorPresenter!
    private var formTextFields: [FormTextField] = []

    // MARK: - Setup
    
    class func instantiate(with viewModel: ChangePasswordNewPasswordViewModelType, style: Style = Variant2Style.shared) -> ChangePasswordNewPasswordViewController {
        let viewController = StoryboardScene.ChangePasswordNewPasswordViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.style = style
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.title = TchapL10n.changePasswordNewPasswordTitle
        
        self.setupViews()
        self.keyboardAvoider = KeyboardAvoider(scrollViewContainerView: self.view, scrollView: self.scrollView)
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = AlertErrorPresenter(viewControllerPresenter: self)
        
        self.viewModel.viewDelegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.themeDidChange()
        
        self.keyboardAvoider?.startAvoiding()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.keyboardAvoider?.stopAvoiding()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.style.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(style: Style) {
        self.style = style
        
        self.view.backgroundColor = style.backgroundColor
        
        self.usernameCoverageView.backgroundColor = style.backgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            style.applyStyle(onNavigationBar: navigationBar)
        }
        
        for formTextield in self.formTextFields {
            formTextield.update(style: style)
        }
        
        self.validateButton.backgroundColor = style.backgroundColor
        style.applyStyle(onButton: self.validateButton)
    }
    
    private func themeDidChange() {
        self.update(style: self.style)
    }
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: TchapL10n.actionCancel, style: .plain) { [weak self] in
            self?.cancelButtonAction()
        }
        
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        self.scrollView.keyboardDismissMode = .interactive
        
        self.instructionsLabel.text = TchapL10n.changePasswordNewPasswordInstructions
        
        self.setupFormTextFields()
        
        self.validateButton.setTitle(TchapL10n.changePasswordNewPasswordValidateAction, for: .normal)
    }
    
    private func setupFormTextFields() {
        
        self.usernameFormTextField.fill(formTextViewModel: self.viewModel.usernameFormTextViewModel)
        self.passwordFormTextField.fill(formTextViewModel: self.viewModel.passwordFormTextViewModel)
        self.confirmPasswordFormTextField.fill(formTextViewModel: self.viewModel.confirmPasswordFormTextViewModel)
        
        let formTextFields: [FormTextField] = [
            self.usernameFormTextField,
            self.passwordFormTextField,
            self.confirmPasswordFormTextField
        ]
        
        for formTextField in formTextFields {
            formTextField.delegate = self
        }
        
        self.formTextFields = formTextFields
    }

    private func render(viewState: ChangePasswordNewPasswordViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded:
            self.renderLoaded()
        case .error(let error):
            self.render(error: error)
        case .success:
            self.renderSuccess()
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderLoaded() {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        var errorMessage: String?
        
        if let changePasswordVMError = error as? ChangePasswordNewPasswordViewModelError {
            switch changePasswordVMError {
            case .missingPassword:
                errorMessage = TchapL10n.authenticationErrorMissingPassword
            case .invalidOldPassword:
                self.presentInvalidOldPasswordAlert()
            case .passwordsDontMatch:
                errorMessage = TchapL10n.registrationErrorPasswordsDontMatch
            case .passwordTooShort:
                errorMessage = TchapL10n.passwordPolicyTooShortPwdDetailedError(FormRules.passwordMinLength)
            case .invalidPassword:
                errorMessage = TchapL10n.registrationPasswordAdditionalInfo
            }
        } else {
            let builder = MXKErrorPresentableBuilder()
            if let mxkErrorPresentable = builder.errorPresentable(fromError: error) {
                errorMessage = mxkErrorPresentable.message
            }
        }
        
        if let errorMessage = errorMessage {
            let errorTitle = TchapL10n.errorTitleDefault
            
            let errorPresentable = ErrorPresentableImpl(title: errorTitle, message: errorMessage)
            self.errorPresenter.present(errorPresentable: errorPresentable, animated: true)
        }
    }
    
    private func renderSuccess() {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.presentChangePasswordSuccessAlert()
    }
    
    private func presentInvalidOldPasswordAlert() {
        
        let alertController = UIAlertController(title: TchapL10n.errorTitleDefault,
                                                message: TchapL10n.changePasswordNewPasswordInvalidOldPassword,
                                                preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: Bundle.mxk_localizedString(forKey: "ok"), style: .default) { _ in
            self.viewModel.process(viewAction: .modifyCurrentPassword)
        }
        
        let cancelAction = UIAlertAction(title: TchapL10n.actionCancel, style: .cancel)
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true)
    }

    private func presentChangePasswordSuccessAlert() {
        
        let alertController = UIAlertController(title: TchapL10n.changePasswordNewPasswordSuccessTitle,
                                                message: TchapL10n.changePasswordNewPasswordSuccessMessage,
                                                preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: Bundle.mxk_localizedString(forKey: "ok"), style: .default) { _ in
            self.viewModel.process(viewAction: .acknowledgeSuccess)
        }
        
        alertController.addAction(okAction)
        
        self.present(alertController, animated: true)
    }
    
    // MARK: - Actions

    @IBAction private func validateButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .validate)
    }

    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
    }
}


// MARK: - ChangePasswordNewPasswordViewModelViewDelegate
extension ChangePasswordNewPasswordViewController: ChangePasswordNewPasswordViewModelViewDelegate {

    func changePasswordNewPasswordViewModel(_ viewModel: ChangePasswordNewPasswordViewModelType, didUpdateViewState viewSate: ChangePasswordNewPasswordViewState) {
        self.render(viewState: viewSate)
    }
}

// MARK: - FormTextFieldDelegate
extension ChangePasswordNewPasswordViewController: FormTextFieldDelegate {
    
    func formTextFieldShouldReturn(_ formTextField: FormTextField) -> Bool {
        guard let index = self.formTextFields.firstIndex(of: formTextField) else {
            return false
        }
        
        let nextIndex = index+1
        
        if nextIndex > self.formTextFields.count - 1 {
            _ = formTextField.resignFirstResponder()
            self.viewModel.process(viewAction: .validate)
        } else {
            _ = self.formTextFields[nextIndex].becomeFirstResponder()
        }
        
        return false
    }
}
