//
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI
import CommonKit

struct AuthenticationVerifyEmailCoordinatorParameters {
    let registrationWizard: RegistrationWizard
    /// The homeserver that is requesting email verification.
    let homeserver: AuthenticationState.Homeserver
}

final class AuthenticationVerifyEmailCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: AuthenticationVerifyEmailCoordinatorParameters
    private let authenticationVerifyEmailHostingController: VectorHostingController
    private var authenticationVerifyEmailViewModel: AuthenticationVerifyEmailViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    /// The wizard used to handle the registration flow.
    private var registrationWizard: RegistrationWizard { parameters.registrationWizard }
    
    private var currentTask: Task<Void, Error>? {
        willSet {
            currentTask?.cancel()
        }
    }
    
    // Tchap: Add thirdPartyIDPlatformInfoResolver
    private let thirdPartyIDPlatformInfoResolver: ThirdPartyIDPlatformInfoResolverType
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: (@MainActor (AuthenticationRegistrationStageResult) -> Void)?
    
    // MARK: - Setup
    
    @MainActor init(parameters: AuthenticationVerifyEmailCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = AuthenticationVerifyEmailViewModel(/*homeserver: parameters.homeserver.viewData*/)
        let view = AuthenticationVerifyEmailScreen(viewModel: viewModel.context)
        authenticationVerifyEmailViewModel = viewModel
        authenticationVerifyEmailHostingController = VectorHostingController(rootView: view)
        authenticationVerifyEmailHostingController.vc_removeBackTitle()
        authenticationVerifyEmailHostingController.enableNavigationBarScrollEdgeAppearance = true
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: authenticationVerifyEmailHostingController)
        
        // Tchap: Configure thirdPartyIDPlatformInfoResolver
        let identityServerURLs = IdentityServersURLGetter(currentIdentityServerURL: nil).identityServerUrls
        self.thirdPartyIDPlatformInfoResolver = ThirdPartyIDPlatformInfoResolver(identityServerUrls: identityServerURLs,
                                                                                 serverPrefixURL: BuildSettings.serverUrlPrefix)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[AuthenticationVerifyEmailCoordinator] did start.")
        Task { await setupViewModel() }
    }
    
    func toPresentable() -> UIViewController {
        return self.authenticationVerifyEmailHostingController
    }
    
    // MARK: - Private
    
    /// Set up the view model. This method is extracted from `start()` so it can run on the `MainActor`.
    @MainActor private func setupViewModel() {
        authenticationVerifyEmailViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[AuthenticationVerifyEmailCoordinator] AuthenticationVerifyEmailViewModel did complete with result: \(result).")
            
            switch result {
            case .send(let emailAddress):
                self.sendEmail(emailAddress)
            case .resend:
                self.resendEmail()
            case .cancel:
                self.callback?(.cancel)
            case .goBack:
                self.authenticationVerifyEmailViewModel.goBackToEnterEmailForm()
            case .sendPassword(let password): // Tchap: Add sendPassword case
                self.prepareAccountCreation(password: password)
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
        // Tchap: Validate e-mail address to update (if needed) the IS
        validateEmailAddress(address)

        let threePID = RegisterThreePID.email(address.trimmingCharacters(in: .whitespaces))
        
        startLoading()
        
        currentTask = Task { [weak self] in
            do {
                let result = try await registrationWizard.addThreePID(threePID: threePID)
                
                // Shouldn't be reachable but just in case, continue the flow.
                
                guard !Task.isCancelled else { return }
                
                self?.callback?(.completed(result))
                self?.stopLoading()
            } catch RegistrationError.waitingForThreePIDValidation {
                // If everything went well, begin polling the server.
                authenticationVerifyEmailViewModel.updateForSentEmail()
                self?.stopLoading()
                
                checkForEmailValidation()
            } catch is CancellationError {
                return
            } catch {
                self?.stopLoading()
                self?.handleError(error)
            }
        }
    }
    
    /// Resends an email to the previously entered address and then resumes polling the server.
    @MainActor private func resendEmail() {
        startLoading()
        
        currentTask = Task { [weak self] in
            do {
                let result = try await registrationWizard.sendAgainThreePID()
                
                // Shouldn't be reachable but just in case, continue the flow.
                
                guard !Task.isCancelled else { return }
                
                self?.callback?(.completed(result))
                self?.stopLoading()
            } catch RegistrationError.waitingForThreePIDValidation {
                // Resume polling the server.
                self?.stopLoading()
                checkForEmailValidation()
            } catch is CancellationError {
                return
            } catch {
                self?.stopLoading()
                self?.handleError(error)
            }
        }
    }
    
    @MainActor private func checkForEmailValidation() {
        currentTask = Task { [weak self] in
            do {
                MXLog.debug("[AuthenticationVerifyEmailCoordinator] checkForEmailValidation: Sleeping for 3 seconds.")
                
                try await Task.sleep(nanoseconds: 3_000_000_000)
                let result = try await registrationWizard.checkIfEmailHasBeenValidated()
                
                guard !Task.isCancelled else { return }
                
                self?.callback?(.completed(result))
            } catch RegistrationError.waitingForThreePIDValidation {
                // Check again, creating a poll on the server.
                checkForEmailValidation()
            } catch is CancellationError {
                return
            } catch {
                self?.handleError(error)
            }
        }
    }
    
    /// Processes an error to either update the flow or display it to the user.
    @MainActor private func handleError(_ error: Error) {
        if let mxError = MXError(nsError: error as NSError) {
            let message = mxError.authenticationErrorMessage()
            authenticationVerifyEmailViewModel.displayError(.mxError(message))
            return
        }
        
        if let authenticationError = error as? AuthenticationError {
            switch authenticationError {
            case .invalidHomeserver:
                authenticationVerifyEmailViewModel.displayError(.invalidHomeserver)
            case .loginFlowNotCalled:
                #warning("Reset the flow")
            case .missingMXRestClient:
                #warning("Forget the soft logout session")
            case .unauthorizedThirdPartyID: // Tchap: Add unauthorizedThirdPartyID
                authenticationVerifyEmailViewModel.displayError(.unauthorizedThirdPartyID)
            }
            return
        }
        
        if let registrationError = error as? RegistrationError {
            switch registrationError {
            case .registrationDisabled:
                authenticationVerifyEmailViewModel.displayError(.registrationDisabled)
            case .createAccountNotCalled, .missingThreePIDData, .missingThreePIDURL, .threePIDClientFailure, .threePIDValidationFailure, .waitingForThreePIDValidation, .invalidPhoneNumber:
                // Shouldn't happen at this stage
                authenticationVerifyEmailViewModel.displayError(.unknown)
            }
            return
        }
        
        authenticationVerifyEmailViewModel.displayError(.unknown)
    }
    
    // Tchap: Add account creation part in this class
    /// Creates an account on the homeserver with the supplied password.
    @MainActor private func prepareAccountCreation(password: String) {
        let authService = AuthenticationService.shared
        let registrationWizard = authService.registrationWizard
        guard let registrationWizard = registrationWizard else {
            MXLog.failure("[AuthenticationVerifyEmailCoordinator] createAccount: The registration wizard is nil.")
            return
        }
        
        startLoading()
        
        currentTask = Task { [weak self] in
            do {
                let result = try await registrationWizard.createAccount(username: nil,
                                                                        password: password,
                                                                        initialDeviceDisplayName: UIDevice.current.initialDisplayName)
                
                guard !Task.isCancelled else { return }
                
                switch result {
                case .flowResponse(let flowResult):
                    if flowResult.missingStages.contains(.email(isMandatory: true)) {
                        authenticationVerifyEmailViewModel.context.send(viewAction: .send)
                    } else {
                        // Should not happen.
                        MXLog.error("[AuthenticationVerifyEmailCoordinator] createAccount flowResponse with no e-mail missing stage !")
                    }
                case .success:
                    MXLog.debug("[AuthenticationVerifyEmailCoordinator] createAccount success")
                    self?.callback?(.completed(result))
                }
                
                self?.stopLoading()
            } catch {
                self?.stopLoading()
                self?.handleError(error)
            }
        }
    }
    
    /// Validate e-mail address and update flow with new domain.
    @MainActor private func validateEmailAddress(_ address: String) {
        guard MXTools.isEmailAddress(address) else { return }

        // Tchap: Update the flow to get the right HS
        thirdPartyIDPlatformInfoResolver.resolvePlatformInformation(address: address, medium: kMX3PIDMediumEmail) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .authorizedThirdPartyID(info: let thirdPartyIDPlatformInfo):
                // Update HS only if different from the current one.
                if AuthenticationService.shared.client.homeserver != thirdPartyIDPlatformInfo.homeServer {
                    self.currentTask = Task { [weak self] in
                        do {
                            try await AuthenticationService.shared.startFlow(.register, for: thirdPartyIDPlatformInfo.homeServer)
                        } catch {
                            self?.handleError(error)
                        }
                    }
                }
            case .unauthorizedThirdPartyID:
                MXLog.error("[AuthenticationVerifyEmailCoordinator] ValidateEmailAddress unauthorized error.")
                self.handleError(AuthenticationError.unauthorizedThirdPartyID)
            }
        } failure: { error in
            guard let error = error else { return }
            MXLog.error("[AuthenticationVerifyEmailCoordinator] ValidateEmailAddress error", context: error)
            self.handleError(error)
        }
    }
}
