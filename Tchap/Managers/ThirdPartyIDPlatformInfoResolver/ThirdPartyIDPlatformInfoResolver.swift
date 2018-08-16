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

/// List the different result cases
public enum ResolveResult {
    case authorizedThirdPartyID(info: ThirdPartyIDPlatformInfoType)
    case unauthorizedThirdPartyID
}

/// `ThirdPartyIDPlatformInfoResolver` is used to check whether a third-party identifier (for example: an email address) is authorized in Tchap.
/// It is used to retrieve the information of the platform associated to an authorized 3pid.
final public class ThirdPartyIDPlatformInfoResolver: NSObject {
    
    // The list of the known ISes in order to run over the list until to get an answer.
    private let identityServerUrls: [String]
    private var currentIndex = 0;
    
    // MARK: - Public
    
    /// - Parameters:
    ///   - identityServerUrls: the list of the known ISes in order to run over the list until to get an answer.
    public init(identityServerUrls: [String]) {
        self.identityServerUrls = identityServerUrls
        
        super.init()
    }
    
    /// Check whether a third-party identifier is authorized or not.
    /// The platform information for this identifier are available only when it is authorized.
    ///
    /// - Parameters:
    ///   - address: The third party identifier (email address, msisdn,...).
    ///   - medium: the type of the third-party id (see kMX3PIDMediumEmail, kMX3PIDMediumMSISDN).
    ///   - success: A block object called when the operation succeeds.
    ///   - failure: A block object called when the operation fails.
    public func resolvePlatformInformationFor(address: String, medium: String, success: ((ResolveResult) -> Void)?, failure: ((Error?) -> Void)?) {
        guard currentIndex < identityServerUrls.count else {
            failure?(nil)
            return
        }
        
        let identityServer = identityServerUrls[currentIndex]
        
        guard let identityHttpClient = MXHTTPClient(baseURL: "\(identityServer)\(kMXIdentityAPIPrefixPath)", andOnUnrecognizedCertificateBlock: nil) else {
                failure?(nil)
                return
        }
        
        identityHttpClient.request(withMethod: "GET", path: "info", parameters: ["address": address, "medium": medium], success: { (response: [AnyHashable: Any]?) in
            guard let response = response else {
                success?(.unauthorizedThirdPartyID)
                return
            }
            
            NSLog("[ThirdPartyIDPlatformInfoResolver] info resquest on \(identityServer) succeeded")
            
            let isInvited = response["invited"] as? Bool ?? false
            
            if let hostname = response["hs"] as? String {
                let info = ThirdPartyIDPlatformInfo(hostname: hostname, isInvited: isInvited);
                success?(.authorizedThirdPartyID(info: info));
            } else {
                success?(.unauthorizedThirdPartyID);
            }
        }, failure: { (error: Error?) in
            NSLog("[ThirdPartyIDPlatformInfoResolver] info resquest on \(identityServer) failed")
            
            // Try another identity server
            self.currentIndex += 1
            if self.currentIndex < self.identityServerUrls.count {
                // Try on anothezr server
                self.resolvePlatformInformationFor(address: address, medium: medium, success: success, failure: failure)
            } else {
                failure?(error)
            }
        })
    }
}
