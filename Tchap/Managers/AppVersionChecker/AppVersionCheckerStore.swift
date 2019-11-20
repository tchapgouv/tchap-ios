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

final class AppVersionCheckerStore: AppVersionCheckerStoreType {
    
    // MARK: - Constants
    
    private enum UserDefaultsKeys {
        static let lastAppVersionCheckerResult = "AppVersionCheckerStore_LastAppVersionCheckerResult"
        static let lastDisplayedClientVersionInfo = "AppVersionCheckerStore_LastDisplayedClientVersionInfo"
    }
    
    // MARK: - Public
    
    func saveLastResult(_ appVersionCheckerResult: AppVersionCheckerResult) {
        do {
            let appVersionCheckerResultData = try JSONEncoder().encode(appVersionCheckerResult)
            UserDefaults.standard.set(appVersionCheckerResultData, forKey: UserDefaultsKeys.lastAppVersionCheckerResult)
        } catch {
            print("[AppVersionCheckerStore] Fail to save \(appVersionCheckerResult) with error: \(error)")
        }
    }
    
    func getLastResult() -> AppVersionCheckerResult? {
        guard let appVersionCheckerResultData = UserDefaults.standard.data(forKey: UserDefaultsKeys.lastAppVersionCheckerResult) else {
            return nil
        }
        return try? JSONDecoder().decode(AppVersionCheckerResult.self, from: appVersionCheckerResultData)
    }
    
    func saveLastDisplayedClientVersionInfo(_ versionInfo: ClientVersionInfo) {
        do {
            let appVersionInfoData = try JSONEncoder().encode(versionInfo)
            UserDefaults.standard.set(appVersionInfoData, forKey: UserDefaultsKeys.lastDisplayedClientVersionInfo)
        } catch {
            print("[AppVersionCheckerStore] Fail to save \(versionInfo) with error: \(error)")
        }
    }
    
    func getLastDisplayedClientVersionInfo() -> ClientVersionInfo? {
        guard let appVersionInfoData = UserDefaults.standard.data(forKey: UserDefaultsKeys.lastDisplayedClientVersionInfo) else {
            return nil
        }
        return try? JSONDecoder().decode(ClientVersionInfo.self, from: appVersionInfoData)
    }
}
