// 
// Copyright 2025 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum TchapAuthenticationHelper {
    enum ClientError: Error {
        /// An unexpected response was received.
        case invalidURL
        case invalidResult
    }

    static public func GetInstance(for email: String) async throws -> String {
        struct InstanceReturnValue: Decodable {
            let hs: String
        }
        
        let homeServerAddress = AuthenticationService.shared.state.homeserver.address
        
        // MXRestClient has no global `request` method exposed.
        // So, I have to make my own and use the shared URLSession.
        guard let url = URL(string: "\(homeServerAddress)/\(kMXIdentityAPIPrefixPathV1)/info?medium=&address=\(email)") else {
            throw ClientError.invalidURL
            }
        
        let (data, _) = try await URLSession.shared.data(from: url)

        guard let stringResult = String(data: data, encoding: .utf8) else {
            throw ClientError.invalidResult
        }
        
        guard let stringResultData = stringResult.data(using: .utf8),
              let getInstanceResult = try? JSONDecoder().decode(InstanceReturnValue.self, from: stringResultData) else {
            throw ClientError.invalidResult
        }
        
        return getInstanceResult.hs
    }
    
    // Tchap: start login flow once email is entered, to be able to determine the correct homeServer.
    // Start login flow by updating AuthenticationService
    static public func UpdateAuthServiceForDirectAuthentication(forHomeServer homeServerAddress: String) async throws -> AuthenticationHomeserverViewData? {
        let authService = AuthenticationService.shared
        authService.reset()
        do {
            try await authService.startFlow(.login, for: homeServerAddress)
            return authService.state.homeserver.viewData
        } catch {
            MXLog.error("[AuthenticationLoginScreen] Unable to start flow for login.")
            return nil
        }
    }
    
    // Tchap: try to determine the homeServer from the user's email
    // and request this homeServer about its Authentication capabilities. (Does it offer SSO?)
    static public func RedirectToSSO(for username: String, redirectAction: @escaping (SSOIdentityProvider?) -> Void) {
        // First, request any HomeServer to get the HomeServer of the user's email domain.
        Task {
            if let instanceDomain = try? await TchapAuthenticationHelper.GetInstance(for: username) {
                if let userHomeServerViewData = try? await TchapAuthenticationHelper.UpdateAuthServiceForDirectAuthentication(forHomeServer: "\(BuildSettings.serverUrlPrefix)\(instanceDomain)") {
                   
                    // Then, now that homeServer is known, call Redirection action with possible SSO provider (eventually nil).
                    redirectAction(userHomeServerViewData.ssoIdentityProviders.first)
                }
            }
        }
    }
}
