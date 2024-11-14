//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import UIKit

/// View controller used for User-Interactive Authentication fallback (https://matrix.org/docs/spec/client_server/latest#fallback)
final class ReauthFallBackViewController: AuthFallBackViewController, Themable {
    
    // MARK: - Properties
                    
    // MARK: Public
    
    var didValidate: (() -> Void)?
    var didCancel: (() -> Void)?
    
    // MARK: Private
    
    private var theme: Theme = ThemeService.shared().theme
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupNavigationBar()
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        // Tchap: block dismissal of this Reauthentication sheet by dragging down.
        // The user must use the close button.
        if #available(iOS 13.0, *) {
            self.isModalInPresentation = true
        }
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.theme = theme
                
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
    }
    
    // MARK: - Private
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupNavigationBar() {
        // Tchap: Add 'Cancel' button the cancel the authentication process from the beginning.
        // (because the 'Done' button will try to launch the authentication process with current session token
        // which will retrigger the display of the Authentication window).
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.didCancel?()
        }

        let doneBarButtonItem = MXKBarButtonItem(title: VectorL10n.close, style: .plain) { [weak self] in
            self?.didValidate?()
        }
        self.navigationItem.leftBarButtonItem = cancelBarButtonItem
        
        self.setBackButton(doneBarButtonItem)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension ReauthFallBackViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.didCancel?()
    }
}
