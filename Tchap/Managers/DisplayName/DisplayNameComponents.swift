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

/// A structure that parses display name and constructs their constituent parts.
struct DisplayNameComponents {
    
    // MARK: - Constants
    
    private enum Constants {
        static let displayNameDomainLeftSeparator = "["
        static let displayNameDomainRightSeparator = "]"
        static let matrixIdPrefix = "@"
        static let homeServerSeparator = ":"
    }
    
    // MARK: - Properties
    
    let name: String
    let domain: String?
    
    // MARK: - Setup
    
    init(displayName: String) {
        let (name, domain) = DisplayNameComponents.getNamePlusDomain(from: displayName)
        
        self.name = name
        self.domain = domain
    }

    init?(userId: String) {
        guard let name = DisplayNameComponents.getName(from: userId) else {
            return nil
        }
        self.name = name
        self.domain = nil
    }
    
    // MARK: - Private
    
    /// Build the potential name and domain name from a display name.
    /// For example in case of "Jean Martin [Modernisation]", this will return "Jean Martin" as name and "Modernisation" as domain.
    ///
    ///  - Parameter displayName: The display name to parse
    ///  - Returns: name, and domain if available.
    private static func getNamePlusDomain(from displayName: String) -> (String, String?) {
        
        let name: String
        let domain: String?
        
        if let domainLeftSeparatorRange = displayName.range(of: Constants.displayNameDomainLeftSeparator) {
            name = String(displayName.prefix(upTo: domainLeftSeparatorRange.lowerBound)).trimmingCharacters(in: .whitespacesAndNewlines)
            domain = String(displayName.suffix(from: domainLeftSeparatorRange.upperBound)).replacingOccurrences(of: Constants.displayNameDomainRightSeparator, with: "")
        } else {
            name = displayName
            domain = nil
        }
        
        return (name, domain)
    }
    
    /// Build a display name from the tchap user identifier.
    /// We don't extract the domain for the moment in order to not display unexpected information.
    /// For example in case of "@jean.martin-modernisation.fr:matrix.org", this will return "Jean Martin".
    ///
    /// - Parameter userId: The user id to parse
    /// - Returns: displayName without domain, nil if the id is not valid.
    private static func getName(from userId: String) -> String? {
        guard MXTools.isMatrixUserIdentifier(userId),
            let homeServerSeparatorIndex = userId.range(of: Constants.homeServerSeparator)?.lowerBound else {
            return nil
        }
        
        let beforeHomeServerSeparatorString = String(userId.prefix(upTo: homeServerSeparatorIndex))
        
        let beforeLastHyphenString: String
        
        // Take substring until the last hyphen if exist
        if let hyphenIndex = beforeHomeServerSeparatorString.range(of: "-", options: String.CompareOptions.backwards)?.lowerBound {
            beforeLastHyphenString = String(beforeHomeServerSeparatorString.prefix(upTo: hyphenIndex))
        } else {
            beforeLastHyphenString = beforeHomeServerSeparatorString
        }
        
        let displayName = beforeLastHyphenString
            .replacingOccurrences(of: Constants.matrixIdPrefix, with: "")
            .replacingOccurrences(of: ".", with: " ")
            .capitalized
        return displayName
    }
}
