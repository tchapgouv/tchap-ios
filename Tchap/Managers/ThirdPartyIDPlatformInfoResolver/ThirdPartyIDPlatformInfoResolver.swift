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

/// `ThirdPartyIDPlatformInfoResolver` is used to check whether a third-party identifier (for example: an email address) is authorized in Tchap.
final class ThirdPartyIDPlatformInfoResolver: ThirdPartyIDPlatformInfoResolverType {
    
    /// The list of the known identity server urls.
    private let identityServerUrls: [String]
    
    /// URL prefix used by identity and home servers.
    private let serverPrefixURL: String
    
    // MARK: - Public
    
    /// - Parameters:
    ///   - identityServerUrls: the list of the known ISes in order to run over the list until to get an answer.
    ///   - serverPrefixURL: URL prefix used by identity and home servers.
    init(identityServerUrls: [String],
         serverPrefixURL: String) {
        self.identityServerUrls = identityServerUrls
        self.serverPrefixURL = serverPrefixURL
    }
    
    func resolvePlatformInformation(address: String, medium: String, success: ((ResolveResult) -> Void)?, failure: ((Error?) -> Void)?) {
        
        // Run over all the provided identity servers until we get the Tchap platform for the provided email address.
        resolvePlatformInformation(index: 0, address: address, medium: medium, success: success, failure: failure)
    }
    
    // MARK: - Private
    
    private func resolvePlatformInformation(index: Int, address: String, medium: String, success: ((ResolveResult) -> Void)?, failure: ((Error?) -> Void)?) {
        guard index < identityServerUrls.count else {
            failure?(nil)
            return
        }
        
        let identityServer = identityServerUrls[index]
        
        guard let identityHttpClient = MXHTTPClient(baseURL: "\(identityServer)/\(kMXIdentityAPIPrefixPath)", andOnUnrecognizedCertificateBlock: nil) else {
            failure?(nil)
            return
        }
        
        let httpOperation = identityHttpClient.request(withMethod: "GET", path: "info", parameters: ["address": address, "medium": medium], success: { (response: [AnyHashable: Any]?) in
            guard let response = response else {
                success?(.unauthorizedThirdPartyID)
                return
            }
            
            NSLog("[ThirdPartyIDPlatformInfoResolver] info resquest on \(identityServer) succeeded")
            
            let isInvited = response["invited"] as? Bool ?? false
            
            var hostname: String?
            // The protected access is not supported by the ios client, use the shadow hs if any
            if let shadowHost = response["shadow_hs"] as? String {
                hostname = shadowHost
            } else if let host = response["hs"] as? String {
                hostname = host
            }
            
            if let finalHostname = hostname, finalHostname.count > 0 {
                let homeServer = "\(self.serverPrefixURL)\(finalHostname)"
                let info = ThirdPartyIDPlatformInfo(hostname: finalHostname, homeServer: homeServer, isInvited: isInvited)
                success?(.authorizedThirdPartyID(info: info))
            } else {
                success?(.unauthorizedThirdPartyID)
            }
        }, failure: { (error: Error?) in
            NSLog("[ThirdPartyIDPlatformInfoResolver] info resquest on \(identityServer) failed")
            
            // Try another identity server if any
            let index = index + 1
            if index < self.identityServerUrls.count {
                self.resolvePlatformInformation(index: index, address: address, medium: medium, success: success, failure: failure)
            } else {
                failure?(error)
            }
        })
        
        // Do not retry on failure
        httpOperation?.maxNumberOfTries = 0
    }
}
