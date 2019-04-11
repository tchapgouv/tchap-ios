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

/// The view model used by ForgotPasswordFormViewController
final class ForgotPasswordFormViewModel: ForgotPasswordFormViewModelType {
    
    // MARK: - Properties
    
    let loginTextViewModel: FormTextViewModelType
    let passwordTextViewModel: FormTextViewModelType
    let confirmPasswordTextViewModel: FormTextViewModelType
    
    // MARK: - Setup
    
    init() {
        
        // Email
        
        let emailTextViewModel = FormTextViewModel(placeholder: TchapL10n.forgotPasswordFormEmailPlaceholder)
        
        var mailTextFieldProperties = TextInputProperties()
        mailTextFieldProperties.keyboardType = .emailAddress
        mailTextFieldProperties.returnKeyType = .next
        mailTextFieldProperties.textContentType = .emailAddress
        
        emailTextViewModel.textInputProperties = mailTextFieldProperties
        
        // Password
        
        var passwordTextFieldProperties = TextInputProperties()
        passwordTextFieldProperties.isSecureTextEntry = true
        if #available(iOS 12.0, *) {
            passwordTextFieldProperties.textContentType = .newPassword
        } else if #available(iOS 11.0, *) {
            passwordTextFieldProperties.textContentType = .password
        }
        
        let passwordTextViewModel = FormTextViewModel(placeholder: TchapL10n.forgotPasswordFormPasswordPlaceholder)
        passwordTextViewModel.textInputProperties = passwordTextFieldProperties
        passwordTextViewModel.valueMinimumCharacterLength = FormRules.passwordMinLength
        
        // Confirm password
        
        // Note ".newPassword" type could not be used for the confirmation text field
        // because this triggers an auto fill and clears the manually filled password (if any)
        var confirmPasswordTextFieldProperties = TextInputProperties()
        confirmPasswordTextFieldProperties.isSecureTextEntry = true
        if #available(iOS 11.0, *) {
            confirmPasswordTextFieldProperties.textContentType = .password
        }
        
        let confirmPasswordTextViewModel = FormTextViewModel(placeholder: TchapL10n.forgotPasswordFormConfirmPasswordPlaceholder)
        confirmPasswordTextViewModel.textInputProperties = confirmPasswordTextFieldProperties
        confirmPasswordTextViewModel.valueMinimumCharacterLength = FormRules.passwordMinLength
        
        let textViewModels = [
            emailTextViewModel,
            passwordTextViewModel,
            confirmPasswordTextViewModel
        ]
        
        var index = 0
        for textViewModel in textViewModels {
            let returnKeyType: UIReturnKeyType
            
            if index >= textViewModels.count - 1 {
                returnKeyType = .done
            } else {
                returnKeyType = .next
            }
            textViewModel.textInputProperties.returnKeyType = returnKeyType
            index+=1
        }
        
        self.loginTextViewModel = emailTextViewModel
        self.passwordTextViewModel = passwordTextViewModel
        self.confirmPasswordTextViewModel = confirmPasswordTextViewModel
    }
    
    // MARK: - Public
    
    func validateForm() -> AuthenticationFormValidationResult {
        
        let errorTitle = TchapL10n.errorTitleDefault
        
        guard let login = self.loginTextViewModel.value else {
            let errorPresentable = ErrorPresentableImpl(title: errorTitle, message: TchapL10n.authenticationErrorInvalidEmail)
            return .failure(errorPresentable)
        }
        
        // Handle here the potential Password AutoFill feature
        let doPasswordsMatch: Bool
        var password = self.passwordTextViewModel.value
        if let confirmPassword = self.confirmPasswordTextViewModel.value {
            if self.confirmPasswordTextViewModel.hasBeenAutoFilled {
                // Ignore the first password value if the confirmed one has been auto-filled.
                password = confirmPassword
                doPasswordsMatch = true
            } else {
                doPasswordsMatch = (password == confirmPassword)
            }
        } else {
            // Ignore the null comfirmed password if the main password has been auto-filled.
            doPasswordsMatch = self.passwordTextViewModel.hasBeenAutoFilled
        }
        
        guard let actualPassword = password else {
            let errorPresentable = ErrorPresentableImpl(title: errorTitle, message: TchapL10n.authenticationErrorMissingPassword)
            return .failure(errorPresentable)
        }
        
        let mail = login.trimmingCharacters(in: .whitespacesAndNewlines)
        let validationResult: AuthenticationFormValidationResult
        
        var errorMessage: String?
        
        if !MXTools.isEmailAddress(mail) {
            print("[ForgotPasswordFormViewModel] Invalid email")
            errorMessage = TchapL10n.authenticationErrorInvalidEmail
        } else if actualPassword.isEmpty {
            print("[ForgotPasswordFormViewModel] Missing Password")
            errorMessage = TchapL10n.authenticationErrorMissingPassword
        } else if actualPassword.count < FormRules.passwordMinLength {
            print("[ForgotPasswordFormViewModel] Invalid Password")
            errorMessage = TchapL10n.authenticationErrorInvalidPassword(FormRules.passwordMinLength)
        } else if doPasswordsMatch == false {
            print("[ForgotPasswordFormViewModel] Passwords don't match")
            errorMessage = TchapL10n.registrationErrorPasswordsDontMatch
        }
        
        if let errorMessage = errorMessage {
            let errorPresentable = ErrorPresentableImpl(title: errorTitle, message: errorMessage)
            validationResult = .failure(errorPresentable)
        } else {
            let authenticationFields = AuthenticationFields(login: mail, password: actualPassword)
            validationResult = .success(authenticationFields)
        }
        
        return validationResult
    }
}
