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

/// Protocol describing a store used by `AppVersionChecker` to persist data.
protocol AppVersionCheckerStoreType {
    
    /// Save last AppVersionCheckerResult remotely fetched with success.
    ///
    /// - Parameter appVersionCheckerResult: The result to save.
    func saveLastResult(_ appVersionCheckerResult: AppVersionCheckerResult)
    
    /// Get last AppVersionCheckerResult remotely fetched with success.
    ///
    /// - Returns: Last result remotely fetched with success or nil.
    func getLastResult() -> AppVersionCheckerResult?
    
    /// Save last ClientVersionInfo displayed to user as update.
    ///
    /// - Parameter versionInfo: The ClientVersionInfo to save.
    func saveLastDisplayedClientVersionInfo(_ versionInfo: ClientVersionInfo)
    
    /// Get last ClientVersionInfo displayed to user as update.
    ///
    /// - Returns: Last ClientVersionInfo displayed to user as update or nil.
    func getLastDisplayedClientVersionInfo() -> ClientVersionInfo?
    
    /// Save the date when the last ClientVersionInfo has been displayed to user.
    ///
    /// - Parameter date: the date.
    func saveLastDisplayedClientVersionDate(_ date: Date)
    
    /// Get the date when the last ClientVersionInfo has been displayed to user.
    ///
    /// - Returns: the date.
    func getLastDisplayedClientVersionDate() -> Date?
}
