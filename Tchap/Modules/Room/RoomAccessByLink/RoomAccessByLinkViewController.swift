/*
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

import Foundation

final class RoomAccessByLinkViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let animationDuration: TimeInterval = 0.3
    }
    
    // MARK: Outlets
    
    @IBOutlet private weak var roomAccessByLinkStatusLabel: UILabel!
    @IBOutlet private weak var roomAccessByLinkSwitch: UISwitch!
    @IBOutlet private weak var roomLinkView: UIView!
    @IBOutlet private weak var roomLinkInfoLabel: UILabel!
    @IBOutlet private weak var roomLinkBackgroundView: UIView!
    @IBOutlet private weak var roomLinkLabel: UILabel!
    @IBOutlet private weak var shareLinkButton: UIButton!
    
    // MARK: Private
    
    private var viewModel: RoomAccessByLinkViewModelType!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    
    // MARK: - Setup
    
    class func instantiate(viewModel: RoomAccessByLinkViewModelType) -> RoomAccessByLinkViewController {
        let viewController = StoryboardScene.RoomAccessByLinkViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        return viewController
    }
    
    // Temporary version used in ObjectiveC.
    @objc class func instantiate(session: MXSession, roomId: String) -> RoomAccessByLinkViewController {
        let model = RoomAccessByLinkViewModel(session: session, roomId: roomId, isForum: nil)
        return RoomAccessByLinkViewController.instantiate(viewModel: model)
    }
    
    deinit {
        self.viewModel.process(viewAction: .releaseData)
    }
        
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.viewModel.viewDelegate = self
        
        // Build title view
        let titleView = RoomTitleView()
//        titleView.fill(roomTitleViewModel: self.viewModel.titleViewModel)
        self.navigationItem.titleView = titleView
        
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.setupViews()
        
        self.viewModel.process(viewAction: .loadData)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.userThemeDidChange()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeService.shared().theme.statusBarStyle
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
                
        self.roomLinkBackgroundView.layer.cornerRadius = 8
    }
    
    // MARK: - Private
    
    private func userThemeDidChange() {
        self.updateTheme()
    }
    
    private func setupViews() {
        self.shareLinkButton.setTitle(TchapL10n.roomSettingsRoomAccessByLinkShare, for: .normal)
    }

    private func render(viewState: RoomAccessByLinkViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .enabled(let roomLink, let editable, let isUnrestrictedRoom):
            self.renderEnabled(roomLink: roomLink, isEditable: editable, isUnrestrictedRoom: isUnrestrictedRoom)
        case .disabled(let editable):
            self.renderDisabled(isEditable: editable)
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderEnabled(roomLink: String, isEditable: Bool, isUnrestrictedRoom: Bool) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        roomAccessByLinkStatusLabel.isHidden = false
        if isEditable {
            roomAccessByLinkStatusLabel.text = TchapL10n.roomSettingsEnableRoomAccessByLink
            roomAccessByLinkSwitch.isHidden = false
            roomAccessByLinkSwitch.isOn = true
        } else {
            roomAccessByLinkStatusLabel.text = TchapL10n.roomSettingsRoomAccessByLinkEnabled
            roomAccessByLinkSwitch.isHidden = true
        }
        
        roomLinkInfoLabel.isHidden = false
        if isUnrestrictedRoom {
            roomLinkInfoLabel.text = TchapL10n.roomSettingsEnableRoomAccessByLinkInfoOnWithLimitation
        } else {
            roomLinkInfoLabel.text = TchapL10n.roomSettingsEnableRoomAccessByLinkInfoOn
        }
        roomLinkBackgroundView.isHidden = false
        roomLinkLabel.text = roomLink
        shareLinkButton.isHidden = false
        self.setupRoomLinkTapGestureRecognizer()
    }
    
    private func renderDisabled(isEditable: Bool) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        roomAccessByLinkStatusLabel.isHidden = false
        if isEditable {
            roomAccessByLinkStatusLabel.text = TchapL10n.roomSettingsEnableRoomAccessByLink
            roomAccessByLinkSwitch.isHidden = false
            roomAccessByLinkSwitch.isOn = false
            roomLinkInfoLabel.isHidden = false
            roomLinkInfoLabel.text = TchapL10n.roomSettingsEnableRoomAccessByLinkInfoOff
        } else {
            roomAccessByLinkStatusLabel.text = TchapL10n.roomSettingsRoomAccessByLinkDisabled
            roomAccessByLinkSwitch.isHidden = true
            roomLinkInfoLabel.isHidden = true
        }
        
        roomLinkBackgroundView.isHidden = true
        shareLinkButton.isHidden = true
        self.removeRoomLinkTapGestureRecognizer()
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: {
            self.viewModel.process(viewAction: .loadData)
        })
    }
    
    // MARK: - Actions
    
    @IBAction private func roomAccessByLinkSwitchAction(_ sender: UISwitch) {
        if sender.isOn {
            self.viewModel.process(viewAction: .enable)
        } else {
            self.viewModel.process(viewAction: .disable)
        }
    }
    
    @IBAction private func shareLinkButtonAction(_ sender: Any) {
        guard let link = self.roomLinkLabel.text, !link.isEmpty else {
            MXLog.debug("[RoomAccessByLinkViewController] shareLinkButtonAction: no link to share")
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [link], applicationActivities: nil)
        activityViewController.modalTransitionStyle = .coverVertical
        activityViewController.popoverPresentationController?.sourceView = self.shareLinkButton
        activityViewController.popoverPresentationController?.sourceRect = self.shareLinkButton.bounds
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    private func setupRoomLinkTapGestureRecognizer() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(copyLink(_:)))
        self.roomLinkLabel.addGestureRecognizer(tapGestureRecognizer)
        self.roomLinkLabel.isUserInteractionEnabled = true
    }
    
    private func removeRoomLinkTapGestureRecognizer() {
        if let recognizer = self.roomLinkLabel.gestureRecognizers?.first {
            self.roomLinkLabel.removeGestureRecognizer(recognizer)
        }
    }
    
    @objc private func copyLink(_ gestureRecognizer: UITapGestureRecognizer) {
        UIPasteboard.general.string = self.roomLinkLabel.text
        // Make room link blink
        self.roomLinkLabel.alpha = 0.2
        UIView.animate(withDuration: Constants.animationDuration) {
            self.roomLinkLabel.alpha = 1
        }
    }
}

// MARK: - Theme
private extension RoomAccessByLinkViewController {
    func updateTheme() {
        self.view.backgroundColor = ThemeService.shared().theme.backgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            ThemeService.shared().theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.roomAccessByLinkStatusLabel.textColor = ThemeService.shared().theme.tintColor
        self.roomLinkInfoLabel.textColor = ThemeService.shared().theme.textSecondaryColor
        self.roomLinkLabel.textColor = ThemeService.shared().theme.headerTextPrimaryColor
        self.roomLinkBackgroundView.backgroundColor = ThemeService.shared().theme.headerBackgroundColor
        self.roomAccessByLinkSwitch.onTintColor = ThemeService.shared().theme.tintColor
        
        ThemeService.shared().theme.applyStyle(onButton: self.shareLinkButton)
    }
}

// MARK: - RoomAccessByLinkViewModelViewDelegate
extension RoomAccessByLinkViewController: RoomAccessByLinkViewModelViewDelegate {

    func roomAccessByLinkViewModel(_ viewModel: RoomAccessByLinkViewModelType, didUpdateViewState viewSate: RoomAccessByLinkViewState) {
        self.render(viewState: viewSate)
    }
}
