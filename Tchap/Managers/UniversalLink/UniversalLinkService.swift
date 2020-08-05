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

/// `UniversalLinkService` implementation of 'UniversalLinkServiceType' to handle Tchap universal links.
final class UniversalLinkService: UniversalLinkServiceType {
    
    // MARK: - Constants
    
    private enum Constants {
        static let emailValidationURLPath = "/_matrix/client/unstable/registration/email/submit_token"
        static let legacyEmailValidationURLPath = "/_matrix/identity/api/v1/validate/email/submitToken"
        static let emailValidationTokenKey = "token"
        static let emailValidationClientSecretKey = "client_secret"
        static let emailValidationSidKey = "sid"
        static let emailValidationNextLinkKey = "nextLink"
        static let registerPathParam = "register"
        static let roomPermalinkPathParam = "room"
    }
    
    private var identityService: MXIdentityService?
    private var currentOperation: MXHTTPOperation?
    
    // MARK: - Public
    
    func handleUserActivity(_ userActivity: NSUserActivity, completion: @escaping (MXResponse<UniversalLinkServiceParsingResult>) -> Void) -> Bool {
        // iOS Patch: fix Tchap urls before using it
        guard let webpageURL = userActivity.webpageURL, let url = Tools.fixURL(withSeveralHashKeys: webpageURL) else {
            return false
        }
        
        // Check whether this is an email validation link.
        if url.path == Constants.legacyEmailValidationURLPath {
            let fragment = url.absoluteString
            NSLog("[UniversalLinkService] handleUserActivity: detect a legacy email validation link")
            
            // Extract required parameters from the link
            let params = self.parseFragment(fragment)
            
            // Validate the email on the passed identity server
            if let token = params.queryParams?[Constants.emailValidationTokenKey],
                let clientSecret = params.queryParams?[Constants.emailValidationClientSecretKey],
                let sid = params.queryParams?[Constants.emailValidationSidKey],
                let scheme = url.scheme,
                let host = url.host {
                
                self.cancelPendingRequest()
                
                let identityServer: String = "\(scheme)://\(host)"
                
                let identityServiceBuilder = IdentityServiceBuilder()
                identityServiceBuilder.build(from: identityServer) { (identityServiceResult) in
                    switch identityServiceResult {
                    case .success(let identityService):
                        self.currentOperation = identityService.submit3PIDValidationToken(token,
                                                                                     medium: kMX3PIDMediumEmail,
                                                                                     clientSecret: clientSecret,
                                                                                     sid: sid,
                                                                                     completion: { (response) in
                                                                                        switch response {
                                                                                        case .success:
                                                                                            NSLog("[UniversalLinkService] handleUserActivity. Email successfully validated.")
                                                                                            
                                                                                            if let nextLink = params.queryParams?[Constants.emailValidationNextLinkKey] {
                                                                                                // Continue the registration with the passed nextLink
                                                                                                NSLog("[UniversalLinkService] handleUserActivity. Complete registration with nextLink")
                                                                                                let nextLinkURL = URL(string: nextLink)
                                                                                                if let fragment = nextLinkURL?.fragment {
                                                                                                    _ = self.handleFragment(fragment, completion: completion)
                                                                                                }
                                                                                            } else {
                                                                                                // No nextLink means validation for binding a new email
                                                                                                NSLog("[UniversalLinkService] handleUserActivity. TODO: Complete email binding")
                                                                                            }
                                                                                        case .failure(let error):
                                                                                            NSLog("[UniversalLinkService] handleUserActivity. Error: submitToken failed")
                                                                                            completion(MXResponse.failure(error))
                                                                                        }
                        })
                        self.identityService = identityService
                    case .failure(let error):
                        completion(MXResponse.failure(error))
                    }
                }
            }
            return true
        } else if url.path == Constants.emailValidationURLPath {
            NSLog("[UniversalLinkService] handleUserActivity: detect an email validation link")
            
            // We just need to ping the link.
            let urlSession = URLSession(configuration: URLSessionConfiguration.default)
            let task = urlSession.dataTask(with: url) { (data, response, error) in
                if let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200 {
                    NSLog("[UniversalLinkService] handleUserActivity. Email successfully validated.")
                    // Check whether a fragment is available in the returned url, this may be the pending register request
                    // (= nextLink)
                    if let url = httpURLResponse.url, let fragment = url.fragment {
                        // Continue the registration with the passed fragment
                        NSLog("[UniversalLinkService] handleUserActivity. Complete registration with nextLink")
                        DispatchQueue.main.async {
                            _ = self.handleFragment(fragment, completion: completion)
                        }
                    } else {
                        // No nextLink means validation for binding a new email
                        NSLog("[UniversalLinkService] handleUserActivity. TODO: Complete email binding")
                    }
                } else {
                    NSLog("[UniversalLinkService] handleUserActivity. Error: submitToken failed")
                    DispatchQueue.main.async {
                        let defaultError = NSError(domain: "UniversalLinkServiceErrorDomain", code: 0, userInfo: [NSLocalizedFailureReasonErrorKey: TchapL10n.registrationEmailValidationFailedTitle, NSLocalizedDescriptionKey: TchapL10n.registrationEmailValidationFailedMsg])
                        completion(MXResponse.failure(error ?? defaultError))
                    }
                }
                
                if let data = data {
                    NSLog("[UniversalLinkService] handleUserActivity: Link validation Data: \(String(data: data, encoding: String.Encoding.utf8) ?? "empty")")
                }}
            task.resume()
            return true
        } else if let fragment = url.fragment {
            return self.handleFragment(fragment, completion: completion)
        }
        return false
    }
    
