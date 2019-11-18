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
import UIKit

final class ChangePasswordNewPasswordCoordinator: ChangePasswordNewPasswordCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private var changePasswordNewPasswordViewModel: ChangePasswordNewPasswordViewModelType
    private let changePasswordNewPasswordViewController: ChangePasswordNewPasswordViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: ChangePasswordNewPasswordCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(account: MXKAccount, oldPassword: String) {
        let changePasswordNewPasswordViewModel = ChangePasswordNewPasswordViewModel(account: account, oldPassword: oldPassword)
        let changePasswordNewPasswordViewController = ChangePasswordNewPasswordViewController.instantiate(with: changePasswordNewPasswordViewModel)
        self.changePasswordNewPasswordViewModel = changePasswordNewPasswordViewModel
        self.changePasswordNewPasswordViewController = changePasswordNewPasswordViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.changePasswordNewPasswordViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.changePasswordNewPasswordViewController
    }
}

// MARK: - ChangePasswordNewPasswordViewModelCoordinatorDelegate
extension ChangePasswordNewPasswordCoordinator: ChangePasswordNewPasswordViewModelCoordinatorDelegate {
    func changePasswordNewPasswordViewModelWantsToModifyCurrentPassword(_ viewModel: ChangePasswordNewPasswordViewModelType) {
        self.delegate?.changePasswordNewPasswordCoordinatorWantsToModifyCurrentPassword(self)
    }
    
    
    func changePasswordNewPasswordViewModelDidComplete(_ viewModel: ChangePasswordNewPasswordViewModelType) {
        self.delegate?.changePasswordNewPasswordCoordinatorDidComplete(self)
    }
    
    func changePasswordNewPasswordViewModelDidCancel(_ viewModel: ChangePasswordNewPasswordViewModelType) {
        self.delegate?.changePasswordNewPasswordCoordinatorDidCancel(self)
    }
}
