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

/// `UserService` implementation of `UserServiceType` is used to handle Tchap users.
final class UserService: UserServiceType {
    
    // MARK: - Constants
    
    private enum Constants {
        static let searchUsersLimit: UInt = 50
    }
    
    // MARK: - Properties
    
    private let session: MXSession
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
    }
    
    // MARK: - Public
    
    func buildUser(from userId: String) -> User {
        let displayName = self.displayName(from: userId)
        return User(userId: userId, displayName: displayName, avatarStringURL: nil)
    }
    
    func findOrBuildUser(from userId: String, completion: @escaping ((User) -> Void)) {
        
        if let matrixUser = self.session.user(withUserId: userId) {
            let user = self.buildUser(from: matrixUser)
            completion(user)
        } else {

            let fallback = {
                let user = self.buildUser(from: userId)
                completion(user)
            }
        
            self.session.matrixRestClient.searchUsers(userId, limit: Constants.searchUsersLimit, success: { (userSearchResponse) in
                if let results = userSearchResponse?.results, let index = results.index(where: { $0.userId == userId }) {
                    let user = self.buildUser(from: results[index])
                    completion(user)
                } else {
                    fallback()
                }
            }, failure: { error in
                fallback()
            })
        }
    }
    
    // MARK: - Private
    
    private func buildUser(from mxUser: MXUser) -> User {
        
        let displayName: String
        let userId: String = mxUser.userId
        
        if let matrixUserDisplayName = mxUser.displayname, matrixUserDisplayName.isEmpty == false {
            displayName = matrixUserDisplayName
        } else {
            displayName = self.displayName(from: userId)
        }
        
        return User(userId: userId, displayName: displayName, avatarStringURL: mxUser.avatarUrl)
    }
    
    private func displayName(from userId: String) -> String {
        let displayName: String
        
        if let name = DisplayNameComponents(userId: userId)?.name {
            displayName = name
        } else {
            displayName = userId
        }
        
        return displayName
    }
}
