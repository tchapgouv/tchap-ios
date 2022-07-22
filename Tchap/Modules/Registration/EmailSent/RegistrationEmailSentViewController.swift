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

protocol RegistrationEmailSentViewControllerDelegate: AnyObject {
    func registrationEmailSentViewControllerDidTapGoToLoginButton(_ registrationEmailSentViewController: RegistrationEmailSentViewController)
    func registrationEmailSentViewControllerDidTapEmailNotReceivedButton(_ registrationEmailSentViewController: RegistrationEmailSentViewController)
}

final class RegistrationEmailSentViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var emailSentInfoLabel: UILabel!
    @IBOutlet private weak var userEmailLabel: UILabel!
    @IBOutlet private weak var userInstructionsLabel: UILabel!
    @IBOutlet private weak var goToLoginButton: UIButton!
    @IBOutlet private weak var emailNotReceivedButton: UIButton!
    
    // MARK: Private
    
    private var userEmail: String!
    private var theme: Theme!
    
    // MARK: Public
    
    weak var delegate: RegistrationEmailSentViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate(userEmail: String) -> RegistrationEmailSentViewController {
        let viewController = StoryboardScene.RegistrationEmailSentViewController.initialScene.instantiate()
        viewController.userEmail = userEmail
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.title = TchapL10n.registrationTitle
        
        self.setupViews()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.theme = ThemeService.shared().theme
        self.update(theme: self.theme)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeService.shared().theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        self.emailSentInfoLabel.text = TchapL10n.registrationEmailSentInfo
        self.userEmailLabel.text = self.userEmail
        self.userInstructionsLabel.text = TchapL10n.registrationEmailSentInstructions
        self.goToLoginButton.setTitle(TchapL10n.registrationEmailLoginAction, for: .normal)
        self.emailNotReceivedButton.setTitle(TchapL10n.registrationEmailNotReceivedAction, for: .normal)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    // MARK: - Actions
    
    @IBAction private func goToLoginButtonAction(_ sender: Any) {
        self.delegate?.registrationEmailSentViewControllerDidTapGoToLoginButton(self)
    }
    
    @IBAction private func emailNotReceivedButtonAction(_ sender: Any) {
        self.delegate?.registrationEmailSentViewControllerDidTapEmailNotReceivedButton(self)
    }
}

// MARK: - Theme
private extension RegistrationEmailSentViewController {
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.backgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.emailSentInfoLabel.textColor = theme.textTertiaryColor
        self.userEmailLabel.textColor = theme.textSecondaryColor
        self.userInstructionsLabel.textColor = theme.textTertiaryColor
        
        theme.applyStyle(onButton: self.goToLoginButton)
        theme.applyStyle(onButton: self.emailNotReceivedButton)
    }
}
