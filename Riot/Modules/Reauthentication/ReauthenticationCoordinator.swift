// File created from FlowTemplate
// $ createRootCoordinator.sh Reauthentication Reauthentication
/*
 Copyright 2021 New Vector Ltd
 
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

enum ReauthenticationCoordinatorError: Error {
    case failToBuildPasswordParameters
}

@objcMembers
final class ReauthenticationCoordinator: ReauthenticationCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: ReauthenticationCoordinatorParameters
    private let userInteractiveAuthenticationService: UserInteractiveAuthenticationService
    private let authenticationParametersBuilder: AuthenticationParametersBuilder
    private let uiaViewControllerFactory: UserInteractiveAuthenticationViewControllerFactory
    
//    private var ssoAuthenticationPresenter: SSOAuthenticationPresenter?
    
    private var authenticationSession: SSOAuthentificationSessionProtocol?
    
    private var presentingViewController: UIViewController {
        return self.parameters.presenter.toPresentable()
    }
    
    private weak var passwordViewController: UIViewController?
    
    /// The presenter used to handler authentication via SSO.
    private var ssoAuthenticationPresenter: SSOAuthenticationPresenter?
    /// The transaction ID used when presenting the SSO screen. Used when completing via a deep link.
    private var ssoTransactionID: String?
    private let authenticationService = AuthenticationService.shared
    /// The type of authentication that was used to complete the flow.
    private var authenticationType: AuthenticationType?

    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: ReauthenticationCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(parameters: ReauthenticationCoordinatorParameters) {
        self.parameters = parameters
        self.userInteractiveAuthenticationService = UserInteractiveAuthenticationService(session: parameters.session)
        self.authenticationParametersBuilder = AuthenticationParametersBuilder()
        self.uiaViewControllerFactory = UserInteractiveAuthenticationViewControllerFactory()
    }    
    
    // MARK: - Public methods
    
    func start() {
        if let authenticatedEndpointRequest = self.parameters.authenticatedEndpointRequest {
            self.start(with: authenticatedEndpointRequest)
        } else if let authenticationSession = self.parameters.authenticationSession {
            self.start(with: authenticationSession)
        } else {
            fatalError("[ReauthenticationCoordinator] Should not happen. Missing authentication parameters")
        }
    }
    
    private func start(with authenticatedEndpointRequest: AuthenticatedEndpointRequest) {
        self.userInteractiveAuthenticationService.authenticatedEndpointStatus(for: authenticatedEndpointRequest) { (result) in
            
            switch result {
            case .success(let authenticatedEnpointStatus):
                
                switch authenticatedEnpointStatus {
                case .authenticationNotNeeded:
                    MXLog.debug("[ReauthenticationCoordinator] No need to login again")
                    self.delegate?.reauthenticationCoordinatorDidComplete(self, withAuthenticationParameters: nil)
                case .authenticationNeeded(let authenticationSession):
                    self.start(with: authenticationSession)
                }
            case .failure(let error):
                self.delegate?.reauthenticationCoordinator(self, didFailWithError: error)
            }
        }
    }
    
    private func start(with authenticationSession: MXAuthenticationSession) {
        // Tchap: give priority to SSO reauthentication if a SSO flow is available and not completed
        if self.userInteractiveAuthenticationService.tchapHasSsoFlowAvailable(authenticationSession: authenticationSession),
           let authenticationFallbackURL = self.userInteractiveAuthenticationService.firstUncompletedStageAuthenticationFallbackURL(for: authenticationSession) {
            
            Task {
                let (client, server) = try await authenticationService.loginFlow(for: parameters.session)
                switch server.preferredLoginMode {
                case .sso(let ssoIdentityProviders), .ssoAndPassword(let ssoIdentityProviders):
                    await presentSSOAuthentication(for: ssoIdentityProviders.first!)
                default:
                    break
                }
//                self.showFallbackAuthentication(with: authenticationFallbackURL, authenticationSession: authenticationSession)
                //            presentSSOAuthentication(for: )
            }
        }
        else if self.userInteractiveAuthenticationService.hasPasswordFlow(inFlows: authenticationSession.flows) {
            self.showPasswordAuthentication(with: authenticationSession)
        } else if let authenticationFallbackURL = self.userInteractiveAuthenticationService.firstUncompletedStageAuthenticationFallbackURL(for: authenticationSession) {
            
            self.showFallbackAuthentication(with: authenticationFallbackURL, authenticationSession: authenticationSession)
        } else {
            self.delegate?.reauthenticationCoordinator(self, didFailWithError: UserInteractiveAuthenticationServiceError.flowNotSupported)
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.parameters.presenter.toPresentable()
    }
    
    // MARK: - Private methods

    private func showPasswordAuthentication(with authenticationSession: MXAuthenticationSession) {                
        guard let userId = parameters.session.myUser.userId else {
            return
        }
        
        let passwordViewController = self.uiaViewControllerFactory.createPasswordViewController(title: self.parameters.title, message: self.parameters.message) { [weak self] (password) in
         
            guard let self = self else {
                return
            }
            
            guard let sessionId = authenticationSession.session, let authenticationParameters = self.authenticationParametersBuilder.buildPasswordParameters(sessionId: sessionId, userId: userId, password: password) else {
                self.delegate?.reauthenticationCoordinator(self, didFailWithError: ReauthenticationCoordinatorError.failToBuildPasswordParameters)
                return
            }

            self.delegate?.reauthenticationCoordinatorDidComplete(self, withAuthenticationParameters: authenticationParameters)
            
        } onCancelled: { [weak self] in
            guard let self = self else {
                return
            }
            self.delegate?.reauthenticationCoordinatorDidCancel(self)
        }
        
        self.presentingViewController.present(passwordViewController, animated: true)
    }
    
    private func showFallbackAuthentication(with authenticationURL: URL, authenticationSession: MXAuthenticationSession) {
        
        // NOTE: Prefer use a callback and the same mechanism as SSOAuthentificationSession instead of using custom WKWebView
        let reauthFallbackViewController: ReauthFallBackViewController = ReauthFallBackViewController(url: authenticationURL.absoluteString)
        reauthFallbackViewController.title = self.parameters.title
                
        // Tchap: move navigationController init before actions closures for the closures to capture the controller to dismiss it.
        let navigationController = RiotNavigationController(rootViewController: reauthFallbackViewController)
        
        reauthFallbackViewController.didCancel = { [weak self] in
            guard let self = self else {
                return
            }
            // Tchap: dismiss controller
            navigationController.dismiss(animated: true)
            self.delegate?.reauthenticationCoordinatorDidCancel(self)
        }
        
        reauthFallbackViewController.didValidate = { [weak self] in
            guard let self = self else {
                return
            }
            
            guard let sessionId = authenticationSession.session else {
                self.delegate?.reauthenticationCoordinator(self, didFailWithError: ReauthenticationCoordinatorError.failToBuildPasswordParameters)
                return
            }
            
            let authenticationParameters = self.authenticationParametersBuilder.buildOAuthParameters(with: sessionId)
            // Tchap: dismiss controller
            navigationController.dismiss(animated: true)
            self.delegate?.reauthenticationCoordinatorDidComplete(self, withAuthenticationParameters: authenticationParameters)
        }
        
        self.presentingViewController.present(navigationController, animated: true)
    }
}


extension ReauthenticationCoordinator: SSOAuthenticationPresenterDelegate {
    /// Presents SSO authentication for the specified identity provider.
    @MainActor private func presentSSOAuthentication(for identityProvider: SSOIdentityProvider) {
        let service = SSOAuthenticationService(homeserverStringURL: authenticationService.state.homeserver.address)
        let presenter = SSOAuthenticationPresenter(ssoAuthenticationService: service)
        presenter.delegate = self
        
        let transactionID = MXTools.generateTransactionId()
        presenter.present(forIdentityProvider: identityProvider, with: transactionID, from: toPresentable(), animated: true)
        
        ssoAuthenticationPresenter = presenter
        ssoTransactionID = transactionID
        authenticationType = .sso(identityProvider)
    }
    
    func ssoAuthenticationPresenter(_ presenter: SSOAuthenticationPresenter, authenticationSucceededWithToken token: String, usingIdentityProvider identityProvider: SSOIdentityProvider?) {
        MXLog.debug("[AuthenticationCoordinator] SSO authentication succeeded.")
        
        guard let sessionId = self.parameters.authenticationSession?.session else {
            self.delegate?.reauthenticationCoordinator(self, didFailWithError: ReauthenticationCoordinatorError.failToBuildPasswordParameters)
            return
        }
        
        let authenticationParameters = self.authenticationParametersBuilder.buildOAuthParameters(with: sessionId)
        // Tchap: dismiss controller
//        navigationController.dismiss(animated: true)
        self.delegate?.reauthenticationCoordinatorDidComplete(self, withAuthenticationParameters: authenticationParameters)
        
        
//        guard let loginWizard = authenticationService.loginWizard else {
//            MXLog.failure("[ReauthenticationCoordinator] The login wizard was requested before getting the login flow.")
//            return
//        }
        
//        Task { await handleLoginToken(token, using: loginWizard) }
    }
    
    func ssoAuthenticationPresenter(_ presenter: SSOAuthenticationPresenter, authenticationDidFailWithError error: Error) {
        MXLog.debug("[ReauthenticationCoordinator] SSO authentication failed.")
        
        Task { @MainActor in
            displayError(message: error.localizedDescription)
            ssoAuthenticationPresenter = nil
            ssoTransactionID = nil
            authenticationType = nil
        }
    }
    
    func ssoAuthenticationPresenterDidCancel(_ presenter: SSOAuthenticationPresenter) {
        MXLog.debug("[ReauthenticationCoordinator] SSO authentication cancelled.")
        ssoAuthenticationPresenter = nil
        ssoTransactionID = nil
        authenticationType = nil
        self.delegate?.reauthenticationCoordinatorDidCancel(self)
    }
    
    /// Performs the last step of the login process for a flow that authenticated via SSO.
    @MainActor private func handleLoginToken(_ token: String, using loginWizard: LoginWizard) async {
        do {
            let session = try await loginWizard.login(with: token)
//            onSessionCreated(session: session, flow: authenticationService.state.flow)
            MXLog.info("[ReauthenticationCoordinator] Login with SSO token: \(token).")
        } catch {
            MXLog.error("[ReauthenticationCoordinator] Login with SSO token failed.")
            displayError(message: error.localizedDescription)
            authenticationType = nil
        }
        
        ssoAuthenticationPresenter = nil
        ssoTransactionID = nil
    }
    
    /// Presents an alert on top of the navigation router with the supplied error message.
    @MainActor private func displayError(message: String) {
        let alert = UIAlertController(title: VectorL10n.error, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: VectorL10n.ok, style: .default))
        toPresentable().present(alert, animated: true)
    }

}
