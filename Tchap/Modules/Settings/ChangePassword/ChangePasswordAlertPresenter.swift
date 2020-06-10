/*
 Copyright 2020 New Vector Ltd
 
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

@objc protocol ChangePasswordAlertPresenterDelegate: class {
    func changePasswordAlertPresenterDidTapChangePasswordAction(_ presenter: ChangePasswordAlertPresenter)
    func changePasswordAlertPresenterDidTapBackupAction(_ presenter: ChangePasswordAlertPresenter)
}

@objcMembers
final class ChangePasswordAlertPresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private weak var presentingViewController: UIViewController?
    private weak var sourceView: UIView?
    
    // MARK: Public
    
    weak var delegate: ChangePasswordAlertPresenterDelegate?
    
    // MARK: - Public
    
    func present(for keyBackupState: MXKeyBackupState,
                 areThereKeysToBackup: Bool,
                 from viewController: UIViewController,
                 sourceView: UIView?,
                 animated: Bool) {
        self.sourceView = sourceView
        self.presentingViewController = viewController
        
        guard areThereKeysToBackup else {
            // If there is no keys to backup do not mention key backup and go to the change password.
            self.delegate?.changePasswordAlertPresenterDidTapChangePasswordAction(self)
            return
        }
                
        switch keyBackupState {
        case MXKeyBackupStateUnknown, MXKeyBackupStateDisabled, MXKeyBackupStateCheckingBackUpOnHomeserver:
            self.presentNonExistingBackupAlert(animated: animated)
        case MXKeyBackupStateWillBackUp, MXKeyBackupStateBackingUp:
            self.presentBackupInProgressAlert(animated: animated)
        default:
            // Change password without prompting the user when the backup is ready
            self.delegate?.changePasswordAlertPresenterDidTapChangePasswordAction(self)
        }
    }
    
    // MARK: - Private
    
    private func presentNonExistingBackupAlert(animated: Bool) {
        let alertContoller = UIAlertController(title: TchapL10n.settingsChangePwdNonExistingKeyBackupAlertTitle,
                                               message: nil,
                                               preferredStyle: .actionSheet)
        
        let changePasswordAction = UIAlertAction(title: TchapL10n.settingsChangePwdNonExistingKeyBackupAlertDiscardKeyBackupAction, style: .default) { (_) in
            self.delegate?.changePasswordAlertPresenterDidTapChangePasswordAction(self)
        }
        
        let setUpKeyBackupAction = UIAlertAction(title: TchapL10n.settingsChangePwdNonExistingKeyBackupAlertSetupKeyBackupAction, style: .default) { (_) in
            self.delegate?.changePasswordAlertPresenterDidTapBackupAction(self)
        }
        
        let cancelAction = UIAlertAction(title: VectorL10n.cancel, style: .cancel, handler: nil)
        
        alertContoller.addAction(changePasswordAction)
        alertContoller.addAction(setUpKeyBackupAction)
        alertContoller.addAction(cancelAction)
        
        self.present(alertController: alertContoller, animated: animated)
    }
    
    private func presentBackupInProgressAlert(animated: Bool) {
        let alertContoller = UIAlertController(title: TchapL10n.settingsChangePwdKeyBackupInProgressAlertTitle,
                                               message: nil,
                                               preferredStyle: .actionSheet)
        
        let discardKeyBackupAction = UIAlertAction(title: TchapL10n.settingsChangePwdKeyBackupInProgressAlertDiscardKeyBackupAction, style: .default) { (_) in
            self.delegate?.changePasswordAlertPresenterDidTapChangePasswordAction(self)
        }
        
        let cancelAction = UIAlertAction(title: TchapL10n.settingsChangePwdKeyBackupInProgressAlertCancelAction, style: .cancel, handler: nil)
        
        alertContoller.addAction(discardKeyBackupAction)
        alertContoller.addAction(cancelAction)
        
        self.present(alertController: alertContoller, animated: animated)
    }
    
    private func present(alertController: UIAlertController, animated: Bool) {
        
        // Configure source view when alert controller is presented with a popover
        if let sourceView = self.sourceView, let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.sourceView = sourceView
            popoverPresentationController.sourceRect = sourceView.bounds
            popoverPresentationController.permittedArrowDirections = [.down, .up]
        }
        
        self.presentingViewController?.present(alertController, animated: animated, completion: nil)
    }
}
