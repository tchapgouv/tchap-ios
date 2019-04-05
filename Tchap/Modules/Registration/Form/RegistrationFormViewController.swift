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

protocol RegistrationFormViewControllerDelegate: class {
    func registrationFormViewController(_ registrationFormViewController: RegistrationFormViewController, didTapNextButtonWith mail: String, password: String)
}

final class RegistrationFormViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var loginFormTextField: FormTextField!
    @IBOutlet private weak var passwordFormTextField: FormTextField!
    @IBOutlet private weak var confirmPasswordFormTextField: FormTextField!
    
    private var formTextFields: [FormTextField] = []
    
    // MARK: Private
    
    private var viewModel: RegistrationFormViewModelType!
    private var errorPresenter: ErrorPresenter?
    private var keyboardAvoider: KeyboardAvoider?
    private var currentStyle: Style!
    
    // MARK: Public
    
    weak var delegate: RegistrationFormViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate(viewModel: RegistrationFormViewModelType, style: Style = Variant2Style.shared) -> RegistrationFormViewController {
        let viewController = StoryboardScene.RegistrationFormViewController.initialScene.instantiate()
        viewController.currentStyle = style
        viewController.viewModel = viewModel
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.title = TchapL10n.registrationTitle
        
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
    }
    
    private func setupFormTextFields() {
        self.loginFormTextField.fill(formTextViewModel: viewModel.loginTextViewModel)
        self.passwordFormTextField.fill(formTextViewModel: viewModel.passwordTextViewModel)
        self.confirmPasswordFormTextField.fill(formTextViewModel: viewModel.confirmPasswordTextViewModel)
        
        let formTextFields: [FormTextField] = [
            self.loginFormTextField,
            self.passwordFormTextField,
            self.confirmPasswordFormTextField
        ]
        
        for formTextField in formTextFields {
            formTextField.delegate = self
        }
        
        self.formTextFields = formTextFields
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
            self.delegate?.registrationFormViewController(self, didTapNextButtonWith: authenticationFields.login, password: authenticationFields.password)
        case .failure(let errorPresentable):
            self.errorPresenter?.present(errorPresentable: errorPresentable)
        }
    }
}

// MARK: - Stylable
extension RegistrationFormViewController: Stylable {
    func update(style: Style) {
        self.currentStyle = style
        
        self.view.backgroundColor = style.backgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            style.applyStyle(onNavigationBar: navigationBar)
        }
        
        for formTextield in self.formTextFields {
            formTextield.update(style: style)
        }
    }
}

// MARK: - FormTextFieldDelegate
extension RegistrationFormViewController: FormTextFieldDelegate {
    
    func formTextFieldShouldReturn(_ formTextField: FormTextField) -> Bool {
        guard let index = self.formTextFields.index(of: formTextField) else {
            return false
        }
        
        let nextIndex = index+1
        
        if nextIndex > self.formTextFields.count - 1 {
            _ = formTextField.resignFirstResponder()
            self.submitForm()
        } else {
            _ = self.formTextFields[nextIndex].becomeFirstResponder()
        }
        
        return false
    }
}
