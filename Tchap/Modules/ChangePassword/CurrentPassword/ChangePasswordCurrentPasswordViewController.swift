/*
 Copyright 2019 New Vector Ltd
 
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

final class ChangePasswordCurrentPasswordViewController: UIViewController {           
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var instructionsLabel: UILabel!
    @IBOutlet private weak var passwordFormTextField: FormTextField!
    @IBOutlet private weak var validateButton: UIButton!
    
    // MARK: Private

    private var viewModel: ChangePasswordCurrentPasswordViewModelType!
    private var style: Style!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: ErrorPresenter!
    private var activityPresenter: ActivityIndicatorPresenter!

    // MARK: - Setup
    
    class func instantiate(with viewModel: ChangePasswordCurrentPasswordViewModelType, style: Style = Variant2Style.shared) -> ChangePasswordCurrentPasswordViewController {
        let viewController = StoryboardScene.ChangePasswordCurrentPasswordViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.style = style
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.title = TchapL10n.changePasswordCurrentPasswordTitle
        
        self.tc_removeBackTitle()
        
        self.setupViews()
        self.keyboardAvoider = KeyboardAvoider(scrollViewContainerView: self.view, scrollView: self.scrollView)
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = AlertErrorPresenter(viewControllerPresenter: self)
        
        self.viewModel.viewDelegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)                
        
        self.themeDidChange()
        self.keyboardAvoider?.startAvoiding()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.keyboardAvoider?.stopAvoiding()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.style.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(style: Style) {
        self.style = style
        
        self.view.backgroundColor = style.backgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            style.applyStyle(onNavigationBar: navigationBar)
        }
                
        self.instructionsLabel.textColor = style.secondaryTextColor
        self.passwordFormTextField.update(style: style)
        
        style.applyStyle(onButton: self.validateButton)
    }
    
    private func themeDidChange() {
        self.update(style: self.style)
    }
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: TchapL10n.actionCancel, style: .plain) { [weak self] in
            self?.cancelButtonAction()
        }
        
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        self.scrollView.keyboardDismissMode = .interactive
        
        self.instructionsLabel.text = TchapL10n.changePasswordCurrentPasswordInstructions
        
        self.setupFormTextFields()
        
        self.validateButton.setTitle(TchapL10n.changePasswordCurrentPasswordValidateAction, for: .normal)
    }
    
    private func setupFormTextFields() {
        self.passwordFormTextField.fill(formTextViewModel: self.viewModel.passwordFormTextViewModel)
        self.passwordFormTextField.delegate = self
    }

    private func render(viewState: ChangePasswordCurrentPasswordViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded:
            self.renderLoaded()
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderLoaded() {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        var errorMessage: String?
        
        if let changeCurrentPasswordVMError = error as? ChangePasswordCurrentPasswordViewModelError,
            case .missingPassword = changeCurrentPasswordVMError {
            errorMessage = TchapL10n.authenticationErrorMissingPassword
        } else {
            let builder = MXKErrorPresentableBuilder()
            if let mxkErrorPresentable = builder.errorPresentable(fromError: error) {
                errorMessage = mxkErrorPresentable.message
            }
        }
        
        if let errorMessage = errorMessage {
            let errorTitle = TchapL10n.errorTitleDefault
            
            let errorPresentable = ErrorPresentableImpl(title: errorTitle, message: errorMessage)
            self.errorPresenter.present(errorPresentable: errorPresentable, animated: true)
        }
    }

    
    // MARK: - Actions

    @IBAction private func validateButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .validate)
    }

    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
    }
}


// MARK: - ChangePasswordCurrentPasswordViewModelViewDelegate
extension ChangePasswordCurrentPasswordViewController: ChangePasswordCurrentPasswordViewModelViewDelegate {

    func changePasswordCurrentPasswordViewModel(_ viewModel: ChangePasswordCurrentPasswordViewModelType, didUpdateViewState viewSate: ChangePasswordCurrentPasswordViewState) {
        self.render(viewState: viewSate)
    }
}

// MARK: - FormTextFieldDelegate
extension ChangePasswordCurrentPasswordViewController: FormTextFieldDelegate {
    
    func formTextFieldShouldReturn(_ formTextField: FormTextField) -> Bool {
        self.viewModel.process(viewAction: .validate)        
        return false
    }
}
