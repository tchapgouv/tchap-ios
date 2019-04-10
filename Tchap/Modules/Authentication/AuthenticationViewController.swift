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

import UIKit

protocol AuthenticationViewControllerDelegate: class {
    func authenticationViewController(_ authenticationViewController: AuthenticationViewController, didTapNextButtonWith mail: String, password: String)
    func authenticationViewControllerDidTapForgotPasswordButton(_ authenticationViewController: AuthenticationViewController)
}

final class AuthenticationViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var loginFormTextField: FormTextField!
    @IBOutlet private weak var passwordFormTextField: FormTextField!
    @IBOutlet private weak var forgotPasswordButton: UIButton!
    
    // MARK: Private
    
    private var viewModel: AuthenticationViewModelType!
    private var errorPresenter: ErrorPresenter?
    private var keyboardAvoider: KeyboardAvoider?
    private var currentStyle: Style!
    
    // MARK: Public
    
    weak var delegate: AuthenticationViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate(viewModel: AuthenticationViewModelType, style: Style = Variant2Style.shared) -> AuthenticationViewController {
        let viewController = StoryboardScene.AuthenticationViewController.initialScene.instantiate()
        viewController.currentStyle = style
        viewController.viewModel = viewModel
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.title = TchapL10n.authenticationTitle
        
        self.setupViews()
        self.errorPresenter = AlertErrorPresenter(viewControllerPresenter: self)
        self.keyboardAvoider = KeyboardAvoider(scrollViewContainerView: self.view, scrollView: self.scrollView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.userThemeDidChange()
        self.keyboardAvoider?.startAvoiding()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.view.endEditing(true)
        self.keyboardAvoider?.stopAvoiding()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.currentStyle.statusBarStyle
    }
    
    // MARK: - Public
            
    func setUserInteraction(enabled: Bool) {
        self.view.isUserInteractionEnabled = enabled
        self.navigationItem.rightBarButtonItem?.isEnabled = enabled
    }
    
    // MARK: - Private
    
    private func setupViews() {
        
        self.navigationItem.rightBarButtonItem = MXKBarButtonItem(title: TchapL10n.actionNext, style: .plain, action: {
            self.submitForm()
        })
        
        self.scrollView.keyboardDismissMode = .interactive
        
        self.setupFormTextFields()
        
        self.forgotPasswordButton.setTitle(TchapL10n.authenticationForgotPassword, for: .normal)
    }
    
    private func setupFormTextFields() {
        self.loginFormTextField.fill(formTextViewModel: viewModel.loginTextViewModel)
        self.loginFormTextField.delegate = self
        self.passwordFormTextField.fill(formTextViewModel: viewModel.passwordTextViewModel)
        self.passwordFormTextField.delegate = self
    }
    
    private func userThemeDidChange() {
        self.update(style: self.currentStyle)
    }
    
    // MARK: - Actions
    
    private func submitForm() {
        self.view.endEditing(true)
        
        let formValidationResult = self.viewModel.validateForm()
        
        switch formValidationResult {
        case .success(let authenticationFields):
            self.delegate?.authenticationViewController(self, didTapNextButtonWith: authenticationFields.login, password: authenticationFields.password)
        case .failure(let errorPresentable):
            self.errorPresenter?.present(errorPresentable: errorPresentable)
        }
    }
    
    @IBAction private func forgotPasswordButtonAction(_ sender: Any) {
        self.delegate?.authenticationViewControllerDidTapForgotPasswordButton(self)
    }
}

// MARK: - Stylable
extension AuthenticationViewController: Stylable {
    func update(style: Style) {
        self.currentStyle = style
        
        self.view.backgroundColor = style.backgroundColor
        
        style.applyStyle(onButton: self.forgotPasswordButton)
        
        if let navigationBar = self.navigationController?.navigationBar {
            style.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.loginFormTextField.update(style: style)
        self.passwordFormTextField.update(style: style)
    }
}

// MARK: - FormTextFieldDelegate
extension AuthenticationViewController: FormTextFieldDelegate {

    func formTextFieldShouldReturn(_ formTextField: FormTextField) -> Bool {
        if formTextField == self.loginFormTextField {
            _ = self.passwordFormTextField?.becomeFirstResponder()
        } else {
            _ = formTextField.resignFirstResponder()
            self.submitForm()
        }
        
        return false
    }
    
    func formTextField(_ formTextField: FormTextField, hasBeenAutoFilled: Bool) {
        // Ignore
    }
}
