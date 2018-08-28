/*
 Copyright 2018 New Vector Ltd
 
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

import Foundation

/// Used to transform authentication error to `ErrorPresentable`
final class AuthenticationErrorPresentableMaker {
    
    // MARK: - Public
    
    func errorPresentable(from error: Error) -> ErrorPresentable? {
        
        if let authenticationServiceError = error as? AuthenticationServiceError {
            return self.authenticationServerErrorPresentable(from: authenticationServiceError)
        }
        
        let nsError = error as NSError
        
        // Ignore connection cancellation error
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            print("[AuthenticationErrorPresenter] Auth request cancelled")
            return nil
        }
        
        if let resourceLimitExceededErrorPresentable = self.resourceLimitExceededErrorPresentable(from: error) {
            return resourceLimitExceededErrorPresentable
        }
        
        let title: String
        let message: String
        
        // Translate the error code to a human message
        if let localizedFailureReason = nsError.localizedFailureReason {
            title = localizedFailureReason
        } else {
            title = Bundle.mxk_localizedString(forKey: "login_error_title")
        }
        
        let dict = nsError.userInfo
        
        if !dict.isEmpty {

            let errorCode = dict["errcode"] as? String
            
            if let localizedError = dict["error"] as? String {
                message = localizedError
            } else if let errCode = errorCode {
                
                switch errCode {
                case kMXErrCodeStringForbidden:
                    message = Bundle.mxk_localizedString(forKey: "login_error_forbidden")
                case kMXErrCodeStringUnknownToken:
                    message = Bundle.mxk_localizedString(forKey: "login_error_unknown_token")
                case kMXErrCodeStringBadJSON:
                    message = Bundle.mxk_localizedString(forKey: "login_error_bad_json")
                case kMXErrCodeStringNotJSON:
                    message = Bundle.mxk_localizedString(forKey: "login_error_bad_json")
                case kMXErrCodeStringLimitExceeded:
                    message = Bundle.mxk_localizedString(forKey: "login_error_limit_exceeded")
                case kMXErrCodeStringUserInUse:
                    message = Bundle.mxk_localizedString(forKey: "login_error_user_in_use")
                case kMXErrCodeStringLoginEmailURLNotYet:
                    message = Bundle.mxk_localizedString(forKey: "login_error_login_email_not_yet")
                default:
                    message = errCode
                }                                
            } else {
                message = error.localizedDescription
            }
        } else {
            message = error.localizedDescription
        }
        
        return ErrorPresentableImpl(title: title, message: message)
    }
    
    // MARK: - Private
    
    private func authenticationServerErrorPresentable(from authenticationServiceError: AuthenticationServiceError) -> ErrorPresentable {
        
        let title: String = Bundle.mxk_localizedString(forKey: "login_error_title")
        let message: String
        
        switch authenticationServiceError {
        case .unauthorizedThirdPartyID:
            message = Bundle.mxk_localizedString(forKey: "login_error_forbidden")
        case .userAlreadyLoggedIn:
            message = Bundle.mxk_localizedString(forKey: "login_error_already_logged_in")
        default:
            message = TchapL10n.errorMessageDefault
        }
        
        return ErrorPresentableImpl(title: title, message: message)
    }
    
    private func resourceLimitExceededErrorPresentable(from error: Error) -> ErrorPresentable? {
        let errorInfo = (error as NSError).userInfo
        
        guard !errorInfo.isEmpty, let errorCode = errorInfo["errcode"] as? String, errorCode == kMXErrCodeStringResourceLimitExceeded else {
            return nil
        }

        return resourceLimitExceededErrorPresentable(from: errorInfo)
    }
    
    private func resourceLimitExceededErrorPresentable(from errorDict: [AnyHashable : Any]) -> ErrorPresentable {
        
        let title: String = Bundle.mxk_localizedString(forKey: "login_error_resource_limit_exceeded_title")
        var message = ""
        
        // Parse error data
        let limitType = errorDict[kMXErrorResourceLimitExceededLimitTypeKey] as? String
        
        // Build the message content
        
        if limitType == kMXErrorResourceLimitExceededLimitTypeMonthlyActiveUserValue {
            message += Bundle.mxk_localizedString(forKey: "login_error_resource_limit_exceeded_message_monthly_active_user")
        } else {
            message += Bundle.mxk_localizedString(forKey: "login_error_resource_limit_exceeded_message_default")
        }
        
        message += Bundle.mxk_localizedString(forKey: "login_error_resource_limit_exceeded_message_contact")
        
        return ErrorPresentableImpl(title: title, message: message)
    }
}
