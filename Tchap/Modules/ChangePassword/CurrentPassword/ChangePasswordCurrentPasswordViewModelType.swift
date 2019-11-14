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

protocol ChangePasswordCurrentPasswordViewModelViewDelegate: class {
    func changePasswordCurrentPasswordViewModel(_ viewModel: ChangePasswordCurrentPasswordViewModelType, didUpdateViewState viewSate: ChangePasswordCurrentPasswordViewState)
}

protocol ChangePasswordCurrentPasswordViewModelCoordinatorDelegate: class {
    func changePasswordCurrentPasswordViewModel(_ viewModel: ChangePasswordCurrentPasswordViewModelType, didCompleteWithCurrentPassword currentPassword: String)    
    func changePasswordCurrentPasswordViewModelDidCancel(_ viewModel: ChangePasswordCurrentPasswordViewModelType)
}

enum ChangePasswordCurrentPasswordViewModelError: Error {
    case missingPassword    
}

/// Protocol describing the view model used by `ChangePasswordCurrentPasswordViewController`
protocol ChangePasswordCurrentPasswordViewModelType {
    
    var passwordFormTextViewModel: FormTextViewModelType { get }
    
    var viewDelegate: ChangePasswordCurrentPasswordViewModelViewDelegate? { get set }
    var coordinatorDelegate: ChangePasswordCurrentPasswordViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: ChangePasswordCurrentPasswordViewAction)
}
