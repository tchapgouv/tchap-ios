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

protocol RegistrationEmailSentViewControllerDelegate: class {
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
    private var currentStyle: Style!
    
    // MARK: Public
    
    weak var delegate: RegistrationEmailSentViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate(userEmail: String, style: Style = Variant2Style.shared) -> RegistrationEmailSentViewController {
        let viewController = StoryboardScene.RegistrationEmailSentViewController.initialScene.instantiate()
        viewController.currentStyle = style
        viewController.userEmail = userEmail
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.title = TchapL10n.registrationTitle
        
        self.setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.userThemeDidChange()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.currentStyle.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        self.emailSentInfoLabel.text = TchapL10n.registrationEmailSentInfo
        self.userEmailLabel.text = self.userEmail
        self.userInstructionsLabel.text = TchapL10n.registrationEmailSentInstructions
        self.goToLoginButton.setTitle(TchapL10n.registrationEmailLoginAction, for: .normal)
        self.emailNotReceivedButton.setTitle(TchapL10n.registrationEmailNotReceivedAction, for: .normal)
    }
    
    private func userThemeDidChange() {
        self.update(style: self.currentStyle)
    }
    
    // MARK: - Actions
    
    @IBAction private func goToLoginButtonAction(_ sender: Any) {
        self.delegate?.registrationEmailSentViewControllerDidTapGoToLoginButton(self)
    }
    
    @IBAction private func emailNotReceivedButtonAction(_ sender: Any) {
        self.delegate?.registrationEmailSentViewControllerDidTapEmailNotReceivedButton(self)
    }
}

// MARK: - Stylable
extension RegistrationEmailSentViewController: Stylable {
    func update(style: Style) {
        self.currentStyle = style
        
        self.view.backgroundColor = style.backgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            style.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.emailSentInfoLabel.textColor = style.primarySubTextColor
        self.userEmailLabel.textColor = style.secondaryTextColor
        self.userInstructionsLabel.textColor = style.primarySubTextColor
        
        style.applyStyle(onButton: self.goToLoginButton)
        style.applyStyle(onButton: self.emailNotReceivedButton)
    }
}
