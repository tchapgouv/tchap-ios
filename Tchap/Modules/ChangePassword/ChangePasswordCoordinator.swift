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

@objcMembers
final class ChangePasswordCoordinator: ChangePasswordCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    private let session: MXSession
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: ChangePasswordCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.navigationRouter = NavigationRouter(navigationController: TCNavigationController())
        self.session = session
    }    
    
    // MARK: - Public methods
    
    func start() {

        let rootCoordinator = self.createCurrentPasswordCoordinator()
        rootCoordinator.start()
        self.add(childCoordinator: rootCoordinator)

        self.navigationRouter.setRootModule(rootCoordinator)
      }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private methods

    private func createCurrentPasswordCoordinator() -> ChangePasswordCurrentPasswordCoordinatorType {
        let coordinator = ChangePasswordCurrentPasswordCoordinator(session: self.session)
        coordinator.delegate = self
        return coordinator
    }
    
    private func showNewPassword(using oldPassword: String) {
        
        guard let account = MXKAccountManager.shared()?.activeAccounts.first else {
            let alertPresenter = AlertErrorPresenter(viewControllerPresenter: self.navigationRouter.toPresentable())
            let errorPresentable = ErrorPresentableImpl(title: TchapL10n.errorTitleDefault, message: TchapL10n.errorMessageDefault)
            alertPresenter.present(errorPresentable: errorPresentable)
            return
        }
        
        let coordinator = ChangePasswordNewPasswordCoordinator(account: account, oldPassword: oldPassword)
        coordinator.delegate = self
        coordinator.start()
        
        self.navigationRouter.push(coordinator, animated: true) { [weak self] in
            guard let self = self else {
                return
            }
            self.remove(childCoordinator: coordinator)
        }
        self.add(childCoordinator: coordinator)
    }
}

// MARK: - TemplateScreenCoordinatorDelegate
extension ChangePasswordCoordinator: ChangePasswordCurrentPasswordCoordinatorDelegate {
    
    func changePasswordCurrentPasswordCoordinator(_ coordinator: ChangePasswordCurrentPasswordCoordinatorType, didCompleteWithCurrentPassword currentPasword: String) {
        self.showNewPassword(using: currentPasword)
    }
    
    func changePasswordCurrentPasswordCoordinatorDidCancel(_ coordinator: ChangePasswordCurrentPasswordCoordinatorType) {
        self.delegate?.changePasswordCoordinatorDidCancel(self)
    }
}

// MARK: - ChangePasswordNewPasswordCoordinatorDelegate
extension ChangePasswordCoordinator: ChangePasswordNewPasswordCoordinatorDelegate {
    
    func changePasswordNewPasswordCoordinatorWantsToModifyCurrentPassword(_ coordinator: ChangePasswordNewPasswordCoordinatorType) {
        self.navigationRouter.popModule(animated: true)
    }
    
    
    func changePasswordNewPasswordCoordinatorDidComplete(_ coordinator: ChangePasswordNewPasswordCoordinatorType) {
        self.delegate?.changePasswordCoordinatorDidComplete(self)
    }
    
    func changePasswordNewPasswordCoordinatorDidCancel(_ coordinator: ChangePasswordNewPasswordCoordinatorType) {
        self.delegate?.changePasswordCoordinatorDidCancel(self)
    }
}
