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

/// A structure that parses a HomeServer hostname and constructs its display name.
/// The display name is capitalized.
/// The Tchap HS display name is the component mentioned before a predefined suffix (currently: "tchap.gouv.fr")
/// For example in case of "@jean-philippe.martin-modernisation.fr:name1.tchap.gouv.fr", this will return "Name1".
/// in case of "@jean-philippe.martin-modernisation.fr:agent.name2.tchap.gouv.fr", this will return "Name2".
struct HomeServerComponents {
    
    // MARK: - Constants
    
    private enum Constants {
        static let homeServerSuffix: String = "tchap.gouv.fr"
        static let homeServerComponentsSeparator: Character = "."
    }
    
    // MARK: - Properties
    
    let displayName: String?
    
    // MARK: - Setup
    
    init(hostname: String) {
        self.displayName = HomeServerComponents.getHomeServerDisplayName(from: hostname)
    }
    
    // MARK: - Private
    
    private static func getHomeServerDisplayName(from hostname: String) -> String? {
        let displayName: String?
        
        let homeServerSubDomainComponents = hostname.replacingOccurrences(of: Constants.homeServerSuffix, with: "").split(separator: Constants.homeServerComponentsSeparator)
        
        if let domainSubtring = homeServerSubDomainComponents.last {
            displayName = String(domainSubtring).capitalized
        } else {
            displayName = nil
        }
        
        return displayName
    }
}
