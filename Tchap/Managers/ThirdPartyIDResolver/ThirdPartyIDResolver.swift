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
    
    /// The current HttpClient
    private let httpClient: MXHTTPClient
    
    // MARK: - Public
    @objc init(credentials: MXCredentials) {
        guard let homeServer = credentials.homeServer,
            let accessToken = credentials.accessToken else {
                fatalError("credentials should be defined")
        }
        self.httpClient = MXHTTPClient(baseURL: "\(homeServer)/\(kMXAPIPrefixPathUnstable)", accessToken: accessToken, andOnUnrecognizedCertificateBlock: nil)
    }
    
    func lookup(address: String, medium: MX3PID.Medium, identityServer: String, completion: @escaping (MXResponse<String?>) -> Void) -> MXHTTPOperation? {
        guard let identityServerURL = URL(string: identityServer),
            let identityServerHost = identityServerURL.host else {
                return nil
        }
        
        return httpClient.request(withMethod: "GET", path: "account/3pid/lookup", parameters: ["address": address, "medium": medium.identifier, "id_server": identityServerHost], success: { (response: [AnyHashable: Any]?) in
            NSLog("[ThirdPartyIDResolver] lookup resquest succeeded")
            guard let response = response else {
                completion(.success(nil))
                return
            }
            let mxid = response["mxid"] as? String
            completion(.success(mxid))
        }, failure: { (error: Error?) in
            NSLog("[ThirdPartyIDResolver] lookup resquest failed")
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(ThirdPartyIDResolverError.unknown))
            }
        })
    }
    
    func bulkLookup(threepids: [(MX3PID.Medium, String)], identityServer: String, completion: @escaping (MXResponse<[(MX3PID.Medium, String, String)]?>) -> Void) -> MXHTTPOperation? {
        let ids = threepids.map { (medium, address) -> [String] in
            return [medium.identifier, address]
        }
        
        return bulkLookup(threepids: ids,
                          identityServer: identityServer,
                          success: { (discoveredUsers: [[String]]?) in
                            if let discoveredUsers = discoveredUsers {
                                let result = discoveredUsers.compactMap { triplet -> (MX3PID.Medium, String, String)? in
                                    // Make sure the array contains 3 items
                                    guard triplet.count == 3 else {
                                        return nil
                                    }
                                    
                                    return (MX3PID.Medium(identifier: triplet[0]), triplet[1], triplet[2])
                                }
                                completion(.success(result))
                            } else {
                                completion(.success(nil))
                            }},
                          failure: { (error: Error?) in
                            if let error = error {
                                completion(.failure(error))
                            } else {
                                completion(.failure(ThirdPartyIDResolverError.unknown))
                            }})
    }
    
    @objc func bulkLookup(threepids: [[String]], identityServer: String, success: @escaping (([[String]]?) -> Void), failure: @escaping ((Error?) -> Void)) -> MXHTTPOperation? {
        guard let identityServerURL = URL(string: identityServer),
            let identityServerHost = identityServerURL.host,
            let payloadData = try? JSONSerialization.data(withJSONObject: ["threepids": threepids, "id_server": identityServerHost], options: []) else {
                return nil
        }
        
        return httpClient.request(withMethod: "POST",
                                  path: "account/3pid/bulk_lookup",
                                  parameters: nil,
                                  data: payloadData,
                                  headers: ["Content-Type": "application/json"],
                                  timeout: -1,
                                  uploadProgress: nil,
                                  success: { (response: [AnyHashable: Any]?) in
                                    NSLog("[ThirdPartyIDResolver] bulk_lookup resquest succeeded")
                                    guard let response = response else {
                                        failure(ThirdPartyIDResolverError.unknown)
                                        return
                                    }
                                    // The server returns a dictionary with key 'threepids', which is a list of results
                                    // where each result is a 3 item list of medium, address, mxid.
                                    if let discoveredUsers = response["threepids"] as? [[String]] {
                                        success(discoveredUsers)
                                    } else {
                                        failure(ThirdPartyIDResolverError.unknown)
                                    }},
                                  failure: failure)
    }
}
