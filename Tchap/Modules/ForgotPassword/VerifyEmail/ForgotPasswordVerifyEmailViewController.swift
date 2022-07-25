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
    private var theme: Theme!
    
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
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.theme = ThemeService.shared().theme
        self.update(theme: self.theme)
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
        self.confirmationButton.setTitle(TchapL10n.forgotPasswordVerifyEmailConfirmationAction, for: .normal)
        
        guard let email = self.userEmail else {
            return
        }
        self.instructionsLabel.text = TchapL10n.forgotPasswordVerifyEmailInstructions(email)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    // MARK: - Actions
    
    @IBAction private func confirmationButtonAction(_ sender: Any) {
        self.delegate?.forgotPasswordVerifyEmailViewControllerDidTapConfirmationButton(self)
    }
}

// MARK: - Theme
private extension ForgotPasswordVerifyEmailViewController {
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.backgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.instructionsLabel.textColor = theme.textSecondaryColor
        
        theme.applyStyle(onButton: self.confirmationButton)
    }
}
