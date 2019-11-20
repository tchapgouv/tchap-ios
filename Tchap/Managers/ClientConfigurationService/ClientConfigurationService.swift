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

enum ClientConfigurationServiceError: Error {
    case unknown
}

final class ClientConfigurationService: ClientConfigurationServiceType {
    
    // MARK: - Properties
    
    private let httpClient: MXHTTPClient
    private let serializationService: SerializationServiceType
    
    // MARK: - Setup
    
    init() {
        self.httpClient = MXHTTPClient (baseURL: TchapDefaults.clientConfigURL, andOnUnrecognizedCertificateBlock: nil)
        self.serializationService = SerializationService()
    }
    
    // MARK: - Public
    
    func getClientConfiguration(completion: @escaping (Result<ClientConfiguration, Error>) -> Void) -> MXHTTPOperation? {
        return self.httpClient.request(withMethod: "GET", path: "", parameters: nil, success: { (json) in
            guard let jsonDict = json as? [String: Any]  else {
                completion(.failure(ClientConfigurationServiceError.unknown))
                return
            }
            
            do {
                let clientConfiguration: ClientConfiguration = try self.serializationService.deserialize(jsonDict)
                completion(.success(clientConfiguration))
            } catch {
                completion(.failure(error))
            }
            
        }, failure: { error in
            let finalError: Error
            
            if let error = error {
                finalError = error
            } else {
                finalError = ClientConfigurationServiceError.unknown
            }
            
            completion(.failure(finalError))
        })
    }
}
