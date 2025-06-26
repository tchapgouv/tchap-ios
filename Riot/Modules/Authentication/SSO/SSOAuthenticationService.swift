// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum SSOAuthenticationServiceError: Error {
    case tokenNotFound
    case userCanceled
    case unknown
}

@objc protocol SSOAuthenticationServiceProtocol {
    var callBackURLScheme: String? { get }

    // Tchap: add `loginHint` string parameter for SSO
//    func authenticationURL(for identityProvider: String?, transactionId: String) -> URL?
    func authenticationURL(for identityProvider: String?, loginHint: String?, transactionId: String) -> URL?

    func loginToken(from url: URL) -> String?
}

@objcMembers
final class SSOAuthenticationService: NSObject, SSOAuthenticationServiceProtocol {
    
    // MARK: - Constants
    
    // MARK: - Properties
    
    private let homeserverStringURL: String
        
    let callBackURLScheme: String?
    
    // MARK: - Setup
    
    init(homeserverStringURL: String) {
        self.homeserverStringURL = homeserverStringURL
        self.callBackURLScheme = BuildSettings.applicationURLScheme
        super.init()
    }
    
    // MARK: - Public
    
    // Tchap: add `loginHint` string parameter for SSO and pass it into url query parameter to SSO portal.
    // Tchap: rewrite `authenticationURL(for:loginHint:transactionId:) method because of problem with email addresses containing `+` character
    // in URL query parameters automatically encoded in a way not supported by ProConnect backend (double encoding done by URLComponents).
    // Methods added in URLComponents and URL that could help us require iOS 16+ or iOS 17+. We need to support iOS 15.
//    func authenticationURL(for identityProvider: String?, transactionId: String) -> URL? {
//        guard var authenticationComponent = URLComponents(string: self.homeserverStringURL) else {
//            return nil
//        }
//        
//        var ssoRedirectPath = SSOURLConstants.Paths.redirect
//        
//        if let identityProvider = identityProvider, !identityProvider.isEmpty {
//            ssoRedirectPath.append("/\(identityProvider)")
//        }
//        
//        authenticationComponent.path = ssoRedirectPath
//        
//        var queryItems: [URLQueryItem] = []
//        
//        if let callBackURLScheme = self.buildCallBackURL(with: transactionId) {
//            queryItems.append(URLQueryItem(name: SSOURLConstants.Parameters.redirectURL, value: callBackURLScheme))
//        }
//        
//        authenticationComponent.queryItems = queryItems
//
//        return authenticationComponent.url
//    }
    
    func authenticationURL(for identityProvider: String?, loginHint: String? = nil, transactionId: String) -> URL? {
        // Don't Verify that homeserverStringURL is encodable for URL because the scheme `https` is contained in the string
        // and it will be escaped and this encoding will break on usage.
        // Just check that it is convertible to an URL.
        guard URL(string: self.homeserverStringURL) != nil else {
            return nil
        }
        var authenticationUrlString = self.homeserverStringURL
        
        // Prepare redirect path part.
        //
        var ssoRedirectPath = SSOURLConstants.Paths.redirect
        
        if let identityProvider = identityProvider, !identityProvider.isEmpty {
            ssoRedirectPath.append("/\(identityProvider)")
        }
        
        // Verify that ssoRedirectPath is encodable for URL.
        guard let pathUrlEncoded = ssoRedirectPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return nil
        }
        authenticationUrlString.append(pathUrlEncoded)
        
        // Prepare Query part.
        //
        var queryItems: [URLQueryItem] = []
        
        // Verify that callBackURLScheme is encodable for URL.
        if let callBackURLScheme = self.buildCallBackURL(with: transactionId),
           let callBackURLSchemeUrlEncoded = callBackURLScheme.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            queryItems.append(URLQueryItem(name: SSOURLConstants.Parameters.redirectURL, value: callBackURLSchemeUrlEncoded))
        }
        
        // Tchap: https://github.com/tchapgouv/tchap-ios/issues/1190
        // We want to allow email addresses containing `+` character as URL query parameters. But the `+` char is historically replaced with SPACE backend side.
        // We have to percent encode it. So we must use a customized allowed Character Set: URLQuesryAllowd minus `+` char.
        let mutableUrlQueryMinusPlusAllowed = NSMutableCharacterSet() //create an empty mutable set
        mutableUrlQueryMinusPlusAllowed.formUnion(with: .urlQueryAllowed)
        mutableUrlQueryMinusPlusAllowed.removeCharacters(in: "+")
        let urlQueryMinusPlusAllowed = mutableUrlQueryMinusPlusAllowed as CharacterSet
        
        // Verify that loginHint is encodable for URL.
        if let loginHint,
           let loginHinturlEncoded = loginHint.addingPercentEncoding(withAllowedCharacters: urlQueryMinusPlusAllowed) {
            queryItems.append(URLQueryItem(name: SSOURLConstants.Parameters.loginHint, value: loginHinturlEncoded))
        }
        
        let queryString = queryItems.reduce(into: "") { result, item in
            result += "\(result.isEmpty ? "" : "&")\(item.name)=\(item.value ?? "")"
        }
        
        authenticationUrlString.append("?\(queryString)")

        return URL(string: authenticationUrlString)
    }
    
    func loginToken(from url: URL) -> String? {
        // If needed convert URL string from HTML entities into correct character representations using UTF8  (like '&amp;' with '&')
        guard let sanitizedStringURL = url.absoluteString.replacingHTMLEntities(),
              let components = URLComponents(string: sanitizedStringURL) else {
            return nil
        }
        return components.vc_getQueryItemValue(for: SSOURLConstants.Parameters.callbackLoginToken)
    }
    
    // MARK: - Private
    
    private func buildCallBackURL(with transactionId: String) -> String? {
        guard let callBackURLScheme = self.callBackURLScheme else {
            return nil
        }
        var urlComponents = URLComponents()
        urlComponents.scheme = callBackURLScheme
        urlComponents.host = CustomSchemeURLConstants.Hosts.connect
        
        // Transaction id is used to indentify the request
        urlComponents.queryItems = [URLQueryItem(name: CustomSchemeURLConstants.Parameters.transactionId, value: transactionId)]
        return urlComponents.string
    }
}
