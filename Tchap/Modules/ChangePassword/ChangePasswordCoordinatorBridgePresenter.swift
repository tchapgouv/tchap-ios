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

@objc protocol ChangePasswordCoordinatorBridgePresenterDelegate {
    func changePasswordCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: ChangePasswordCoordinatorBridgePresenter)
    func changePasswordCoordinatorBridgePresenterDelegateDidCancel(_ coordinatorBridgePresenter: ChangePasswordCoordinatorBridgePresenter)
}

/// ChangePasswordCoordinatorBridgePresenter enables to start ChangePasswordCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class ChangePasswordCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var coordinator: ChangePasswordCoordinator?
    
    // MARK: Public
    
    weak var delegate: ChangePasswordCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        super.init()
    }
    
    // MARK: - Public
    
    func present(from viewController: UIViewController, animated: Bool) {
        let changePasswordCoordinator = ChangePasswordCoordinator(session: self.session)
        changePasswordCoordinator.delegate = self
        viewController.present(changePasswordCoordinator.toPresentable(), animated: animated, completion: nil)
        changePasswordCoordinator.start()
        
        self.coordinator = changePasswordCoordinator
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let coordinator = self.coordinator else {
            return
        }
        coordinator.toPresentable().dismiss(animated: animated) {
            self.coordinator = nil

            if let completion = completion {
                completion()
            }
        }
    }
}

// MARK: - ChangePasswordCoordinatorDelegate
extension ChangePasswordCoordinatorBridgePresenter: ChangePasswordCoordinatorDelegate {
    
    func changePasswordCoordinatorDidComplete(_ coordinator: ChangePasswordCoordinatorType) {
        self.delegate?.changePasswordCoordinatorBridgePresenterDelegateDidComplete(self)
    }
    
    func changePasswordCoordinatorDidCancel(_ coordinator: ChangePasswordCoordinatorType) {
        self.delegate?.changePasswordCoordinatorBridgePresenterDelegateDidCancel(self)
    }
}
