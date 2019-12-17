/*
 Copyright 2019 New Vector Ltd
 
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

enum IdentityServiceError: Error {
    case identityServiceURLBuildFailed
}

/// `IdentityServiceBuilder` allows to create an `MXIdentityService`.
final class IdentityServiceBuilder {
    
    // MARK: - Public
    
    /// Create an `MXIdentityService` based on a identity server.
    ///
    /// - Parameters:
    ///   - identityserver: The identity service.
    ///   - completion: A closure called when the operation complete. Provide the service when succeed.
    func build(from identityServer: String, completion: @escaping (MXResponse<MXIdentityService>) -> Void) {
        guard let identityServerURL = URL(string: identityServer) else {
            completion(MXResponse.failure(IdentityServiceError.identityServiceURLBuildFailed))
            return
        }
        
        let restClientBuilder = RestClientBuilder()
        
        restClientBuilder.build(fromHomeServer: identityServer) { (restClientBuilderResult) in
            switch restClientBuilderResult {
            case .success(let restClient):
                let identityService = MXIdentityService(identityServer: identityServerURL, accessToken: nil, homeserverRestClient: restClient)
                completion(MXResponse.success(identityService))
            case .failure(let error):
                completion(MXResponse.failure(error))
            }
        }
    }
}
