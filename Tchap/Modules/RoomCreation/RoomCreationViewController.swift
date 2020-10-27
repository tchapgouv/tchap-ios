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
    let roomType: RoomType
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
        static let borderColorAlpha: CGFloat = 0.7
        static let borderWidth: CGFloat = 4.0
    }

    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var avatarContentView: UIView!
    @IBOutlet private weak var roomNameFormTextField: FormTextField!
    
    @IBOutlet private weak var roomRetentionLabel: UILabel!
    @IBOutlet private weak var retentionPeriodInDaysPicker: RetentionPeriodInDaysPickerContentView!
    
    @IBOutlet private weak var publicVisibilityInfoLabel: UILabel!
    
    @IBOutlet private weak var publicRoomFederationStackView: UIStackView!
    @IBOutlet private weak var publicRoomFederationTitleLabel: UILabel!
    @IBOutlet private weak var disablePublicRoomFederationSwitch: UISwitch!
    
    @IBOutlet private weak var privateRoomView: UIView!
    @IBOutlet private weak var privateRoomTitleLabel: UILabel!
    @IBOutlet private weak var privateRoomImage: UIImageView!
    @IBOutlet private weak var privateRoomInfoLabel: UILabel!
    
    @IBOutlet private weak var externRoomView: UIView!
    @IBOutlet private weak var externRoomImage: UIImageView!
    @IBOutlet private weak var externRoomTitleLabel: UILabel!
    @IBOutlet private weak var externRoomInfoLabel: UILabel!
    
    @IBOutlet private weak var forumRoomView: UIView!
    @IBOutlet private weak var forumRoomTitleLabel: UILabel!
    @IBOutlet private weak var forumRoomInfoLabel: UILabel!
    
    @IBOutlet private weak var roomTypeTitleLabel: UILabel!
    @IBOutlet private weak var roomTypeImage: UIImageView!
    
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
        self.setupPrivateRoomView()
        self.setupExternRoomView()
        self.setupForumRoomView()
        
        #if ENABLE_ROOM_RETENTION
        self.setupRoomRetentionLabel()
        self.setupRetentionPeriodPicker()
        self.setRetentionPeriodInDays(self.viewModel.retentionPeriodInDays)
        #else
        self.roomRetentionLabel.isHidden = true
        #endif
        
        self.setupRoomType()
        
        self.publicVisibilityInfoLabel.text = TchapL10n.roomCreationPublicVisibilityInfo
        self.publicRoomFederationTitleLabel.text = TchapL10n.roomCreationPublicRoomFederationTitle(self.viewModel.homeServerDomain)
        
        self.roomTypeTitleLabel.text = TchapL10n.roomCreationRoomTypeTitle.uppercased()
    
        self.privateRoomTitleLabel.text = TchapL10n.roomTitlePrivateRoom
        self.privateRoomInfoLabel.text = TchapL10n.roomCreationPrivateRoomInfo
        
        self.externRoomTitleLabel.text = TchapL10n.roomTitleExternRoom
        self.externRoomInfoLabel.text = TchapL10n.roomCreationExternRoomInfo
        
        self.forumRoomTitleLabel.text = TchapL10n.roomTitleForumRoom
        self.forumRoomInfoLabel.text = TchapL10n.roomCreationForumRoomInfo
    }
    
    private func setupRoomType() {
        self.disablePrivateRoom()
        self.disableExternRoom()
        self.disableForumRoom()
        self.hideRetentionPeriodPicker(true)
        
        switch self.viewModel.selectedRoomType {
        case .privateRestricted:
            self.enablePrivateRoom()
        case .privateUnrestricted:
            self.enableExternRoom()
        case .forum(let isFederated):
            self.enableForumRoom(isFederated)
        }
        
        self.refreshAvatarView()
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
    
    private func setupPrivateRoomView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(privateRoomViewTapGestureRecognizer(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.numberOfTouchesRequired = 1
        self.privateRoomView.addGestureRecognizer(tapGestureRecognizer)
        self.privateRoomView.isUserInteractionEnabled = true
    }
    
    private func setupExternRoomView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(externRoomViewTapGestureRecognizer(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.numberOfTouchesRequired = 1
        self.externRoomView.addGestureRecognizer(tapGestureRecognizer)
        self.externRoomView.isUserInteractionEnabled = true
    }
    
    private func setupForumRoomView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(forumRoomViewTapGestureRecognizer))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.numberOfTouchesRequired = 1
        self.forumRoomView.addGestureRecognizer(tapGestureRecognizer)
        self.forumRoomView.isUserInteractionEnabled = true
    }
    
    private func refreshAvatarView() {
        let borderColor: UIColor
        let borderWidth: CGFloat
        if case .privateUnrestricted = self.viewModel.selectedRoomType {
            borderColor = kColorDarkGrey
            borderWidth = Constants.hexagonBorderWidthUnrestricted
        } else {
            borderColor = kColorDarkBlue
            borderWidth = Constants.hexagonBorderWidthDefault
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
    
    private func enablePrivateRoom() {
        self.privateRoomView.layer.borderWidth = Constants.borderWidth
        self.privateRoomView.layer.borderColor = kColorCoral.withAlphaComponent(Constants.borderColorAlpha).cgColor
        self.roomTypeImage.image = Asset.Images.privateAvatarIconHr.image
    }
    
    private func disablePrivateRoom() {
        self.privateRoomView.layer.borderWidth = 0
    }
    
    private func enableExternRoom() {
        self.externRoomView.layer.borderWidth = Constants.borderWidth
        self.externRoomView.layer.borderColor = kColorPumpkinOrange.withAlphaComponent(Constants.borderColorAlpha).cgColor
        self.roomTypeImage.image = Asset.Images.privateAvatarIconHr.image
    }
    
    private func disableExternRoom() {
        self.externRoomView.layer.borderWidth = 0
    }
    
    private func enableForumRoom(_ isFederated: Bool) {
        self.forumRoomView.layer.borderWidth = Constants.borderWidth
        self.forumRoomView.layer.borderColor = kColorJadeGreen.withAlphaComponent(Constants.borderColorAlpha).cgColor
        self.roomTypeImage.image = Asset.Images.forumAvatarIconHr.image
        
        self.publicVisibilityInfoLabel.isHidden = false
        self.publicRoomFederationStackView.isHidden = false
        self.disablePublicRoomFederationSwitch.isOn = !isFederated
    }
    
    private func disableForumRoom() {
        self.forumRoomView.layer.borderWidth = 0
        self.publicVisibilityInfoLabel.isHidden = true
        self.publicRoomFederationStackView.isHidden = true
    }
    
    // MARK: - Actions
    
    private func nextButtonAction() {
        self.view.endEditing(true)
        
        if let roomName = self.viewModel.roomNameFormTextViewModel.value {
            let roomCreationFormResult = RoomCreationFormResult(name: roomName,
                                                                retentionPeriodInDays: self.viewModel.retentionPeriodInDays,
                                                                roomType: self.viewModel.selectedRoomType)
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
    
    @IBAction private func privateRoomViewTapGestureRecognizer(_ sender: UITapGestureRecognizer) {
        self.viewModel.selectedRoomType = .privateRestricted()
        self.setupRoomType()
    }
    
    @IBAction private func externRoomViewTapGestureRecognizer(_ sender: UITapGestureRecognizer) {
        self.viewModel.selectedRoomType = .privateUnrestricted()
        self.setupRoomType()
    }
    
    @IBAction private func forumRoomViewTapGestureRecognizer(_ sender: UITapGestureRecognizer) {
        self.viewModel.selectedRoomType = .forum()
        self.setupRoomType()
    }
    
    @IBAction private func disablePublicRoomFederationSwitchAction(_ sender: UISwitch) {
        self.viewModel.selectedRoomType = .forum(isFederated: !sender.isOn)
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
        self.publicVisibilityInfoLabel.textColor = style.boxTextColor
        self.publicRoomFederationTitleLabel.textColor = style.boxTextColor

        let padLockimage = Asset.SharedImages.e2eVerified.image.withRenderingMode(.alwaysTemplate)
        
        self.privateRoomView.backgroundColor = kColorPaleGrey
        self.privateRoomTitleLabel.textColor = kColorCoral
        self.privateRoomImage.image = padLockimage
        self.privateRoomImage.tintColor = kColorCoral
        self.privateRoomInfoLabel.textColor = style.boxTextColor
        
        self.externRoomView.backgroundColor = kColorPaleGrey
        self.externRoomTitleLabel.textColor = kColorPumpkinOrange
        self.externRoomImage.image = padLockimage
        self.externRoomImage.tintColor = kColorPumpkinOrange
        self.externRoomInfoLabel.textColor = style.boxTextColor
        
        self.forumRoomView.backgroundColor = kColorPaleGrey
        self.forumRoomTitleLabel.textColor = kColorJadeGreen
        self.forumRoomInfoLabel.textColor = style.boxTextColor
        self.roomTypeTitleLabel.textColor = style.boxTextColor
        
        self.disablePublicRoomFederationSwitch.onTintColor = kColorJadeGreen
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
