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

final class ChangePasswordCurrentPasswordViewModel: ChangePasswordCurrentPasswordViewModelType {
    
    // MARK: - Properties
    
    lazy var passwordFormTextViewModel: FormTextViewModelType = {
        return self.createPasswordFormViewModel()
    }()
    
    // MARK: Private

    private let session: MXSession
    
    // MARK: Public
    
    weak var viewDelegate: ChangePasswordCurrentPasswordViewModelViewDelegate?
    weak var coordinatorDelegate: ChangePasswordCurrentPasswordViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
    }
    
    // MARK: - Public
    
    func process(viewAction: ChangePasswordCurrentPasswordViewAction) {
        switch viewAction {
        case .validate:
            self.validate()
        case .cancel:
            self.coordinatorDelegate?.changePasswordCurrentPasswordViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func createPasswordFormViewModel() -> FormTextViewModelType {

        let passwordTextViewModel = FormTextViewModel(placeholder: TchapL10n.changePasswordCurrentPasswordPasswordPlaceholder)
        
        var passwordTextFieldProperties = TextInputProperties()
        passwordTextFieldProperties.isSecureTextEntry = true        
        passwordTextFieldProperties.returnKeyType = .done
        
        if #available(iOS 11.0, *) {
            passwordTextFieldProperties.textContentType = .password
        }
        
        passwordTextViewModel.textInputProperties = passwordTextFieldProperties
        return passwordTextViewModel
    }
    
    private func validate() {
        
        if let password = self.passwordFormTextViewModel.value, password.isEmpty == false {
            self.coordinatorDelegate?.changePasswordCurrentPasswordViewModel(self, didCompleteWithCurrentPassword: password)
        } else {
            self.update(viewState: .error(ChangePasswordCurrentPasswordViewModelError.missingPassword))
        }
    }
    
    private func update(viewState: ChangePasswordCurrentPasswordViewState) {
        self.viewDelegate?.changePasswordCurrentPasswordViewModel(self, didUpdateViewState: viewState)
    }
}
