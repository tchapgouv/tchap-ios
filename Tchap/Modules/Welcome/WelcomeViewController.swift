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

protocol WelcomeViewControllerDelegate: AnyObject {
    func welcomeViewControllerDidTapLoginButton(_ welcomeViewController: WelcomeViewController)
    func welcomeViewControllerDidTapRegisterButton(_ welcomeViewController: WelcomeViewController)
}

final class WelcomeViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var registerButton: UIButton!
    @IBOutlet private weak var loginButton: UIButton!
    @IBOutlet private weak var buttonsSeparatorView: UIView!
    
    // MARK: Private
    
    // MARK: Public
    
    weak var delegate: WelcomeViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate() -> WelcomeViewController {
        let viewController = StoryboardScene.WelcomeViewController.initialScene.instantiate()
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.title = TchapL10n.authenticationTitle
        
        self.setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        self.userThemeDidChange()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeService.shared().theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        self.titleLabel.text = TchapL10n.welcomeTitle
        
        self.registerButton.setTitle(TchapL10n.welcomeRegisterAction, for: .normal)
        self.registerButton.titleLabel?.numberOfLines = 0
        
        self.loginButton.setTitle(TchapL10n.welcomeLoginAction, for: .normal)
        self.loginButton.titleLabel?.numberOfLines = 0
    }
    
    private func userThemeDidChange() {
        self.updateTheme()
    }
    
    // MARK: - Actions
    
    @IBAction private func loginButtonAction(_ sender: Any) {
        self.delegate?.welcomeViewControllerDidTapLoginButton(self)
    }
    
    @IBAction private func registerButtonAction(_ sender: Any) {
        self.delegate?.welcomeViewControllerDidTapRegisterButton(self)
    }
}

// MARK: - Theme
private extension WelcomeViewController {
    func updateTheme() {
        self.view.backgroundColor = ThemeService.shared().theme.backgroundColor
        self.titleLabel.textColor = ThemeService.shared().theme.textTertiaryColor
        self.buttonsSeparatorView.backgroundColor = ThemeService.shared().theme.selectedBackgroundColor
        
        ThemeService.shared().theme.applyStyle(onButton: self.loginButton)
        ThemeService.shared().theme.applyStyle(onButton: self.registerButton)
    }
}
