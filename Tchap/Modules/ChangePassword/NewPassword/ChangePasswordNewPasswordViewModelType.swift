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

protocol ChangePasswordNewPasswordViewModelViewDelegate: class {
    func changePasswordNewPasswordViewModel(_ viewModel: ChangePasswordNewPasswordViewModelType, didUpdateViewState viewSate: ChangePasswordNewPasswordViewState)
}

protocol ChangePasswordNewPasswordViewModelCoordinatorDelegate: class {
    func changePasswordNewPasswordViewModelDidComplete(_ viewModel: ChangePasswordNewPasswordViewModelType)    
    func changePasswordNewPasswordViewModelDidCancel(_ viewModel: ChangePasswordNewPasswordViewModelType)
    func changePasswordNewPasswordViewModelWantsToModifyCurrentPassword(_ viewModel: ChangePasswordNewPasswordViewModelType)
}

enum ChangePasswordNewPasswordViewModelError: Error {
    case missingPassword
    case passwordTooShort
    case invalidPassword
    case passwordsDontMatch
    case invalidOldPassword
}

/// Protocol describing the view model used by `ChangePasswordNewPasswordViewController`
protocol ChangePasswordNewPasswordViewModelType {
    
    var usernameFormTextViewModel: FormTextViewModelType { get }
    var passwordFormTextViewModel: FormTextViewModelType { get }
    var confirmPasswordFormTextViewModel: FormTextViewModelType { get }
    
    var viewDelegate: ChangePasswordNewPasswordViewModelViewDelegate? { get set }
    var coordinatorDelegate: ChangePasswordNewPasswordViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: ChangePasswordNewPasswordViewAction)
}
