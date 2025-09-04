//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// MARK: View model

enum AuthenticationLoginViewModelResult: CustomStringConvertible {
    /// The user would like to select another server.
    case selectServer
    /// Parse the username and update the homeserver if included.
    case parseUsername(String)
    /// The user would like to reset their password.
    case forgotPassword
    /// Login using the supplied credentials.
    case login(username: String, password: String)
    // Tchap: add `loginHint` string parameter for SSO
    //    case continueWithSSO(SSOIdentityProvider)
    /// Continue using the supplied SSO provider.
    case continueWithSSO(SSOIdentityProvider, String? = nil)
    /// Continue using the fallback page
    case fallback
    /// Continue with QR login
    case qrLogin
    
    /// A string representation of the result, ignoring any associated values that could leak PII.
    var description: String {
        switch self {
        case .selectServer:
            return "selectServer"
        case .parseUsername:
            return "parseUsername"
        case .forgotPassword:
            return "forgotPassword"
        case .login:
            return "login"
        case .continueWithSSO(let provider, _):
            return "continueWithSSO: \(provider)"
        case .fallback:
            return "fallback"
        case .qrLogin:
            return "qrLogin"
        }
    }
}

// MARK: View

struct AuthenticationLoginViewState: BindableState {
    /// Data about the selected homeserver.
    var homeserver: AuthenticationHomeserverViewData
    /// Whether a new homeserver is currently being loaded.
    var isLoading = false
    /// View state that can be bound to from SwiftUI.
    var bindings: AuthenticationLoginBindings
    
    // Tchap: add loginMode (only password or sso modes are handled)
    var tchapAuthenticationMode: LoginMode

    /// Whether to show any SSO buttons.
    var showSSOButtons: Bool {
        // Tchap: only show sso buttons if tchapAuthenticationMode == .sso OR .ssoAndPassword
//        !homeserver.ssoIdentityProviders.isEmpty
        if case .sso = tchapAuthenticationMode,
           !homeserver.ssoIdentityProviders.isEmpty {
            return true
        }
        if case .ssoAndPassword = tchapAuthenticationMode,
           !homeserver.ssoIdentityProviders.isEmpty {
            return true
        }
        return false
    }
    
    /// `true` if the username and password are ready to be submitted.
    var hasValidCredentials: Bool {
        !bindings.username.isEmpty && !bindings.password.isEmpty
    }
    
    /// `true` if valid credentials have been entered and the homeserver is loaded.
    var canSubmit: Bool {
        // Tchap: handle `canSubmit` by checking email validity for concerned cases
//        return hasValidCredentials && !isLoading
        switch tchapAuthenticationMode {
        case .password:
            return !isLoading && tchapEmailIsValid
        case .sso:
            return !isLoading && tchapEmailIsValid
        default:
            return hasValidCredentials && !isLoading
        }
    }
    
    // Tchap: username is email
    var tchapEmailIsValid: Bool {
        MXTools.isEmailAddress(bindings.username)
    }
}

struct AuthenticationLoginBindings {
    /// The username input by the user.
    var username = ""
    /// The password input by the user.
    var password = ""
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<AuthenticationLoginErrorType>?
}

enum AuthenticationLoginViewAction {
    /// The user would like to select another server.
    case selectServer
    /// Parse the username to detect if a homeserver is included.
    case parseUsername
    /// The user would like to reset their password.
    case forgotPassword
    /// Continue using the input username and password.
    case next
    /// Continue using the fallback page
    case fallback
    // Tchap; add `loginHint` string parameter for SSO
//    case continueWithSSO(SSOIdentityProvider)
    /// Continue using the supplied SSO provider.
    case continueWithSSO(SSOIdentityProvider, String? = nil)
    /// Continue using QR login
    case qrLogin
}

enum AuthenticationLoginErrorType: Hashable {
    /// An error response from the homeserver.
    case mxError(String)
    /// The current homeserver address isn't valid.
    case invalidHomeserver
    /// The response from the homeserver was unexpected.
    case unknown
    // Tchap: Add unauthorizedThirdPartyID
    /// Unauthorized third party ID.
    case unauthorizedThirdPartyID
    // Tchap: Add unauthorizedThirdPartyID
    /// Unsupported Login Identifier (trying to log with login/password on MAS-only instance)
    case unsupportedLoginIdentifier

}
