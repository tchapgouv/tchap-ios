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

/// `RestClientBuilder` allows to create an `MXRestClient`.
final class RestClientBuilder {
    
    // MARK: - Public

    /// Create an `MXRestClient` based on email address. Homeserver is determined by the email address and homeserver is needed to create an `MXRestClient`.
    ///
    /// - Parameters:
    ///   - email: The user email.
    ///   - completion: A closure called when the operation complete. Provide the rest client when succeed.
    func build(fromEmail email: String, completion: @escaping (MXResponse<MXRestClient>) -> Void) {
        
        self.resolveHomeServer(with: email) { (resolveResult) in
            switch resolveResult {
            case .success(let homeServer):
                do {
                    let restClient = try self.createRestClient(homeServerStringURL: homeServer)
                    completion(MXResponse.success(restClient))
                } catch {
                    completion(MXResponse.failure(error))
                }
            case .failure(let error):
                completion(MXResponse.failure(error))
            }
        }
    }
    
    /// Create an `MXRestClient` based on a homeserver.
    ///
    /// - Parameters:
    ///   - homeserver: The homeserver.
    ///   - completion: A closure called when the operation complete. Provide the rest client when succeed.
    func build(fromHomeServer homeServer: String, completion: @escaping (MXResponse<MXRestClient>) -> Void) {
        do {
            let restClient = try self.createRestClient(homeServerStringURL: homeServer)
            completion(MXResponse.success(restClient))
        } catch {
            completion(MXResponse.failure(error))
        }
    }
    
    // MARK: - Private
    
    private func resolveHomeServer(with mail: String, completion: @escaping (MXResponse<String>) -> Void) {
        // Create a new resolver each time user wants to login because identityServerURLs should be shuffled.
        let thirdPartyIDPlatformInfoResolver = self.createThirdPartyIDPlatformInfoResolver()
        
        thirdPartyIDPlatformInfoResolver.resolvePlatformInformation(address: mail, medium: kMX3PIDMediumEmail, success: { (resolveResult) in
            switch resolveResult {
            case .authorizedThirdPartyID(info: let thirdPartyIDPlatformInfo):
                completion(MXResponse.success(thirdPartyIDPlatformInfo.homeServer))
            case .unauthorizedThirdPartyID:
                completion(MXResponse.failure(RestClientBuilderError.unauthorizedThirdPartyID))
            }
        }, failure: { (error) in
            completion(MXResponse.failure(RestClientBuilderError.thirdPartyIDResolveFailure(error: error)))
        })
    }
    
    private func createThirdPartyIDPlatformInfoResolver() -> ThirdPartyIDPlatformInfoResolver {
        guard let serverUrlPrefix = UserDefaults.standard.string(forKey: "serverUrlPrefix") else {
            fatalError("serverUrlPrefix should be defined")
        }
        let identityServerURLs = IdentityServersURLGetter(currentIdentityServerURL: nil).identityServerUrls
        let thirdPartyIDPlatformInfoResolver = ThirdPartyIDPlatformInfoResolver(identityServerUrls: identityServerURLs, serverPrefixURL: serverUrlPrefix)
        return thirdPartyIDPlatformInfoResolver
    }
    
    private func createRestClient(homeServerURL: URL, onUnrecognizedCertificate: @escaping MXHTTPClientOnUnrecognizedCertificate) -> MXRestClient {
        return MXRestClient(homeServer: homeServerURL) { (certificateData) -> Bool in
            onUnrecognizedCertificate(certificateData)
        }
    }
    
    private func createRestClient(homeServerURL: URL) -> MXRestClient {
        let onUnrecognizedCertificate = self.onUnrecognizedCertificateAction(homeServerURL: homeServerURL)
        
        return self.createRestClient(homeServerURL: homeServerURL) { (certificateData) -> Bool in
            // TODO: Update MXRestClient with better unrecognized certificate error handling as MXRestClient is unusable when `onUnrecognizedCertBlock` return false.
            // NOTE: By returning false here for invalid certicate give us an error with error code `NSURLErrorCancelled` when call any endpoint on MXRestClient.
            return onUnrecognizedCertificate(certificateData)
        }
    }
    
    private func createRestClient(homeServerStringURL: String) throws -> MXRestClient {
        guard let homeServerURL = URL(string: homeServerStringURL) else {
            throw RestClientBuilderError.homeServerURLBuildFailed
        }
        
        let restClient = self.createRestClient(homeServerURL: homeServerURL)
        
        // Force the identity server url with the provided homeserver (to keep temporarily the historical behavior)
        // TODO: Use a MXIdentityService to handle the request to id server when it will be available in matrixSDK
        restClient.identityServer = homeServerStringURL
        
        return restClient
    }
    
    private func onUnrecognizedCertificateAction(homeServerURL: URL) -> MXHTTPClientOnUnrecognizedCertificate {
        let onUnrecognizedCertificate: MXHTTPClientOnUnrecognizedCertificate = { (certificateData) -> Bool in
            
            let certificateFingerprint: String
            
            if let certificateData = certificateData {
                certificateFingerprint = (certificateData as NSData).mx_SHA256AsHexString()
            } else {
                certificateFingerprint = ""
            }
            
            print("[RestClientBuilder] Unrecognize certificate for homeserver: \(homeServerURL.absoluteString)\nfingerprint: \(certificateFingerprint)")
            
            return false
        }
        
        return onUnrecognizedCertificate
    }    
}
