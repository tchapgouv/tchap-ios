// File created from ScreenTemplate
// $ createScreen.sh KeyVerification KeyVerificationSelfVerifyWait
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

import UIKit

final class KeyVerificationSelfVerifyWaitViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let clientNamesLineSpacing: CGFloat = 3.0
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var desktopClientImageView: UIImageView!
    @IBOutlet private weak var mobileClientImageView: UIImageView!
        
    @IBOutlet private weak var recoverSecretsAvailabilityLoadingContainerView: UIView!
    @IBOutlet private weak var recoverSecretsAvailabilityLoadingLabel: UILabel!
    @IBOutlet private weak var recoverSecretsAvailabilityActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var recoverSecretsContainerView: UIView!
    @IBOutlet private weak var recoverSecretsButton: RoundedButton!
    @IBOutlet private weak var recoverSecretsAdditionalInformationLabel: UILabel!
    
    // Tchap: UI to enable user to cancel this view if no recover secrets method is available
    // It can happen on an account created before setting `secureBackupRequired` to true.
    // This account can have cross-signing activated but no more session connected (all devices disconnected).
    // The application will ask the user to verifiy the session with another device because cross-signing is activated.
    // But as no other device is still connected, the user has no way to perform the verification, 
    // because SecureBackup is not activated: we are in the process of activating it.
    @IBOutlet weak var tchapNoRecoverSecretsMethodAvailableContainerView: UIView!
    @IBOutlet weak var tchapNoRecoverSecretsMethodAvailableInformationLabel: UILabel!
    @IBOutlet weak var tchapNoRecoverSecretsMethodAvailableButton: RoundedButton!
    
    // Tchap: Quick access to Help FAQ specific article
    @IBOutlet weak var tchapQuickHelpButton: UIButton!
    
    // MARK: Private

    private var viewModel: KeyVerificationSelfVerifyWaitViewModelType!
    private var cancellable: Bool!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    
    private weak var cancelBarButtonItem: UIBarButtonItem?

    // MARK: - Setup
    
    class func instantiate(with viewModel: KeyVerificationSelfVerifyWaitViewModelType, cancellable: Bool) -> KeyVerificationSelfVerifyWaitViewController {
        let viewController = StoryboardScene.KeyVerificationSelfVerifyWaitViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.cancellable = cancellable
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.setupViews()
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self
        self.viewModel.process(viewAction: .loadData)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }

        self.titleLabel.textColor = theme.textPrimaryColor
        self.informationLabel.textColor = theme.textSecondaryColor
        self.desktopClientImageView.tintColor = theme.tintColor
        self.mobileClientImageView.tintColor = theme.tintColor
        self.recoverSecretsAvailabilityLoadingLabel.textColor = theme.textSecondaryColor
        self.recoverSecretsAvailabilityActivityIndicatorView.color = theme.tintColor
        
        // Tchap:
        self.tchapNoRecoverSecretsMethodAvailableInformationLabel.textColor = theme.textSecondaryColor
        
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        if self.cancellable {
            let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.skip, style: .plain) { [weak self] in
                self?.cancelButtonAction()
            }

            self.vc_removeBackTitle()

            self.navigationItem.rightBarButtonItem = cancelBarButtonItem
            self.cancelBarButtonItem = cancelBarButtonItem
        }
        
        self.titleLabel.text = VectorL10n.deviceVerificationSelfVerifyOpenOnOtherDeviceTitle(AppInfo.current.displayName)
        self.informationLabel.text = VectorL10n.deviceVerificationSelfVerifyOpenOnOtherDeviceInformation
        
        self.desktopClientImageView.image = Asset.Images.monitor.image.withRenderingMode(.alwaysTemplate)
        self.mobileClientImageView.image = Asset.Images.smartphone.image.withRenderingMode(.alwaysTemplate)
        
        self.recoverSecretsAdditionalInformationLabel.text = VectorL10n.deviceVerificationSelfVerifyWaitRecoverSecretsAdditionalHelp(AppInfo.current.displayName)
        
        // Tchap: configure Help button
        self.tchapSetupHelpButton()
    }

    // Tchap: configure Help button
    private func tchapSetupHelpButton() {
        let  helpAttributedString = NSMutableAttributedString(string: TchapL10n.deviceVerificationHelpLabel, attributes: [.foregroundColor: self.theme.warningColor])
        
        self.tchapQuickHelpButton.setAttributedTitle(helpAttributedString, for: .normal)
        
        self.tchapQuickHelpButton.vc_addAction {
            self.tchapHelpButtonAction()
        }
    }
    
    private func render(viewState: KeyVerificationSelfVerifyWaitViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .secretsRecoveryCheckingAvailability(let text):
            self.renderSecretsRecoveryCheckingAvailability(withText: text)
        case .loaded(let viewData):
            self.renderLoaded(viewData: viewData)
        case .cancelled(let reason):
            self.renderCancelled(reason: reason)
        case .cancelledByMe(let reason):
            self.renderCancelledByMe(reason: reason)
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderSecretsRecoveryCheckingAvailability(withText text: String?) {
        self.recoverSecretsAvailabilityLoadingLabel.text = text
        self.recoverSecretsAvailabilityActivityIndicatorView.startAnimating()
        self.recoverSecretsAvailabilityLoadingContainerView.isHidden = false
        self.recoverSecretsContainerView.isHidden = true
    }
    
    private func renderLoaded(viewData: KeyVerificationSelfVerifyWaitViewData) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        self.cancelBarButtonItem?.title = viewData.isNewSignIn ? VectorL10n.skip : VectorL10n.cancel
   
        let hideRecoverSecrets: Bool
        let recoverSecretsButtonTitle: String?
        
        switch viewData.secretsRecoveryAvailability {
        case .notAvailable:
            hideRecoverSecrets = true
            recoverSecretsButtonTitle = nil
        case .available(let secretsRecoveryMode):
            hideRecoverSecrets = false
            
            switch secretsRecoveryMode {
                // Tchap : use only generated key as recovery mode
//            case .passphraseOrKey:
//                recoverSecretsButtonTitle = VectorL10n.deviceVerificationSelfVerifyWaitRecoverSecretsWithPassphrase
            case .onlyKey:
                recoverSecretsButtonTitle = VectorL10n.deviceVerificationSelfVerifyWaitRecoverSecretsWithoutPassphrase
            }
        }
        
        self.recoverSecretsAvailabilityLoadingContainerView.isHidden = true
        self.recoverSecretsAvailabilityActivityIndicatorView.stopAnimating()
        self.recoverSecretsContainerView.isHidden = hideRecoverSecrets
        self.recoverSecretsButton.setTitle(recoverSecretsButtonTitle, for: .normal)
        
        // Tchap: show no recovery secrets method available only if hideRecoverSecrets is true.
        // The UI will propose the user to verify is session with another device.
        // Offer the user to cancel if no device is available to him.
        self.tchapNoRecoverSecretsMethodAvailableContainerView.isHidden = !hideRecoverSecrets
        self.tchapNoRecoverSecretsMethodAvailableInformationLabel.text = TchapL10n.deviceVerificationSelfVerifyNoOtherVerifiedSessionAvailable
        self.tchapNoRecoverSecretsMethodAvailableButton.setTitle(VectorL10n.cancel, for: .normal)
        
        if (hideRecoverSecrets)
        {
            self.tchapNoRecoverSecretsMethodAvailableButton.addTarget(self, action: #selector(cancelButtonAction), for: .touchUpInside)
        }
        
    }
    
    private func renderCancelled(reason: MXTransactionCancelCode) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        self.errorPresenter.presentError(from: self, title: "", message: VectorL10n.deviceVerificationCancelled, animated: true) {
            self.viewModel.process(viewAction: .cancel)
        }
    }
    
    private func renderCancelledByMe(reason: MXTransactionCancelCode) {
        if reason.value != MXTransactionCancelCode.user().value {
            self.activityPresenter.removeCurrentActivityIndicator(animated: true)
            
            self.errorPresenter.presentError(from: self, title: "", message: VectorL10n.deviceVerificationCancelledByMe(reason.humanReadable), animated: true) {
                self.viewModel.process(viewAction: .cancel)
            }
        } else {
            self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        }
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    // MARK: - Actions
    
    @objc private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
    }
    
    @IBAction private func recoverSecretsButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .recoverSecrets)
    }
    
    // Tchap: Help button action
    private func tchapHelpButtonAction() {
        self.present(WebSheetViewController(targetUrl: URL(string: BuildSettings.newDeviceVerificationFaqArticleUrlString)!), animated: true)
    }
}


// MARK: - KeyVerificationSelfVerifyWaitViewModelViewDelegate
extension KeyVerificationSelfVerifyWaitViewController: KeyVerificationSelfVerifyWaitViewModelViewDelegate {

    func keyVerificationSelfVerifyWaitViewModel(_ viewModel: KeyVerificationSelfVerifyWaitViewModelType, didUpdateViewState viewSate: KeyVerificationSelfVerifyWaitViewState) {
        self.render(viewState: viewSate)
    }
}
