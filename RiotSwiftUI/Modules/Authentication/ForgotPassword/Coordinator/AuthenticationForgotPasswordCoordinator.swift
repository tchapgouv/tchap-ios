//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CommonKit
import SwiftUI

struct AuthenticationForgotPasswordCoordinatorParameters {
    let navigationRouter: NavigationRouterType
    let loginWizard: LoginWizard
    /// The homeserver currently being used.
    let homeserver: AuthenticationState.Homeserver
}

enum AuthenticationForgotPasswordCoordinatorResult {
    /// Forgot password flow succeeded
    case success
    /// Forgot password flow cancelled
    case cancel
    // Tchap: need to connect to SSO to reset password
    case tchapResetWithSSO(String)
}

final class AuthenticationForgotPasswordCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: AuthenticationForgotPasswordCoordinatorParameters
    private let authenticationForgotPasswordHostingController: VectorHostingController
    private var authenticationForgotPasswordViewModel: AuthenticationForgotPasswordViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?

    private var navigationRouter: NavigationRouterType { parameters.navigationRouter }
    /// The wizard used to handle the registration flow.
    // Tchap: loginWizard should be updated according to the selected email
    private var loginWizard: LoginWizard //{ parameters.loginWizard }
    
    // Tchap: Add thirdPartyIDPlatformInfoResolver
    private let thirdPartyIDPlatformInfoResolver: ThirdPartyIDPlatformInfoResolverType
    
    private var currentTask: Task<Void, Error>? {
        willSet {
            currentTask?.cancel()
        }
    }
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: (@MainActor (AuthenticationForgotPasswordCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    @MainActor init(parameters: AuthenticationForgotPasswordCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = AuthenticationForgotPasswordViewModel(homeserver: parameters.homeserver.viewData)
        let view = AuthenticationForgotPasswordScreen(viewModel: viewModel.context)
        authenticationForgotPasswordViewModel = viewModel
        authenticationForgotPasswordHostingController = VectorHostingController(rootView: view)
        authenticationForgotPasswordHostingController.vc_removeBackTitle()
        authenticationForgotPasswordHostingController.enableNavigationBarScrollEdgeAppearance = true
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: authenticationForgotPasswordHostingController)
        
        // Tchap: use by default the registrationWizard of the parameters
        loginWizard = parameters.loginWizard
        
        // Tchap: Configure thirdPartyIDPlatformInfoResolver
        let identityServerURLs = IdentityServersURLGetter(currentIdentityServerURL: nil).identityServerUrls
        self.thirdPartyIDPlatformInfoResolver = ThirdPartyIDPlatformInfoResolver(identityServerUrls: identityServerURLs,
                                                                                 serverPrefixURL: BuildSettings.serverUrlPrefix)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[AuthenticationForgotPasswordCoordinator] did start.")
        Task { await setupViewModel() }
    }
    
    func toPresentable() -> UIViewController {
        authenticationForgotPasswordHostingController
    }
    
    // MARK: - Private
    
    /// Set up the view model. This method is extracted from `start()` so it can run on the `MainActor`.
    @MainActor private func setupViewModel() {
        authenticationForgotPasswordViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[AuthenticationForgotPasswordCoordinator] AuthenticationForgotPasswordViewModel did complete with result: \(result).")
            
            switch result {
            case .send(let emailAddress):
                self.sendEmail(emailAddress)
            case .cancel:
                self.callback?(.cancel)
            case .done:
                self.showChoosePasswordScreen()
            case .goBack:
                self.authenticationForgotPasswordViewModel.goBackToEnterEmailForm()
            }
        }
    }
    
    /// Show an activity indicator whilst loading.
    @MainActor private func startLoading() {
        loadingIndicator = indicatorPresenter.present(.loading(label: VectorL10n.loading, isInteractionBlocking: true))
    }
    
    /// Hide the currently displayed activity indicator.
    @MainActor private func stopLoading() {
        loadingIndicator = nil
    }
    
    /// Sends a validation email to the supplied address and then begins polling the server.
    @MainActor private func sendEmail(_ address: String) {
        startLoading()
        
        // Tchap: Update the flow to get the right HS
        thirdPartyIDPlatformInfoResolver.resolvePlatformInformation(address: address, medium: kMX3PIDMediumEmail) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .authorizedThirdPartyID(info: let thirdPartyIDPlatformInfo):
                self.currentTask = Task { [weak self] in
                    guard let self = self else { return }
                    do {
                        try await AuthenticationService.shared.startFlow(.login, for: thirdPartyIDPlatformInfo.homeServer)
                        
                        if let updatedLoginWizard = AuthenticationService.shared.loginWizard {
                            self.loginWizard = updatedLoginWizard
                        }
                            
                        try await self.loginWizard.resetPassword(email: address)
                        
                        // Shouldn't be reachable but just in case, continue the flow.

                        guard !Task.isCancelled else { return }
                        
                        self.authenticationForgotPasswordViewModel.updateForSentEmail()
                        self.stopLoading()
                    } catch is CancellationError {
                        return
                    } catch {
                        self.stopLoading()
                        self.handleError(error)
                    }
                }
            case .unauthorizedThirdPartyID:
                MXLog.error("[AuthenticationForgotPasswordCoordinator] sendEmail unauthorized error.")
                self.stopLoading()
                self.handleError(AuthenticationError.unauthorizedThirdPartyID)
            }
        } failure: { error in
            guard let error = error else { return }
            MXLog.error("[AuthenticationForgotPasswordCoordinator] sendEmail error", context: error)
            self.stopLoading()
            self.handleError(error)
        }
    }

    /// Shows the choose password screen
    @MainActor private func showChoosePasswordScreen() {
        MXLog.debug("[AuthenticationForgotPasswordCoordinator] showChoosePasswordScreen")

        let parameters = AuthenticationChoosePasswordCoordinatorParameters(loginWizard: loginWizard)
        let coordinator = AuthenticationChoosePasswordCoordinator(parameters: parameters)
        coordinator.callback = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.callback?(.success)
            case .cancel:
                self.navigationRouter.popModule(animated: true)
            }
        }

        coordinator.start()
        add(childCoordinator: coordinator)

        navigationRouter.push(coordinator, animated: true, popCompletion: nil)
    }

    /// Processes an error to either update the flow or display it to the user.
    @MainActor private func handleError(_ error: Error) {
        if let mxError = MXError(nsError: error as NSError) {
            
            // Tchap: Handle MAS-only password reset
//            let message = mxError.authenticationErrorMessage()
//            authenticationForgotPasswordViewModel.displayError(.mxError(message))
            if mxError.isUnrecognizedRequest {
                authenticationForgotPasswordViewModel.context.viewState.bindings.alertInfo = AlertInfo(id: .unrecognizedRequest,
                                                                                              title: VectorL10n.warning,
                                                                                              message: TchapL10n.authenticationMasEnabledAlertMessage(BuildSettings.bundleDisplayName),
                                                                                              primaryButton: (title: VectorL10n.ok, action: {
                    TchapAuthenticationHelper.RedirectToSSO(for: self.authenticationForgotPasswordViewModel.context.emailAddress) { ssoProvider in
                        Task { @MainActor in
                            self.callback?(.tchapResetWithSSO(self.authenticationForgotPasswordViewModel.context.emailAddress))
                        }
                    }
                }))
            }
            else {
                let message = mxError.authenticationErrorMessage()
                authenticationForgotPasswordViewModel.displayError(.mxError(message))
            }
            
            return
        }
        
        if let authenticationError = error as? AuthenticationError {
            switch authenticationError {
            case .unauthorizedThirdPartyID: // Tchap: Add unauthorizedThirdPartyID
                authenticationForgotPasswordViewModel.displayError(.unauthorizedThirdPartyID)
            default:
                authenticationForgotPasswordViewModel.displayError(.unknown)
            }
            return
        }
        
        authenticationForgotPasswordViewModel.displayError(.unknown)
    }
}

// Tchap: handle MAS-only reset password error
extension MXError {
    var isUnrecognizedRequest: Bool {
        errcode == kMXErrCodeStringUnrecognized && error == "Unrecognized request"
    }
}