    func handleFragment(_ fragment: String, completion: @escaping (MXResponse<UniversalLinkServiceParsingResult>) -> Void) -> Bool {
        NSLog("[UniversalLinkService] handleFragment: \(fragment)")
        
        // Extract required parameters from the link
        let params = parseFragment(fragment)
        guard params.pathParams.isEmpty == false else {
            NSLog("[UniversalLinkService] handleFragment: Error: No path parameters")
            return false
        }
        
        let isSupported: Bool
        
        // Check whether this is a registration links.
        if params.pathParams[0] == Constants.registerPathParam, let registerParams = params.queryParams {
            NSLog("[UniversalLinkService] handleFragment: link with registration parameters")
            completion(MXResponse.success(.registrationLink(params: registerParams)))
            isSupported = true
        } else if params.pathParams[0] == Constants.roomPermalinkPathParam, params.pathParams.count >= 2 {
            NSLog("[UniversalLinkService] handleFragment: link with room parameters")
            // The link is the form of "/room/[roomIdOrAlias]" or "/room/[roomIdOrAlias]/[eventId]"
            let roomIdOrAlias = params.pathParams[1]
            var eventId: String?
            
            // Is it a link to an event of a room?
            if params.pathParams.count == 3 {
                eventId = params.pathParams[2]
            }
            
            completion(MXResponse.success(.roomLink(roomIdOrAlias, eventID: eventId)))
            isSupported = true
        } else if params.pathParams[0].hasPrefix("#") || params.pathParams[0].hasPrefix("!") {
            NSLog("[UniversalLinkService] handleFragment: link with room parameters")
            // The link is the form of "/[roomIdOrAlias]" or "/[roomIdOrAlias]/[eventId]"
            // Such links come from matrix.to permalinks
            let roomIdOrAlias = params.pathParams[0]
            var eventId: String?
            
            // Is it a link to an event of a room?
            if params.pathParams.count == 2 {
                eventId = params.pathParams[1]
            }
            completion(MXResponse.success(.roomLink(roomIdOrAlias, eventID: eventId)))
            isSupported = true
        } else {
            NSLog("[UniversalLinkService] handleFragment: Do not know what to do with the link arguments: %@", params.pathParams)
            isSupported = false
        }
        
        return isSupported
    }
    
    func cancelPendingRequest() {
        self.currentOperation?.cancel()
        self.identityService = nil
    }
    
    // MARK: - Private
    
    private func parseFragment(_ fragment: String) -> UniversalLinkParameters {
        var pathParams = [String]()
        var queryParams: [String: String]?
        
        let fragmentParts = fragment.split(separator: "?")
        
        if let firstFragment = fragmentParts.first {
            // Extract path params by removing empty ones, and removing percent encoding
            let pathSubstrings = firstFragment.split(separator: "/").filter { !$0.isEmpty }
            for substring in pathSubstrings {
                if let param = substring.removingPercentEncoding {
                    pathParams.append(param)
                }
            }
            
            // Extract query params if any
            // Query params are in the form [queryParam1Key]=[queryParam1Value], so the
            // presence of at least one '=' character is mandatory
            if fragmentParts.count == 2 {
                var queryParameters = [String: String]()
                let querySubstrings = fragmentParts[1].split(separator: "&").filter { $0.contains("=") }
                for substring in querySubstrings {
                    let key = substring.split(separator: "=")[0]
                    if let value = substring.split(separator: "=")[1].replacingOccurrences(of: "+", with: " ").removingPercentEncoding {
                        queryParameters[String(key)] = String(value)
                    }
                }
                
                if !queryParameters.isEmpty {
                    queryParams = queryParameters
                }
            }
        }
        
        return UniversalLinkParameters(pathParams: pathParams, queryParams: queryParams)
    }
}
