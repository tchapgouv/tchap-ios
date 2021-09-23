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

protocol ForgotPasswordVerifyEmailViewControllerDelegate: AnyObject {
    func forgotPasswordVerifyEmailViewControllerDidTapConfirmationButton(_ forgotPasswordVerifyEmailViewController: ForgotPasswordVerifyEmailViewController)
}

final class ForgotPasswordVerifyEmailViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var instructionsLabel: UILabel!
    @IBOutlet private weak var confirmationButton: UIButton!
    
    // MARK: Private
    
    private var userEmail: String!
    
    // MARK: Public
    
    weak var delegate: ForgotPasswordVerifyEmailViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate(userEmail: String) -> ForgotPasswordVerifyEmailViewController {
        let viewController = StoryboardScene.ForgotPasswordVerifyEmailViewController.initialScene.instantiate()
        viewController.userEmail = userEmail
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.title = TchapL10n.forgotPasswordTitle
        
        self.setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.userThemeDidChange()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeService.shared().theme.statusBarStyle
    }
    
    // MARK: - Public
    
    func setUserInteraction(enabled: Bool) {
        self.view.isUserInteractionEnabled = enabled
    }
    
    // MARK: - Private
    
    private func setupViews() {
        self.instructionsLabel.text = TchapL10n.forgotPasswordVerifyEmailInstructions(self.userEmail)
        self.confirmationButton.setTitle(TchapL10n.forgotPasswordVerifyEmailConfirmationAction, for: .normal)
    }
    
    private func userThemeDidChange() {
        self.updateTheme()
    }
    
    // MARK: - Actions
    
    @IBAction private func confirmationButtonAction(_ sender: Any) {
        self.delegate?.forgotPasswordVerifyEmailViewControllerDidTapConfirmationButton(self)
    }
}

// MARK: - Theme
private extension ForgotPasswordVerifyEmailViewController {
    func updateTheme() {
        self.view.backgroundColor = ThemeService.shared().theme.backgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            ThemeService.shared().theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.instructionsLabel.textColor = ThemeService.shared().theme.textSecondaryColor
        
        ThemeService.shared().theme.applyStyle(onButton: self.confirmationButton)
    }
}
