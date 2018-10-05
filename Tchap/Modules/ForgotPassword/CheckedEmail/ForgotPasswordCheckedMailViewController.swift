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

protocol ForgotPasswordCheckedEmailViewControllerDelegate: class {
    func forgotPasswordCheckedEmailViewControllerDidTapDoneButton(_ forgotPasswordCheckedEmailViewController: ForgotPasswordCheckedEmailViewController)
}

final class ForgotPasswordCheckedEmailViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var instructionsLabel: UILabel!
    @IBOutlet private weak var doneButton: UIButton!
    
    // MARK: Private
    
    private var currentStyle: Style!
    
    // MARK: Public
    
    weak var delegate: ForgotPasswordCheckedEmailViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate(style: Style = Variant2Style.shared) -> ForgotPasswordCheckedEmailViewController {
        let viewController = StoryboardScene.ForgotPasswordCheckedEmailViewController.initialScene.instantiate()
        viewController.currentStyle = style
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
        
        self.navigationItem.setHidesBackButton(true, animated: animated)
        
        self.userThemeDidChange()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.currentStyle.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        self.instructionsLabel.text = TchapL10n.forgotPasswordCheckedEmailInstructions
        self.doneButton.setTitle(TchapL10n.forgotPasswordCheckedEmailDoneAction, for: .normal)
    }
    
    private func userThemeDidChange() {
        self.update(style: self.currentStyle)
    }
    
    // MARK: - Actions
    
    @IBAction private func confirmationButtonAction(_ sender: Any) {
        self.delegate?.forgotPasswordCheckedEmailViewControllerDidTapDoneButton(self)
    }
}

// MARK: - Stylable
extension ForgotPasswordCheckedEmailViewController: Stylable {
    func update(style: Style) {
        self.currentStyle = style
        
        self.view.backgroundColor = style.backgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            style.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.instructionsLabel.textColor = style.secondaryTextColor
        
        style.applyStyle(onButton: self.doneButton)
    }
}
