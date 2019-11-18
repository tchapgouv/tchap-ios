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

import Foundation

final class ChangePasswordNewPasswordViewModel: ChangePasswordNewPasswordViewModelType {
    
    // MARK: - Properties
    
    lazy var usernameFormTextViewModel: FormTextViewModelType = {
        return self.createUsernameFormViewModel()
    }()
    
    lazy var passwordFormTextViewModel: FormTextViewModelType = {
        return self.createPasswordFormViewModel()
    }()
    
    lazy var confirmPasswordFormTextViewModel: FormTextViewModelType = {
        return self.createConfirmPasswordFormViewModel()
    }()
    
    // MARK: Private
    
    private let account: MXKAccount
    private let oldPassword: String
    private let changePasswordService: ChangePasswordServiceType
    
    private var currentChangePasswordOperation: MXHTTPOperation?
    
    // MARK: Public

    weak var viewDelegate: ChangePasswordNewPasswordViewModelViewDelegate?
    weak var coordinatorDelegate: ChangePasswordNewPasswordViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(account: MXKAccount, oldPassword: String) {
        let session: MXSession = account.mxSession
        
        self.account = account
        self.oldPassword = oldPassword
        self.changePasswordService = ChangePasswordService(session: session)
    }
    
    // MARK: - Public
    
    func process(viewAction: ChangePasswordNewPasswordViewAction) {
        switch viewAction {
        case .validate:
            self.validate()
        case .cancel:
            self.coordinatorDelegate?.changePasswordNewPasswordViewModelDidCancel(self)
        case .modifyCurrentPassword:
            self.coordinatorDelegate?.changePasswordNewPasswordViewModelWantsToModifyCurrentPassword(self)
        case .acknowledgeSuccess:
            self.coordinatorDelegate?.changePasswordNewPasswordViewModelDidComplete(self)
        }
    }
    
    // MARK: - Private
    
    private func createUsernameFormViewModel() -> FormTextViewModelType {
        var usernameTextFieldProperties = TextInputProperties()
        if #available(iOS 11.0, *) {
            usernameTextFieldProperties.textContentType = .username
        }
        let usernameTextViewModel = FormTextViewModel(placeholder: "")
        usernameTextViewModel.value = self.account.linkedEmails.first
        usernameTextViewModel.textInputProperties = usernameTextFieldProperties
        usernameTextViewModel.isEditable = false
        
        return usernameTextViewModel
    }
    
    private func createPasswordFormViewModel() -> FormTextViewModelType {
        var passwordTextFieldProperties = TextInputProperties()
        passwordTextFieldProperties.isSecureTextEntry = true
        if #available(iOS 12.0, *) {
            passwordTextFieldProperties.textContentType = .newPassword
        } else if #available(iOS 11.0, *) {
            passwordTextFieldProperties.textContentType = .password
        }
        
        passwordTextFieldProperties.returnKeyType = .next
        
        let passwordTextViewModel = FormTextViewModel(placeholder: TchapL10n.forgotPasswordFormPasswordPlaceholder)
        passwordTextViewModel.textInputProperties = passwordTextFieldProperties
        passwordTextViewModel.valueMinimumCharacterLength = FormRules.passwordMinLength
        
        return passwordTextViewModel
    }
    
    private func createConfirmPasswordFormViewModel() -> FormTextViewModelType {
        
        var confirmPasswordTextFieldProperties = TextInputProperties()
        confirmPasswordTextFieldProperties.isSecureTextEntry = true
        if #available(iOS 12.0, *) {
            confirmPasswordTextFieldProperties.textContentType = .newPassword
        } else if #available(iOS 11.0, *) {
            confirmPasswordTextFieldProperties.textContentType = .password
        }
        
        confirmPasswordTextFieldProperties.returnKeyType = .done
        
        let confirmPasswordTextViewModel = FormTextViewModel(placeholder: TchapL10n.forgotPasswordFormConfirmPasswordPlaceholder)
        confirmPasswordTextViewModel.textInputProperties = confirmPasswordTextFieldProperties
        confirmPasswordTextViewModel.valueMinimumCharacterLength = FormRules.passwordMinLength
        
        return confirmPasswordTextViewModel
    }
    
    private func validate() {
        
        print("Validate new password\npassword: \(String(describing: passwordFormTextViewModel.value))\nconfirm password: \(String(describing: confirmPasswordFormTextViewModel.value))")
        
        guard let newPassword = self.passwordFormTextViewModel.value else {
            self.update(viewState: .error(ChangePasswordNewPasswordViewModelError.missingPassword))
            return
        }
        
        let formError: Error?
        
        if newPassword.isEmpty {
            print("[ChangePasswordNewPasswordViewModel] Missing Password")
            formError = ChangePasswordNewPasswordViewModelError.missingPassword
        } else if newPassword.count < FormRules.passwordMinLength {
            print("[ChangePasswordNewPasswordViewModel] Invalid Password")
            formError = ChangePasswordNewPasswordViewModelError.passwordTooShort
        } else if newPassword != self.confirmPasswordFormTextViewModel.value {
            print("[ChangePasswordNewPasswordViewModel] Passwords don't match")
            formError = ChangePasswordNewPasswordViewModelError.passwordsDontMatch
        } else {
            formError = nil
        }
        
        if let formError = formError {
            self.update(viewState: .error(formError))
        } else {
            self.update(viewState: .loading)
            
            self.currentChangePasswordOperation = self.changePasswordService.changePassword(from: self.oldPassword, to: newPassword) { (response) in
                switch response {
                case .success:
                    self.update(viewState: .success)
                case .failure(let error):
                    if let mxError = MXError(nsError: error) {
                        
                        let passwordError: ChangePasswordNewPasswordViewModelError?
                        
                        switch mxError.errcode {
                        case kMXErrCodeStringForbidden:
                            passwordError = .invalidOldPassword
                        case kMXErrCodeStringPasswordTooShort:
                            passwordError = .passwordTooShort
                        case kMXErrCodeStringPasswordNoDigit, kMXErrCodeStringPasswordNoUppercase, kMXErrCodeStringPasswordNoLowercase, kMXErrCodeStringPasswordNoSymbol:
                            passwordError = .invalidPassword
                        default:
                            passwordError = nil
                        }
                        
                        self.update(viewState: .error(passwordError ?? error))
                    } else {
                        self.update(viewState: .error(error))
                    }
                }
            }
        }
    }
    
    private func update(viewState: ChangePasswordNewPasswordViewState) {
        self.viewDelegate?.changePasswordNewPasswordViewModel(self, didUpdateViewState: viewState)
    }
}
