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
final class RoomCreationViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // MARK: - Constants
    
    private enum Constants {
        static let hexagonBorderWidthDefault: CGFloat = 1.0
        static let hexagonBorderWidthUnrestricted: CGFloat = 10.0
        static let roomRetentionPeriodMin: Int = 1
        static let roomRetentionPeriodMax: Int = 365
    }

    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var avatarContentView: UIView!
    @IBOutlet private weak var roomNameFormTextField: FormTextField!
    
    @IBOutlet private weak var roomRetentionLabel: UILabel!
    @IBOutlet private weak var roomRetentionPeriodPicker: UIPickerView!
    
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
    private var retentionPeriodValuesNb: Int!
    
    private weak var nextBarButtonItem: UIBarButtonItem?
    private weak var roomCreationAvatarView: RoomCreationAvatarView?
    
    // MARK: Public
    
    weak var delegate: RoomCreationViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate(viewModel: RoomCreationViewModelType, style: Style = Variant1Style.shared) -> RoomCreationViewController {
        let viewController = StoryboardScene.RoomCreationViewController.initialScene.instantiate()
        viewController.currentStyle = style
        viewController.viewModel = viewModel
        viewController.retentionPeriodValuesNb = (Constants.roomRetentionPeriodMax - Constants.roomRetentionPeriodMin + 1)
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
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        // Make the picker wrap around by adding a set of values before and after -> 3 sets
        return 3 * self.retentionPeriodValuesNb
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(row % self.retentionPeriodValuesNb + 1)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.setRetentionPeriodInDays((uint)(row % self.retentionPeriodValuesNb + 1))
    }
    
    // MARK: - Private
    
    private func setupViews() {
        
        self.title = TchapL10n.roomCreationTitle
        
        self.setupNavigationBar()
        
        self.setupRoomAvatarCreationView()
        self.setupRoomNameFormTextField()
        
        #if ENABLE_ROOM_RETENTION
        self.setupRoomRetentionLabel()
        self.setupRoomRetentionPeriodPicker()
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
        self.avatarContentView.tc_addSubViewMathingParent(roomCreationAvatarView)
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
        self.roomRetentionLabel.textColor = self.currentStyle.primarySubTextColor
    }
    
    private func setupRoomRetentionPeriodPicker() {
        self.roomRetentionPeriodPicker.backgroundColor = self.currentStyle.backgroundColor
        
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
    
    private func hideRoomRetentionPeriodPicker(_ isHidden: Bool) {
        if isHidden {
            // Hide without animation because the animation is buggy...
            self.roomRetentionPeriodPicker.isHidden = true
        } else {
            UIView.animate(withDuration: 0.3) {
                self.roomRetentionPeriodPicker.isHidden = isHidden
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
        if self.roomRetentionPeriodPicker.isHidden == true {
            self.roomRetentionPeriodPicker.selectRow((Int)(self.viewModel.retentionPeriodInDays - 1) + self.retentionPeriodValuesNb, inComponent: 0, animated: false)
            self.hideRoomRetentionPeriodPicker(false)
        } else {
            self.hideRoomRetentionPeriodPicker(true)
        }
    }
    
    @IBAction private func mainViewTapGestureRecognizer(_ sender: UITapGestureRecognizer) {
        self.hideRoomRetentionPeriodPicker(true)
    }
    
    @IBAction private func roomAccessSwitchAction(_ sender: UISwitch) {
        self.allowExternalUsers(sender.isOn)
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
