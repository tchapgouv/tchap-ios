//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

/// Using an enum for the screen allows you define the different state cases with
/// the relevant associated data for each case.
enum MockAuthenticationVerifyEmailScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case emptyAddress
    case enteredAddress
    case hasSentEmail
    case toggleTermsAndConditions // Tchap: Add Terms and Conditions.
    
    /// The associated screen
    var screenType: Any.Type {
        AuthenticationVerifyEmailScreen.self
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let viewModel: AuthenticationVerifyEmailViewModel
        // Tchap: No homeserver
        switch self {
        case .emptyAddress:
            viewModel = AuthenticationVerifyEmailViewModel(/*homeserver: .mockMatrixDotOrg,
                                                           */emailAddress: "")
        case .enteredAddress:
            viewModel = AuthenticationVerifyEmailViewModel(/*homeserver: .mockMatrixDotOrg,
                                                           */emailAddress: "test@example.com")
        case .hasSentEmail:
            viewModel = AuthenticationVerifyEmailViewModel(/*homeserver: .mockMatrixDotOrg,
                                                           */emailAddress: "test@example.com")
            Task { await viewModel.updateForSentEmail() }
        case .toggleTermsAndConditions: // Tchap: Add Terms and Conditions.
            viewModel = AuthenticationVerifyEmailViewModel(emailAddress: "test@example.com")
        }
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [viewModel], AnyView(AuthenticationVerifyEmailScreen(viewModel: viewModel.context))
        )
    }
}
