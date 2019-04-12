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

struct RoomCreationFormResult {
    let name: String
    let isPublic: Bool
    let isFederated: Bool
}

protocol RoomCreationViewControllerDelegate: class {
    func roomCreationViewControllerDidTapAddAvatarButton(_ roomCreationViewController: RoomCreationViewController)
    func roomCreationViewController(_ roomCreationViewController: RoomCreationViewController, didTapNextButtonWith roomCreationFormResult: RoomCreationFormResult)
}

/// RoomCreationViewController enables to create a new room.
final class RoomCreationViewController: UIViewController {

    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var avatarContentView: UIView!
    @IBOutlet private weak var roomNameFormTextField: FormTextField!
    
    @IBOutlet private weak var publicVisibilityTitleLabel: UILabel!
    @IBOutlet private weak var publicVisibilitySwitch: UISwitch!
    
    @IBOutlet private weak var publicVisibilityInfoLabel: UILabel!
    
    @IBOutlet private weak var publicRoomFederationStackView: UIStackView!
    @IBOutlet private weak var publicRoomFederationTitleLabel: UILabel!
    @IBOutlet private weak var disablePublicRoomFederationSwitch: UISwitch!
    
    // MARK: Private
    
    private var currentStyle: Style!
    private var viewModel: RoomCreationViewModelType!
    private var keyboardAvoider: KeyboardAvoider?
    
    private weak var nextBarButtonItem: UIBarButtonItem?
    private weak var roomCreationAvatarView: RoomCreationAvatarView?
    
    // MARK: Public
    
    weak var delegate: RoomCreationViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate(viewModel: RoomCreationViewModelType, style: Style = Variant1Style.shared) -> RoomCreationViewController {
        let viewController = StoryboardScene.RoomCreationViewController.initialScene.instantiate()
        viewController.currentStyle = style
        viewController.viewModel = viewModel
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.setupViews()
        self.scrollView.keyboardDismissMode = .interactive
        self.keyboardAvoider = KeyboardAvoider(scrollViewContainerView: self.view, scrollView: self.scrollView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.update(style: self.currentStyle)
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
    
    func updateAvatar(with image: UIImage) {
        self.roomCreationAvatarView?.updateAvatar(with: image)
    }
    
    // MARK: - Private
    
    private func setupViews() {
        
        self.title = TchapL10n.roomCreationTitle
        
        self.setupNavigationBar()
        
        self.setupRoomAvatarCreationView()
        self.setupRoomNameFormTextField()
        
        self.publicVisibilitySwitch.isOn = self.viewModel.isPublic
        self.enablePublicVisibility(self.viewModel.isPublic)
        
        self.publicVisibilityTitleLabel.text = TchapL10n.roomCreationPublicVisibilityTitle
        self.publicVisibilityInfoLabel.text = TchapL10n.roomCreationPublicVisibilityInfo
        
        self.disablePublicRoomFederationSwitch.isOn = !self.viewModel.isFederated
        
        self.publicRoomFederationTitleLabel.text = TchapL10n.roomCreationPublicRoomFederationTitle(self.viewModel.homeServerDomain)
    }
    
    private func setupNavigationBar() {
        let nextBarButtonItem = MXKBarButtonItem(title: TchapL10n.actionNext, style: .plain, action: {
            self.nextButtonAction()
        })
        
        self.navigationItem.rightBarButtonItem = nextBarButtonItem
        self.nextBarButtonItem = nextBarButtonItem
    }
    
    private func setupRoomAvatarCreationView() {
        let roomCreationAvatarView = RoomCreationAvatarView.loadFromNib()
        roomCreationAvatarView.delegate = self
        self.avatarContentView.tc_addSubViewMathingParent(roomCreationAvatarView)
        self.roomCreationAvatarView = roomCreationAvatarView
    }
    
    private func setupRoomNameFormTextField() {
        self.roomNameFormTextField.fill(formTextViewModel: self.viewModel.roomNameFormTextViewModel)
        self.roomNameFormTextField.delegate = self
        
        self.viewModel.roomNameFormTextViewModel.valueDidUpdate = { [weak self] (text, _) in
            self?.roomNameDidChange(with: text)
        }
        
        self.roomNameDidChange(with: self.viewModel.roomNameFormTextViewModel.value)
    }
    
    private func highlightPublicVisibilityInfoLabel(_ highlight: Bool) {
        self.publicVisibilityInfoLabel.textColor = highlight ? self.currentStyle.warnTextColor : self.currentStyle.secondaryTextColor
    }
    
    private func enablePublicVisibility(_ publicVisibilityEnabled: Bool) {
        self.publicRoomFederationStackView.isHidden = !publicVisibilityEnabled
        self.viewModel.isPublic = publicVisibilityEnabled
        self.highlightPublicVisibilityInfoLabel(publicVisibilityEnabled)
        
        if publicVisibilityEnabled == false {
            self.disablePublicRoomFederation(false)
            self.disablePublicRoomFederationSwitch.isOn = false
        }
    }
    
    private func disablePublicRoomFederation(_ publicRoomFederationDisabled: Bool) {
        self.viewModel.isFederated = !publicRoomFederationDisabled
    }
    
    private func roomNameDidChange(with text: String?) {
        let enableNextButton: Bool
        
        if let text = text, text.isEmpty == false {
            enableNextButton = true
        } else {
            enableNextButton = false
        }
        
        self.nextBarButtonItem?.isEnabled = enableNextButton
    }
    
    // MARK: - Actions
    
    private func nextButtonAction() {
        self.view.endEditing(true)
        
        if let roomName = self.viewModel.roomNameFormTextViewModel.value {
            let roomCreationFormResult = RoomCreationFormResult(name: roomName, isPublic: self.viewModel.isPublic, isFederated: self.viewModel.isFederated)
            self.delegate?.roomCreationViewController(self, didTapNextButtonWith: roomCreationFormResult)
        }
    }
    
    @IBAction private func publicVisibilitySwitchAction(_ sender: UISwitch) {
        self.enablePublicVisibility(sender.isOn)
    }
    
    @IBAction private func disablePublicRoomFederationSwitchAction(_ sender: UISwitch) {
        self.disablePublicRoomFederation(sender.isOn)
    }
}

// MARK: - Stylable
extension RoomCreationViewController: Stylable {
    func update(style: Style) {
        self.currentStyle = style
        
        self.view.backgroundColor = style.backgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            style.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.roomNameFormTextField.update(style: style)
        self.publicVisibilityTitleLabel.textColor = style.primarySubTextColor
        self.publicVisibilityInfoLabel.textColor = style.secondaryTextColor
        self.publicRoomFederationTitleLabel.textColor = style.primarySubTextColor
        
        style.applyStyle(onSwitch: self.publicVisibilitySwitch)
        style.applyStyle(onSwitch: self.disablePublicRoomFederationSwitch)
    }
}

// MARK: - FormTextFieldDelegate
extension RoomCreationViewController: FormTextFieldDelegate {
    
    func formTextFieldShouldReturn(_ formTextField: FormTextField) -> Bool {
        _ = formTextField.resignFirstResponder()
        return false
    }
}

// MARK: - RoomCreationAvatarViewDelegate
extension RoomCreationViewController: RoomCreationAvatarViewDelegate {
    
    func roomCreationAvatarViewDidTapAddPhotoButton(_ roomCreationAvatarView: RoomCreationAvatarView) {
        self.delegate?.roomCreationViewControllerDidTapAddAvatarButton(self)
    }
}
