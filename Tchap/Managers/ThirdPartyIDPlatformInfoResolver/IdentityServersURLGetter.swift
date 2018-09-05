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


/// `IdentityServersURLGetter` is used to retrieved all the known identity server urls.
final class IdentityServersURLGetter {
    
    // MARK: - Public
    
    // The available identity servers
    let identityServerUrls: [String]
    
    /// Prepare the list of the known ISes
    ///
    /// - Parameters:
    ///   - currentIdentityServerURL: the current identity server if any.
    init(currentIdentityServerURL: String?) {
        var identityServerUrls: [String] = []
        
        // Consider first the current identity server if any.
        if let currentIdentityServerURL = currentIdentityServerURL {
            identityServerUrls.append(currentIdentityServerURL)
        }
        
        if let identityServerPrefixURL = UserDefaults.standard.string(forKey: "serverUrlPrefix") {
            if var preferredKnownHosts = UserDefaults.standard.stringArray(forKey: "preferredIdentityServerNames") {
                // Add randomly the preferred known ISes
                while preferredKnownHosts.count > 0 {
                    let index = Int(arc4random_uniform(UInt32(preferredKnownHosts.count)))
                    identityServerUrls.append("\(identityServerPrefixURL)\(preferredKnownHosts[index])")
                    preferredKnownHosts.remove(at: index)
                }
            }
            
            if var otherKnownHosts = UserDefaults.standard.stringArray(forKey: "otherIdentityServerNames") {
                // Add randomly the other known ISes
                while otherKnownHosts.count > 0 {
                    let index = Int(arc4random_uniform(UInt32(otherKnownHosts.count)))
                    identityServerUrls.append("\(identityServerPrefixURL)\(otherKnownHosts[index])")
                    otherKnownHosts.remove(at: index)
                }
            }
        }
        
        self.identityServerUrls = identityServerUrls
    }
}
