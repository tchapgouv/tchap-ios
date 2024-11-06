// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import MatrixSDK

extension MXError {
    /// Returns custom localized message from errcode parameter of MXError.
    func authenticationErrorMessage() -> String {
        let message: String
        switch self.errcode {
        case kMXErrCodeStringForbidden:
            message = VectorL10n.loginErrorForbidden
        case kMXErrCodeStringUnknownToken:
            message = VectorL10n.loginErrorUnknownToken
        case kMXErrCodeStringBadJSON:
            message = VectorL10n.loginErrorBadJson
        case kMXErrCodeStringNotJSON:
            message = VectorL10n.loginErrorBadJson
        case kMXErrCodeStringLimitExceeded:
            message = TchapL10n.authenticationErrorLimitExceeded // Tchap
        case kMXErrCodeStringUserInUse:
            message = VectorL10n.loginErrorUserInUse
        case kMXErrCodeStringLoginEmailURLNotYet:
            message = VectorL10n.loginErrorLoginEmailNotYet
        case kMXErrCodeStringThreePIDInUse:
            message = TchapL10n.authenticationErrorEmailInUse // Tchap
        case kMXErrCodeStringPasswordTooShort:
            message = TchapL10n.passwordPolicyTooShortPwdError // Tchap
        case kMXErrCodeStringPasswordNoDigit:
            message = TchapL10n.passwordPolicyWeakPwdError // Tchap
        case kMXErrCodeStringPasswordNoLowercase:
            message = TchapL10n.passwordPolicyWeakPwdError // Tchap
        case kMXErrCodeStringPasswordNoUppercase:
            message = TchapL10n.passwordPolicyWeakPwdError // Tchap
        case kMXErrCodeStringPasswordNoSymbol:
            message = TchapL10n.passwordPolicyWeakPwdError // Tchap
        case kMXErrCodeStringWeakPassword:
            message = TchapL10n.passwordPolicyWeakPwdError // Tchap
        case kMXErrCodeStringPasswordInDictionary:
            message = TchapL10n.passwordPolicyPwdInDictError // Tchap
        default:
            message = self.error
        }

        return message
    }
}
