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

/// List the different result cases
enum ResolveResult {
    case authorizedThirdPartyID(info: ThirdPartyIDPlatformInfoType)
    case unauthorizedThirdPartyID
}

/// Protocol describing a service used to check whether a third-party identifier (for example: an email address) is authorized in Tchap.
/// It is used to retrieve the information of the platform associated to an authorized 3pid.
protocol ThirdPartyIDPlatformInfoResolverType {
    
    /// Check whether a third-party identifier is authorized or not.
    /// The platform information for this identifier are available only when it is authorized.
    ///
    /// - Parameters:
    ///   - address: The third party identifier (email address, msisdn,...).
    ///   - medium: the type of the third-party id (see kMX3PIDMediumEmail, kMX3PIDMediumMSISDN).
    ///   - success: A block object called when the operation succeeds.
    ///   - failure: A block object called when the operation fails.
    func resolvePlatformInformation(address: String, medium: String, success: ((ResolveResult) -> Void)?, failure: ((Error?) -> Void)?)
}
