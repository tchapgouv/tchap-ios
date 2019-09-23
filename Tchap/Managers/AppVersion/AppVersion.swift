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

/// A structure used to handle the application version
struct AppVersion {
    
    // MARK: - Constants
    
    private enum Constants {
        static let lastBundleShortVersion: String = "lastBundleShortVersion"
        static let lastBundleVersion: String = "lastBundleVersion"
        static let shortVersionComponentsSeparator: Character = "."
    }
    
    // MARK: - Properties
    
    let bundleShortVersion: String
    let bundleVersion: String
    
    // MARK: - Setup
    
    // MARK: - Public
    
    /// Return true if the last stored version is lower than the provided one.
    /// Retrun true by default when there is no stored version.
    static func isLastVersionLowerThan(_ appVersion: AppVersion) -> Bool {
        guard let lastAppVersion = lastAppVersion() else {
            return true
        }
        
        let isLower: Bool
        let lastVersion = convertToInt(lastAppVersion.bundleShortVersion)
        let version = convertToInt(appVersion.bundleShortVersion)
        if  lastVersion < version {
            isLower = true
        } else if lastVersion == version {
            isLower = Int(lastAppVersion.bundleVersion) ?? 0 < Int(appVersion.bundleVersion) ?? 0
        } else {
            isLower = false
        }
        
        return isLower
    }
    
    /// Store the current application version.
    static func updateLastVersion() {
        guard let bundleShortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString"),
            let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") else {
                return
        }
        
        UserDefaults.standard.set(bundleShortVersion, forKey: Constants.lastBundleShortVersion)
        UserDefaults.standard.set(bundleVersion, forKey: Constants.lastBundleVersion)
    }
    
    // MARK: - Private
    
    private static func lastAppVersion() -> AppVersion? {
        guard let bundleShortVersion = UserDefaults.standard.string(forKey: Constants.lastBundleShortVersion),
            let bundleVersion = UserDefaults.standard.string(forKey: Constants.lastBundleVersion) else {
                return nil
        }
        
        return AppVersion(bundleShortVersion: bundleShortVersion, bundleVersion: bundleVersion)
    }
    
    private static func convertToInt(_ version: String) -> Int {
        var versionInt: Int = 0
        var components = version.split(separator: Constants.shortVersionComponentsSeparator)
        components.reverse()
        let count = components.count
        var factor = 1
        for i in 0..<count {
            versionInt = versionInt + (Int(String(components[i])) ?? 0) * factor
            factor *= 1000
        }
        return versionInt
    }
}
