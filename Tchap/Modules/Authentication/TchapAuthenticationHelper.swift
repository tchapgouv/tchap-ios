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
}
