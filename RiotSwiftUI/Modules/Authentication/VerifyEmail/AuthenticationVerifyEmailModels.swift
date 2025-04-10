//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

// MARK: View model

enum AuthenticationVerifyEmailViewModelResult {
    /// Send an email to the associated address.
    case send(String)
    /// Send the email once more.
    case resend
    /// Cancel the flow.
    case cancel
    /// Go back to the email form
    case goBack
    // Tchap: Add prepareAccountCreation case
    case prepareAccountCreation(String, String)
    // Tchap: Show Terms and Conditions.
    case showTermsAndConditions
}

// MARK: View

struct AuthenticationVerifyEmailViewState: BindableState {
    /// The homeserver requesting email verification.
    // Tchap: Remove HomeServer from properties list
//    let homeserver: AuthenticationHomeserverViewData
    /// An email has been sent and the app is waiting for the user to tap the link.
    var hasSentEmail = false
    /// View state that can be bound to from SwiftUI.
    var bindings: AuthenticationVerifyEmailBindings
    
    /// The message shown in the header while asking for an email address to be entered.
    var formHeaderMessage: String {
        // Tchap: Set bundle display name instead of address.
        VectorL10n.authenticationVerifyEmailInputMessage(BuildSettings.bundleDisplayName)
    }
    
    /// Whether the email address is valid and the user can continue.
    var hasInvalidAddress: Bool {
        bindings.emailAddress.isEmpty
    }
    
    // Tchap: Add Password and Credentials management
    /// Whether or not the password field has been edited yet.
    ///
    /// This is used to delay showing an error state until the user has tried 1 password.
    var hasEditedPassword = false
    
    /// Whether the current `password` is invalid.
    var isPasswordInvalid: Bool {
        // Tchap: password policy
//        bindings.password.count < 8
        bindings.password.count < FormRules.passwordMinLength
    }
    
    /// `true` if it is possible to continue, otherwise `false`.
    var hasValidCredentials: Bool {
        !hasInvalidAddress && !isPasswordInvalid
    }
    
    /// `true` if valid credentials have been entered and the homeserver is loaded.
    var canSubmit: Bool {
        hasValidCredentials && userAgreeWithTermsAndConditions // Tchap: Add Terms and Conditions.
    }
    
    // Tchap: Add Terms and Conditions.
    /// `true` if user validate the Terms and Conditions.
    var userAgreeWithTermsAndConditions: Bool {
        return bindings.userAgreeWithTermsAndConditions
    }
}

struct AuthenticationVerifyEmailBindings {
    /// The email address input by the user.
    var emailAddress: String
    // Tchap: Add password value
    /// The password input by the user.
    var password: String
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<AuthenticationVerifyEmailErrorType>?
    // Tchap: Add Terms and Conditions.
    /// Terms and conditions validation status.
    var userAgreeWithTermsAndConditions = false
}

enum AuthenticationVerifyEmailViewAction {
    /// Send an email to the entered address.
    case send
    /// Send the email once more.
    case resend
    /// Cancel the flow.
    case cancel
    /// Go back to enter email adress screen
    case goBack
    // Tchap: Prepare the account creation.
    case prepareAccountCreation
    // Tchap: Add Terms and Conditions.
    /// Change the Terms and Conditions status.
    case toggleTermsAndConditions
    // Tchap: Add Terms and Conditions.
    /// Show Terms and Conditions view.
    case showTermsAndConditions
}

enum AuthenticationVerifyEmailErrorType: Hashable {
    /// An error response from the homeserver.
    case mxError(String)
    /// An unknown error occurred.
    case unknown
    // Tchap: Add Tchap cases
    /// The current homeserver address isn't valid.
    case invalidHomeserver
    /// The homeserver doesn't support registration.
    case registrationDisabled
    // Tchap: Add unauthorizedThirdPartyID
    /// Unauthorized third party ID.
    case unauthorizedThirdPartyID
}
