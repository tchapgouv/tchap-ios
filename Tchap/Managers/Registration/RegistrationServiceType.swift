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

protocol RegistrationServiceType {     
    
    /// Initialize a registration session
    ///
    /// - Parameters:
    ///   - completion: A closure called when the operation complete. Provide the authentication session id when succeed.
    func setupRegistrationSession(completion: @escaping (MXResponse<String>) -> Void)
    
    /// Submit registration verification email and return third PID credentials for registration.
    ///
    /// - Parameters:
    ///   - email: The user email.
    ///   - sessionId: The registration session identifier
    ///   - completion: A closure called when the operation succeeds. Provide the three PID credentials.
    func submitRegistrationEmailVerification(to email: String, sessionId: String, completion: @escaping (MXResponse<ThreePIDCredentials>) -> Void)
        
    /// Register user on homeserver.
    ///
    /// - Parameters:
    ///   - threePIDCredentials: The user three PID credentials given by email verification.
    ///   - sessionId: The registration session identifier (a password may have been already associated to this session).
    ///   - password: The user password (may be null if a password has been already associated to the session).
    ///   - deviceDisplayName: The current device display name.
    ///   - completion: A closure called when the operation complete. Provide the authenticated user id when succeed.    
    func register(withEmailCredentials threePIDCredentials: ThreePIDCredentials, sessionId: String?, password: String?, deviceDisplayName: String, completion: @escaping (MXResponse<String>) -> Void)
    
    /// Cancel pending registration request.
    func cancelPendingRegistration()
}
