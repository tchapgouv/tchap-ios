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

/// The view model used by AuthenticationViewController
final class AuthenticationViewModel: AuthenticationViewModelType {
    
    // MARK: - Properties
    
    let loginTextViewModel: FormTextViewModelType
    let passwordTextViewModel: FormTextViewModelType
    
    // MARK: - Setup
    
    init() {
        
        // Mail
        
        let mailTextViewModel = FormTextViewModel(placeholder: TchapL10n.authenticationMailPlaceholder)
        
        var mailTextFieldProperties = TextInputProperties()
        mailTextFieldProperties.keyboardType = .emailAddress
        mailTextFieldProperties.returnKeyType = .next
        mailTextFieldProperties.textContentType = .emailAddress
        
        mailTextViewModel.textInputProperties = mailTextFieldProperties
        
        // Password
        
        let passwordTextViewModel = FormTextViewModel(placeholder: TchapL10n.authenticationPasswordPlaceholder)
        
        var passwordTextFieldProperties = TextInputProperties()
        passwordTextFieldProperties.isSecureTextEntry = true
        passwordTextFieldProperties.returnKeyType = .done
        
        if #available(iOS 11.0, *) {
            passwordTextFieldProperties.textContentType = .password
        }
        
        passwordTextViewModel.textInputProperties = passwordTextFieldProperties
        
        self.loginTextViewModel = mailTextViewModel
        self.passwordTextViewModel = passwordTextViewModel
    }
    
    // MARK: - Public
    
    func validateForm() -> AuthenticationFormValidationResult {
        
        let errorTitle = TchapL10n.errorTitleDefault
        
        guard let mail = self.loginTextViewModel.value else {
            let errorPresentable = ErrorPresentableImpl(title: errorTitle, message: TchapL10n.authenticationErrorInvalidEmail)
            return .failure(errorPresentable)
        }
        
        guard let password = self.passwordTextViewModel.value else {
            let errorPresentable = ErrorPresentableImpl(title: errorTitle, message: TchapL10n.authenticationErrorMissingPassword)
            return .failure(errorPresentable)
        }
        
        let validationResult: AuthenticationFormValidationResult
        
        var errorMessage: String?
        
        if !MXTools.isEmailAddress(mail) {
            print("[AuthenticationViewModel] Invalid email")
            errorMessage = TchapL10n.authenticationErrorInvalidEmail
        } else if password.isEmpty {
            print("[AuthenticationViewModel] Missing Password")
            errorMessage = TchapL10n.authenticationErrorMissingPassword
        }
        
        if let errorMessage = errorMessage {
            let errorPresentable = ErrorPresentableImpl(title: errorTitle, message: errorMessage)
            validationResult = .failure(errorPresentable)
        } else {
            let authenticationFields = AuthenticationFields(login: mail, password: password)
            validationResult = .success(authenticationFields)
        }        
        
        return validationResult
    }
}
