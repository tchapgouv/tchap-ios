/*
 Copyright 2018 New Vector Ltd
 Copyright 2020 New Vector Ltd
 
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
    let retentionPeriodInDays: uint
    let isRestricted: Bool
    let isPublic: Bool
    let isFederated: Bool
}

protocol RoomCreationViewControllerDelegate: class {
    func roomCreationViewControllerDidTapAddAvatarButton(_ roomCreationViewController: RoomCreationViewController)
    func roomCreationViewController(_ roomCreationViewController: RoomCreationViewController, didTapNextButtonWith roomCreationFormResult: RoomCreationFormResult)
}

/// RoomCreationViewController enables to create a new room.
final class RoomCreationViewController: UIViewController, RetentionPeriodInDaysPickerContentViewDelegate {
    
    // MARK: - Constants
    
    private enum Constants {
        static let animationDuration: TimeInterval = 0.3
        static let hexagonBorderWidthDefault: CGFloat = 1.0
        static let hexagonBorderWidthUnrestricted: CGFloat = 10.0
    }

    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var avatarContentView: UIView!
    @IBOutlet private weak var roomNameFormTextField: FormTextField!
    
    @IBOutlet private weak var roomRetentionLabel: UILabel!
    @IBOutlet private weak var retentionPeriodInDaysPicker: RetentionPeriodInDaysPickerContentView!
    
    @IBOutlet private weak var roomAccessTitleLabel: UILabel!
    @IBOutlet private weak var roomAccessSwitch: UISwitch!
    
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.hideRetentionPeriodPicker(true)
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
    
    func retentionPeriodInDaysPickerContentView(_ view: RetentionPeriodInDaysPickerContentView, didSelect period: uint) {
        self.setRetentionPeriodInDays(period)
    }
    
    // MARK: - Private
    
    private func setupViews() {
        
        self.title = TchapL10n.roomCreationTitle
        
        self.setupNavigationBar()
        
        self.setupRoomAvatarCreationView()
        self.setupRoomNameFormTextField()
        
        #if ENABLE_ROOM_RETENTION
        self.setupRoomRetentionLabel()
        self.setupRetentionPeriodPicker()
        self.setRetentionPeriodInDays(self.viewModel.retentionPeriodInDays)
        #else
        self.roomRetentionLabel.isHidden = true
        #endif
        
        self.roomAccessSwitch.isOn = !self.viewModel.isRestricted
        self.roomAccessTitleLabel.text = TchapL10n.roomCreationRoomAccessTitle
        
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
        self.avatarContentView.tc_addSubViewMatchingParent(roomCreationAvatarView)
        self.roomCreationAvatarView = roomCreationAvatarView
        refreshAvatarView()
    }
    
    private func setupRoomNameFormTextField() {
        self.roomNameFormTextField.fill(formTextViewModel: self.viewModel.roomNameFormTextViewModel)
        self.roomNameFormTextField.delegate = self
        
        self.viewModel.roomNameFormTextViewModel.valueDidUpdate = { [weak self] (text, _) in
            self?.roomNameDidChange(with: text)
        }
        
        self.roomNameDidChange(with: self.viewModel.roomNameFormTextViewModel.value)
    }
    
    private func setupRoomRetentionLabel() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(roomRetentionLabelTapGestureRecognizer(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.numberOfTouchesRequired = 1
        self.roomRetentionLabel.addGestureRecognizer(tapGestureRecognizer)
        self.roomRetentionLabel.isUserInteractionEnabled = true
    }
    
    private func setupRetentionPeriodPicker() {
        self.retentionPeriodInDaysPicker.delegate = self
        
        // Add a tap gesture recognizer on the main view to hide the picker (if any)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(mainViewTapGestureRecognizer(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.numberOfTouchesRequired = 1
        self.view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    private func highlightPublicVisibilityInfoLabel(_ highlight: Bool) {
        self.publicVisibilityInfoLabel.textColor = highlight ? self.currentStyle.warnTextColor : self.currentStyle.secondaryTextColor
    }
    
    private func enableRoomAccessOption(_ isEnabled: Bool) {
        self.roomAccessTitleLabel.textColor = isEnabled ? self.currentStyle.primarySubTextColor : self.currentStyle.secondaryTextColor
        self.roomAccessSwitch.isEnabled = isEnabled
        
        if !isEnabled {
            self.roomAccessSwitch.isOn = false
            self.viewModel.isRestricted = true
            self.roomCreationAvatarView?.setAvatarBorder(color: kColorDarkBlue, width: Constants.hexagonBorderWidthDefault)
        }
    }
    
    private func allowExternalUsers(_ isUnrestricted: Bool) {
        self.viewModel.isRestricted = !isUnrestricted
        refreshAvatarView()
    }
    
    private func refreshAvatarView() {
        let borderColor: UIColor
        let borderWidth: CGFloat
        if self.viewModel.isRestricted {
            borderColor = kColorDarkBlue
            borderWidth = Constants.hexagonBorderWidthDefault
        } else {
            borderColor = kColorDarkGrey
            borderWidth = Constants.hexagonBorderWidthUnrestricted
        }
        self.roomCreationAvatarView?.setAvatarBorder(color: borderColor, width: borderWidth)
    }
    
    private func setRetentionPeriodInDays(_ period: uint) {
        self.viewModel.retentionPeriodInDays = period
        
        let textLabel = period == 1 ? TchapL10n.roomCreationRoomRetentionPeriodOneDay : TchapL10n.roomCreationRoomRetentionPeriodDays(Int(period))
        let attributedTextLabel = NSMutableAttributedString(string: textLabel)
        let range = (textLabel as NSString).range(of: String(period))
        let underlineRange = NSRange(location: range.location, length: textLabel.count - range.location)
        attributedTextLabel.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: underlineRange)
        self.roomRetentionLabel.attributedText = attributedTextLabel
    }
    
    private func enablePublicVisibility(_ publicVisibilityEnabled: Bool) {
        self.enableRoomAccessOption(!publicVisibilityEnabled)
        self.publicRoomFederationStackView.isHidden = !publicVisibilityEnabled
        self.viewModel.isPublic = publicVisibilityEnabled
        self.highlightPublicVisibilityInfoLabel(publicVisibilityEnabled)
        
        if publicVisibilityEnabled == false {
            // Private rooms are all federated
            self.disableRoomFederation(false)
            self.disablePublicRoomFederationSwitch.isOn = false
        } else {
            // Public rooms are not federated by default
            self.disableRoomFederation(true)
            self.disablePublicRoomFederationSwitch.isOn = true
        }
    }
    
    private func disableRoomFederation(_ roomFederationDisabled: Bool) {
        self.viewModel.isFederated = !roomFederationDisabled
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
    
    private func hideRetentionPeriodPicker(_ isHidden: Bool) {
        if isHidden {
            // Hide without animation because the animation is buggy...
            self.retentionPeriodInDaysPicker.isHidden = true
        } else {
            UIView.animate(withDuration: Constants.animationDuration) {
                self.retentionPeriodInDaysPicker.isHidden = false
            }
        }
    }
    
    // MARK: - Actions
    
    private func nextButtonAction() {
        self.view.endEditing(true)
        
        if let roomName = self.viewModel.roomNameFormTextViewModel.value {
            let roomCreationFormResult = RoomCreationFormResult(name: roomName,
                                                                retentionPeriodInDays: self.viewModel.retentionPeriodInDays,
                                                                isRestricted: self.viewModel.isRestricted,
                                                                isPublic: self.viewModel.isPublic,
                                                                isFederated: self.viewModel.isFederated)
            self.delegate?.roomCreationViewController(self, didTapNextButtonWith: roomCreationFormResult)
        }
    }
    
    @IBAction private func roomRetentionLabelTapGestureRecognizer(_ sender: UITapGestureRecognizer) {
        if self.retentionPeriodInDaysPicker.isHidden == true {
            self.retentionPeriodInDaysPicker.scrollTo(retentionPeriodInDays: self.viewModel.retentionPeriodInDays, animated: false)
            self.hideRetentionPeriodPicker(false)
        } else {
            self.hideRetentionPeriodPicker(true)
        }
    }
    
    @IBAction private func mainViewTapGestureRecognizer(_ sender: UITapGestureRecognizer) {
        self.hideRetentionPeriodPicker(true)
    }
    
    @IBAction private func roomAccessSwitchAction(_ sender: UISwitch) {
        self.allowExternalUsers(sender.isOn)
    }
    
    @IBAction private func publicVisibilitySwitchAction(_ sender: UISwitch) {
        self.enablePublicVisibility(sender.isOn)
    }
    
    @IBAction private func disablePublicRoomFederationSwitchAction(_ sender: UISwitch) {
        self.disableRoomFederation(sender.isOn)
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
        self.roomRetentionLabel.textColor = style.primarySubTextColor
        self.retentionPeriodInDaysPicker.update(style: style)
        self.enableRoomAccessOption(!self.viewModel.isPublic)
        self.publicVisibilityTitleLabel.textColor = style.primarySubTextColor
        self.highlightPublicVisibilityInfoLabel(self.viewModel.isPublic)
        self.publicRoomFederationTitleLabel.textColor = style.primarySubTextColor
        
        style.applyStyle(onSwitch: self.roomAccessSwitch)
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
