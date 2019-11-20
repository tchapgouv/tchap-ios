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

/// Protocol describing an application version checker that verify if an update is required or not.
protocol AppVersionCheckerType {
    
    /// Check current application version status.
    ///
    /// - Parameter completion: A closure called when the operation complete. Provide an AppVersionCheckerResult when succeed.
    /// - Returns: A `MXHTTPOperation` instance or nil.
    @discardableResult
    func checkCurrentAppVersion(completion: @escaping (AppVersionCheckerResult) -> Void) -> MXHTTPOperation?
    
    /// Check an application version status.
    ///
    /// - Parameters:
    ///   - appVersion: An application version.
    ///   - completion: A closure called when the operation complete. Provide an AppVersionCheckerResult when succeed.
    /// - Returns: A `MXHTTPOperation` instance or nil.
    @discardableResult
    func checkAppVersion(_ appVersion: AppVersion, completion: @escaping (AppVersionCheckerResult) -> Void) -> MXHTTPOperation?
    
    /// Check if an update information has already been displayed to user.
    ///
    /// - Parameter versionInfo: The ClientInfoVersion to check.
    /// - Returns: true if the ClientInfoVersion has already been displayed.
    func isClientVersionInfoAlreadyDisplayed(_ versionInfo: ClientVersionInfo) -> Bool
}
