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

/// `ChangePasswordService` implementation of `ChangePasswordServiceType`
final class ChangePasswordService: ChangePasswordServiceType {
    
    // MARK: - Properties
    
    private let session: MXSession
    private var currentOperation: MXHTTPOperation?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
    }
    
    deinit {
        self.currentOperation?.cancel()
    }
    
    // MARK: - Public
    
    func changePassword(from oldPassword: String, to newPassword: String, completion: @escaping (MXResponse<Void>) -> Void) -> MXHTTPOperation {
        self.cancelPendingChangePassword()
        return self.session.matrixRestClient.changePassword(from: oldPassword, to: newPassword, completion: completion)
    }
    
    // MARK: - Private
    
    private func cancelPendingChangePassword() {
        self.currentOperation?.cancel()
    }
}
