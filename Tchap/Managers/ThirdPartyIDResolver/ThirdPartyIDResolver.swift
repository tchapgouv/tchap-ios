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

enum ThirdPartyIDResolverError: Error {
    case unknown
}

/// `ThirdPartyIDResolver` to discover Tchap users from third-party identifiers.
final class ThirdPartyIDResolver: NSObject, ThirdPartyIDResolverType {
    
    /// The current session
    private let session: MXSession
    
    // MARK: - Public
    @objc init(session: MXSession) {
        self.session = session
    }
    
    // MARK: - Public
    @objc func bulkLookup(threepids: [[String]],
                          success: @escaping (([[String]]) -> Void),
                          failure: @escaping ((Error) -> Void)) -> MXHTTPOperation? {
        
        guard let identityService = session.identityService else {
            return nil
        }
        
        let pids: [MX3PID]? = threepids.compactMap { tempPid in
            return MX3PID.threePidFromArray(tempPid)
        }
        
        guard let pids = pids else {
            return nil
        }
        
        return identityService.lookup3PIDs(pids) { lookupResponse in
            switch lookupResponse {
            case .success(let threePids):
                MXLog.debug("[ThirdPartyIDResolver] bulk_lookup resquest succeeded")

                // The server returns a dictionary with key 'threepids', which is a list of results
                // where each result is a 3 item list of medium, address, mxid.
                if threePids.isEmpty == false {
                    var discoveredUsers: [[String]] = []
                    for (pid, value) in threePids {
                        discoveredUsers.append(pid.arrayFromThreePid(with: value))
                    }
                    success(discoveredUsers)
                } else {
                    failure(ThirdPartyIDResolverError.unknown)
                }
            case .failure(let error):
                failure(error)
            }
        }
    }
}
