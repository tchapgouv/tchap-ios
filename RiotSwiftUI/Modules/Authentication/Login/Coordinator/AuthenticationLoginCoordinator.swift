//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CommonKit
import MatrixSDK
import SwiftUI

struct AuthenticationLoginCoordinatorParameters {
    let navigationRouter: NavigationRouterType
    let authenticationService: AuthenticationService
    /// The login mode to allow SSO buttons to be shown when available.
    let loginMode: LoginMode
}

enum AuthenticationLoginCoordinatorResult: CustomStringConvertible {
    // Tchap: add `loginHint` string parameter for SSO
//    case continueWithSSO(SSOIdentityProvider)
    /// Continue using the supplied SSO provider.
    case continueWithSSO(SSOIdentityProvider, String? = nil)
    /// Login was successful with the associated session created.
    case success(session: MXSession, password: String)
    /// Login was successful with the associated session created.
    case loggedInWithQRCode(session: MXSession, securityCompleted: Bool)
    /// Login requested a fallback
    case fallback
    
    /// A string representation of the result, ignoring any associated values that could leak PII.
    var description: String {
        switch self {
        // Tchap: add `loginHint` string parameter for SSO
//        case .continueWithSSO(let provider):
        case .continueWithSSO(let provider, _):
            return "continueWithSSO: \(provider)"
        case .success:
            return "success"
        case .loggedInWithQRCode:
            return "loggedInWithQRCode"
        case .fallback:
            return "fallback"
        }
    }
}

