//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

typealias AuthenticationVerifyEmailViewModelType = StateStoreViewModel<AuthenticationVerifyEmailViewState, AuthenticationVerifyEmailViewAction>

class AuthenticationVerifyEmailViewModel: AuthenticationVerifyEmailViewModelType, AuthenticationVerifyEmailViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var callback: (@MainActor (AuthenticationVerifyEmailViewModelResult) -> Void)?

    // MARK: - Setup

    // Tchap: Remove homeserver from parameters list
    init(/*homeserver: AuthenticationHomeserverViewData,*/
         emailAddress: String = "",
         password: String = "") {
        let viewState = AuthenticationVerifyEmailViewState(/*homeserver: homeserver,
                                                           */bindings: AuthenticationVerifyEmailBindings(emailAddress: emailAddress, password: password))
        super.init(initialViewState: viewState)
    }

    // MARK: - Public
    
    override func process(viewAction: AuthenticationVerifyEmailViewAction) {
        switch viewAction {
        case .send:
            Task { await callback?(.send(state.bindings.emailAddress)) }
        case .resend:
            Task { await callback?(.resend) }
        case .cancel:
            Task { await callback?(.cancel) }
        case .goBack:
            Task { await callback?(.goBack) }
        case .prepareAccountCreation: // Tchap: Add prepareAccountCreation specific case
            Task { await callback?(.prepareAccountCreation(state.bindings.emailAddress, state.bindings.password)) }
        case .toggleTermsAndConditions: // Tchap: Add Terms and Conditions.
            Task { await toggleTermsAndConditions() }
        case .showTermsAndConditions: // Tchap: Add Terms and Conditions.
            Task { await callback?(.showTermsAndConditions) }
        }
    }
    
    @MainActor func updateForSentEmail() {
        state.hasSentEmail = true
    }

    @MainActor func goBackToEnterEmailForm() {
        state.hasSentEmail = false
    }
    
    @MainActor func displayError(_ type: AuthenticationVerifyEmailErrorType) {
        switch type {
        case .mxError(let message):
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: VectorL10n.error,
                                                 message: message)
        case .unknown:
            state.bindings.alertInfo = AlertInfo(id: type)
        case .invalidHomeserver:
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: VectorL10n.error,
                                                 message: VectorL10n.authenticationServerSelectionGenericError)
        case .registrationDisabled:
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: VectorL10n.error,
                                                 message: VectorL10n.loginErrorRegistrationIsNotSupported)
        case .unauthorizedThirdPartyID:
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: VectorL10n.error,
                                                 message: TchapL10n.authenticationErrorUnauthorizedEmail)
        }
    }
    
    // Tchap: Add Terms and Conditions.
    /// Toggle the value for Terms and Conditions agreement.
    @MainActor private func toggleTermsAndConditions() {
        state.bindings.userAgreeWithTermsAndConditions = !state.bindings.userAgreeWithTermsAndConditions
    }
}
