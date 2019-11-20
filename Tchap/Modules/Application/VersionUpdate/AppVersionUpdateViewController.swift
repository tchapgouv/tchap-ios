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

protocol AppVersionUpdateViewControllerDelegate: class {
    func appVersionUpdateViewControllerDidTapCancelAction(_ appVersionUpdateViewController: AppVersionUpdateViewController)
    func appVersionUpdateViewControllerDidTapOpenAppStoreAction(_ appVersionUpdateViewController: AppVersionUpdateViewController)
}

final class AppVersionUpdateViewController: UIViewController {

    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var appStoreButton: UIButton!
    
    // MARK: Private
    
    private var viewModel: AppVersionUpdateViewModelType!
    private var style: Style!
    
    // MARK: Public
    
    weak var delegate: AppVersionUpdateViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate(with viewModel: AppVersionUpdateViewModelType, style: Style = Variant2Style.shared) -> AppVersionUpdateViewController {
        let viewController = StoryboardScene.AppVersionUpdateViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.style = style
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.themeDidChange()
    }
    
    // MARK: - Private
    
    private func update(style: Style) {
        self.style = style
        
        self.view.backgroundColor = style.backgroundColor
        
        self.messageLabel.textColor = self.style.primarySubTextColor
        style.applyStyle(onButton: self.cancelButton)
        style.applyStyle(onButton: self.appStoreButton)
    }
    
    private func themeDidChange() {
        self.update(style: self.style)
    }
    
    private func setupViews() {
        
        self.messageLabel.text = self.viewModel.message        
        
        if self.viewModel.showCancelAction == false {
            self.cancelButton.isHidden = true
        } else {
            let cancelButtonTitle = self.viewModel.displayOnce ? TchapL10n.appVersionUpdateIgnoreAction : TchapL10n.appVersionUpdateLaterAction
            self.cancelButton.setTitle(cancelButtonTitle, for: .normal)
        }
        
        if self.viewModel.showOpenAppStoreAction == false {
            self.appStoreButton.isHidden = true
        } else {
            self.appStoreButton.setTitle(TchapL10n.appVersionUpdateOpenAppStoreAction, for: .normal)
        }
    }
    
    // MARK: - Actions
    
    @IBAction private func cancelButtonAction(_ sender: Any) {
        self.delegate?.appVersionUpdateViewControllerDidTapCancelAction(self)
    }
    
    @IBAction private func openAppStoreButtonAction(_ sender: Any) {
        self.delegate?.appVersionUpdateViewControllerDidTapOpenAppStoreAction(self)
    }
}
