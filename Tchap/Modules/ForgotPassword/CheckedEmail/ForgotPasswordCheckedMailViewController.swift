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

protocol ForgotPasswordCheckedEmailViewControllerDelegate: AnyObject {
    func forgotPasswordCheckedEmailViewControllerDidTapDoneButton(_ forgotPasswordCheckedEmailViewController: ForgotPasswordCheckedEmailViewController)
}

final class ForgotPasswordCheckedEmailViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var instructionsLabel: UILabel!
    @IBOutlet private weak var doneButton: UIButton!
    
    // MARK: Private
    
    private var theme: Theme!
    
    // MARK: Public
    
    weak var delegate: ForgotPasswordCheckedEmailViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate() -> ForgotPasswordCheckedEmailViewController {
        return StoryboardScene.ForgotPasswordCheckedEmailViewController.initialScene.instantiate()
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationItem.setHidesBackButton(true, animated: animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeService.shared().theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        self.instructionsLabel.text = TchapL10n.forgotPasswordCheckedEmailInstructions
        self.doneButton.setTitle(TchapL10n.forgotPasswordCheckedEmailDoneAction, for: .normal)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    // MARK: - Actions
    
    @IBAction private func confirmationButtonAction(_ sender: Any) {
        self.delegate?.forgotPasswordCheckedEmailViewControllerDidTapDoneButton(self)
    }
}

// MARK: - Theme
private extension ForgotPasswordCheckedEmailViewController {
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.backgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.instructionsLabel.textColor = theme.textSecondaryColor
        
        theme.applyStyle(onButton: self.doneButton)
    }
}