final class AuthenticationLoginCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: AuthenticationLoginCoordinatorParameters
    private let authenticationLoginHostingController: VectorHostingController
    private var authenticationLoginViewModel: AuthenticationLoginViewModelProtocol
    
    private var currentTask: Task<Void, Error>? {
        willSet {
            currentTask?.cancel()
        }
    }
    
    private var navigationRouter: NavigationRouterType { parameters.navigationRouter }
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var waitingIndicator: UserIndicator?
    private var successIndicator: UserIndicator?
    
    /// The authentication service used for the login.
    private var authenticationService: AuthenticationService { parameters.authenticationService }
    /// The wizard used to handle the login flow. Will only be `nil` if there is a misconfiguration.
    private var loginWizard: LoginWizard? { parameters.authenticationService.loginWizard }
    
    // Tchap: Add thirdPartyIDPlatformInfoResolver
    private let thirdPartyIDPlatformInfoResolver: ThirdPartyIDPlatformInfoResolverType
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: (@MainActor (AuthenticationLoginCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    @MainActor init(parameters: AuthenticationLoginCoordinatorParameters) {
        self.parameters = parameters
        
        let homeserver = parameters.authenticationService.state.homeserver
        // Tchap: pass `loginMode` to viewModel to be able to adapt the working of the login display view.
        let viewModel = AuthenticationLoginViewModel(homeserver: homeserver.viewData, authenticationMode: parameters.loginMode)
        authenticationLoginViewModel = viewModel
        
        // Tchap: Use heavily customized AuthenticationLoginScreen
//        let view = AuthenticationLoginScreen(viewModel: viewModel.context)
        let view = TchapAuthenticationLoginScreen(viewModel: viewModel.context)
        authenticationLoginHostingController = VectorHostingController(rootView: view)
        authenticationLoginHostingController.vc_removeBackTitle()
        authenticationLoginHostingController.enableNavigationBarScrollEdgeAppearance = true
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: authenticationLoginHostingController)
        
        // Tchap: Configure thirdPartyIDPlatformInfoResolver
        let identityServerURLs = IdentityServersURLGetter(currentIdentityServerURL: nil).identityServerUrls
        self.thirdPartyIDPlatformInfoResolver = ThirdPartyIDPlatformInfoResolver(identityServerUrls: identityServerURLs,
                                                                                 serverPrefixURL: BuildSettings.serverUrlPrefix)
    }
    
    // MARK: - Public

    func start() {
        MXLog.debug("[AuthenticationLoginCoordinator] did start.")
        Task { await setupViewModel() }
    }
    
    func toPresentable() -> UIViewController {
        authenticationLoginHostingController
    }
    
    // MARK: - Private
    
    /// Set up the view model. This method is extracted from `start()` so it can run on the `MainActor`.
    @MainActor private func setupViewModel() {
        authenticationLoginViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[AuthenticationLoginCoordinator] AuthenticationLoginViewModel did callback with result: \(result).")
            
            switch result {
            case .selectServer:
                self.presentServerSelectionScreen()
            case .parseUsername(let username):
                self.parseUsername(username)
            case .forgotPassword:
                self.showForgotPasswordScreen()
            case .login(let username, let password):
                self.login(username: username, password: password)
            case .continueWithSSO(let identityProvider, let loginHint):
                self.callback?(.continueWithSSO(identityProvider, loginHint))
            case .fallback:
                self.callback?(.fallback)
            case .qrLogin:
                self.showQRLoginScreen()
            }
        }
    }
    
    /// Show a blocking activity indicator whilst saving.
    @MainActor private func startLoading(isInteractionBlocking: Bool) {
        waitingIndicator = indicatorPresenter.present(.loading(label: VectorL10n.loading, isInteractionBlocking: isInteractionBlocking))
        
        if !isInteractionBlocking {
            authenticationLoginViewModel.update(isLoading: true)
        }
    }
    
    /// Hide the currently displayed activity indicator.
    @MainActor private func stopLoading() {
        authenticationLoginViewModel.update(isLoading: false)
        waitingIndicator = nil
    }
    
    /// Login with the supplied username and password.
    @MainActor private func login(username: String, password: String) {
        guard let loginWizard = loginWizard else {
            MXLog.failure("[AuthenticationLoginCoordinator] The login wizard was requested before getting the login flow.")
            return
        }
        
        startLoading(isInteractionBlocking: true)
        
        currentTask = Task { [weak self] in
            do {
                let session = try await loginWizard.login(login: username,
                                                          password: password,
                                                          initialDeviceName: UIDevice.current.initialDisplayName)
                
                guard !Task.isCancelled else { return }
                callback?(.success(session: session, password: password))
                
                self?.stopLoading()
            } catch {
                self?.stopLoading()
                self?.handleError(error)
            }
        }
    }
    
    /// Processes an error to either update the flow or display it to the user.
    @MainActor private func handleError(_ error: Error) {
        if let mxError = MXError(nsError: error as NSError) {
            let message = mxError.authenticationErrorMessage()
            authenticationLoginViewModel.displayError(.mxError(message))
            return
        }
        
        if let authenticationError = error as? AuthenticationError {
            switch authenticationError {
            case .invalidHomeserver:
                authenticationLoginViewModel.displayError(.invalidHomeserver)
            case .loginFlowNotCalled:
                #warning("Reset the flow")
            case .missingMXRestClient:
                #warning("Forget the soft logout session")
            case .unauthorizedThirdPartyID: // Tchap: Add unauthorizedThirdPartyID
                authenticationLoginViewModel.displayError(.unauthorizedThirdPartyID)
            }
            return
        }
        
        authenticationLoginViewModel.displayError(.unknown)
    }
    
    @MainActor private func parseUsername(_ username: String) {
        // Tchap: Use e-mail address instead of a Matrix username.
        guard MXTools.isEmailAddress(username) else { return }
        
        startLoading(isInteractionBlocking: false)
        
        // Tchap: Update the flow to get the right HS
        thirdPartyIDPlatformInfoResolver.resolvePlatformInformation(address: username, medium: kMX3PIDMediumEmail) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .authorizedThirdPartyID(info: let thirdPartyIDPlatformInfo):
                self.currentTask = Task { [weak self] in
                    guard let self = self else { return }
                    
                    do {
                        try await self.authenticationService.startFlow(.login, for: thirdPartyIDPlatformInfo.homeServer)
                        
                        guard !Task.isCancelled else { return }
                        
                        self.updateViewModel()
                        self.stopLoading()
                    } catch {
                        self.stopLoading()
                        self.handleError(error)
                    }
                }
            case .unauthorizedThirdPartyID:
                MXLog.error("[AuthenticationLoginCoordinator] ParseUsername unauthorized error.")
                self.stopLoading()
                self.handleError(AuthenticationError.unauthorizedThirdPartyID)
            }
        } failure: { error in
            guard let error = error else { return }
            MXLog.error("[AuthenticationLoginCoordinator] ParseUsername error", context: error)
            self.stopLoading()
            self.handleError(error)
        }
    }
    
    /// Presents the server selection screen as a modal.
    @MainActor private func presentServerSelectionScreen() {
        MXLog.debug("[AuthenticationLoginCoordinator] presentServerSelectionScreen")
        let parameters = AuthenticationServerSelectionCoordinatorParameters(authenticationService: authenticationService,
                                                                            flow: .login,
                                                                            hasModalPresentation: true)
        let coordinator = AuthenticationServerSelectionCoordinator(parameters: parameters)
        coordinator.callback = { [weak self, weak coordinator] result in
            guard let self = self, let coordinator = coordinator else { return }
            self.serverSelectionCoordinator(coordinator, didCompleteWith: result)
        }
        
        coordinator.start()
        add(childCoordinator: coordinator)
        
        let modalRouter = NavigationRouter()
        modalRouter.setRootModule(coordinator)
        
        navigationRouter.present(modalRouter, animated: true)
    }
    
    /// Handles the result from the server selection modal, dismissing it after updating the view.
    @MainActor private func serverSelectionCoordinator(_ coordinator: AuthenticationServerSelectionCoordinator,
                                                       didCompleteWith result: AuthenticationServerSelectionCoordinatorResult) {
        navigationRouter.dismissModule(animated: true) { [weak self] in
            if result == .updated {
                self?.updateViewModel()
            }

            self?.remove(childCoordinator: coordinator)
        }
    }

    /// Shows the forgot password screen.
    @MainActor private func showForgotPasswordScreen() {
        MXLog.debug("[AuthenticationLoginCoordinator] showForgotPasswordScreen")

        // Tchap: Call `startFlow` here to get `loginWizard` initialized.
        Task {
            try? await authenticationService.startFlow(.login)
            
            guard let loginWizard = loginWizard else {
                MXLog.failure("[AuthenticationLoginCoordinator] The login wizard was requested before getting the login flow.")
                return
            }
            
            let modalRouter = NavigationRouter()
            
            let parameters = AuthenticationForgotPasswordCoordinatorParameters(navigationRouter: modalRouter,
                                                                               loginWizard: loginWizard,
                                                                               homeserver: parameters.authenticationService.state.homeserver)
            let coordinator = AuthenticationForgotPasswordCoordinator(parameters: parameters)
            coordinator.callback = { [weak self, weak coordinator] result in
                guard let self = self, let coordinator = coordinator else { return }
                switch result {
                case .success:
                    self.navigationRouter.dismissModule(animated: true, completion: nil)
                    self.successIndicator = self.indicatorPresenter.present(.success(label: VectorL10n.done))
                case .cancel:
                    self.navigationRouter.dismissModule(animated: true, completion: nil)
                }
                self.remove(childCoordinator: coordinator)
            }
            
            coordinator.start()
            add(childCoordinator: coordinator)
            
            modalRouter.setRootModule(coordinator)
            
            navigationRouter.present(modalRouter, animated: true)
        }
    }

    /// Shows the QR login screen.
    @MainActor private func showQRLoginScreen() {
        MXLog.debug("[AuthenticationLoginCoordinator] showQRLoginScreen")

        let service = QRLoginService(client: parameters.authenticationService.client,
                                     mode: .notAuthenticated)
        let parameters = AuthenticationQRLoginStartCoordinatorParameters(navigationRouter: navigationRouter,
                                                                         qrLoginService: service)
        let coordinator = AuthenticationQRLoginStartCoordinator(parameters: parameters)
        coordinator.callback = { [weak self, weak coordinator] callback in
            guard let self = self, let coordinator = coordinator else { return }
            switch callback {
            case .done(let session, let securityCompleted):
                self.callback?(.loggedInWithQRCode(session: session, securityCompleted: securityCompleted))
            }
            
            self.remove(childCoordinator: coordinator)
        }

        coordinator.start()
        add(childCoordinator: coordinator)

        navigationRouter.push(coordinator, animated: true) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    /// Updates the view model to reflect any changes made to the homeserver.
    @MainActor private func updateViewModel() {
        let homeserver = authenticationService.state.homeserver
        authenticationLoginViewModel.update(homeserver: homeserver.viewData)

        if homeserver.needsLoginFallback {
            callback?(.fallback)
        }
    }
}
