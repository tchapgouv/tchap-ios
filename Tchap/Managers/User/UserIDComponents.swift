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

/// A structure that parses Matrix User ID and constructs their constituent parts.
struct UserIDComponents {
    
    // MARK: - Constants
    
    private enum Constants {
        static let matrixUserIdPrefix = "@"
        static let hostNameSeparator: Character = ":"
    }
    
    // MARK: - Properties
    
    let localUserID: String
    let hostName: String
    
    // MARK: - Setup
    
    init?(matrixID: String) {
        guard MXTools.isMatrixUserIdentifier(matrixID),
            let (localUserID, hostName) = UserIDComponents.getLocalUserIDAndHostName(from: matrixID) else {
            return nil
        }
        
        self.localUserID = localUserID
        self.hostName = hostName
    }
    
    // MARK: - Private    

    /// Extract local user id and hostName from Matrix ID
    ///
    /// - Parameter matrixID: A Matrix ID
    /// - Returns: A tuple with local user ID and hostName.
    private static func getLocalUserIDAndHostName(from matrixID: String) -> (String, String)? {
        let matrixIDParts = matrixID.split(separator: Constants.hostNameSeparator)
        
        guard matrixIDParts.count == 2 else {
            return nil
        }
        
        let localUserID = matrixIDParts[0].replacingOccurrences(of: Constants.matrixUserIdPrefix, with: "")
        let hostName = String(matrixIDParts[1])

        return (localUserID, hostName)
    }
}
