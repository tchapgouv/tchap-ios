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
    
    func getUserFromLocalSession(with userId: String) -> User? {
        let user: User?
        
        if let matrixUser = self.session.user(withUserId: userId) {
            user = self.buildUser(from: matrixUser)
        } else {
            user = nil
        }
        
        return user
    }
    
    func findUser(with userId: String, completion: @escaping ((User?) -> Void)) {
        
        if let matrixUser = self.session.user(withUserId: userId) {
            let user = self.getUserFromLocalSession(with: matrixUser.userId)
            completion(user)
        } else {
            self.session.matrixRestClient.searchUsers(userId, limit: Constants.searchUsersLimit, success: { (userSearchResponse) in
                if let results = userSearchResponse?.results, let index = results.index(where: { $0.userId == userId }) {
                    let user = self.buildUser(from: results[index])
                    completion(user)
                } else {
                    completion(nil)
                }
            }, failure: { error in
                completion(nil)
            })
        }
    }
    
    func buildTemporaryUser(from userId: String) -> User {
        let displayName = self.displayName(from: userId)
        return User(userId: userId, displayName: displayName, avatarStringURL: nil)
    }
    
    // MARK: - Private
    
    func buildUser(from userId: String) -> User {
        let displayName = self.displayName(from: userId)
        return User(userId: userId, displayName: displayName, avatarStringURL: nil)
    }
    
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
            // This case happen only if given user id is not a valid Matrix id
            displayName = ""
        }
        
        return displayName
    }
}
