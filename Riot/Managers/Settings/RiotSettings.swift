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

/// Store Riot specific app settings.
@objcMembers
final class RiotSettings: NSObject {
    
    // MARK: - Constants
    
    private enum UserDefaultsKeys {
        static let enableCrashReport = "enableCrashReport"
        static let enableRageShake = "enableRageShake"
        static let createConferenceCallsWithJitsi = "createConferenceCallsWithJitsi"
        static let userInterfaceTheme = "userInterfaceTheme"
        static let notificationsShowDecryptedContent = "showDecryptedContent"
        static let showJoinLeaveEvents = "showJoinLeaveEvents"
        static let showProfileUpdateEvents = "showProfileUpdateEvents"
        static let allowStunServerFallback = "allowStunServerFallback"
        static let stunServerFallback = "stunServerFallback"
        static let hideVerifyThisSessionAlert = "hideVerifyThisSessionAlert"
        static let hideReviewSessionsAlert = "hideReviewSessionsAlert"
    }
    
    static let shared = RiotSettings()
    
    /// UserDefaults to be used on reads and writes.
    private lazy var defaults: UserDefaults = {
        return UserDefaults(suiteName: TchapDefaults.appGroupId)!
    }()
    
    // MARK: - Public
    
    // MARK: Notifications
    
    /// Indicate if `showDecryptedContentInNotifications` settings has been set once.
    var isShowDecryptedContentInNotificationsHasBeenSetOnce: Bool {
        return defaults.object(forKey: UserDefaultsKeys.notificationsShowDecryptedContent) != nil
    }
    
    /// Indicate if UserDefaults suite has been migrated once.
    var isUserDefaultsMigrated: Bool {
        return defaults.object(forKey: UserDefaultsKeys.notificationsShowDecryptedContent) != nil
    }
    
    func migrate() {
        //  read all values from standard
        let dictionary = UserDefaults.standard.dictionaryRepresentation()
        
        //  write values to suite
        //  remove redundant values from standard
        for (key, value) in dictionary {
            defaults.set(value, forKey: key)
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    /// Indicate if encrypted messages content should be displayed in notifications.
    var showDecryptedContentInNotifications: Bool {
        get {
            return defaults.bool(forKey: UserDefaultsKeys.notificationsShowDecryptedContent)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.notificationsShowDecryptedContent)
        }
    }
    
    /// Indicate if the user wants to display the join and leave events in the room history.
    /// (No by default)
    var showJoinLeaveEvents: Bool {
        get {
            return defaults.bool(forKey: UserDefaultsKeys.showJoinLeaveEvents)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.showJoinLeaveEvents)
        }
    }
    
    /// Indicate if the user wants to display the profile update events (avatar / displayname) in the room history.
    /// (No by default)
    var showProfileUpdateEvents: Bool {
        get {
            return defaults.bool(forKey: UserDefaultsKeys.showProfileUpdateEvents)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.showProfileUpdateEvents)
        }
    }
    
    // MARK: User interface
    
    var userInterfaceTheme: String? {
        get {
            return defaults.string(forKey: UserDefaultsKeys.userInterfaceTheme)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.userInterfaceTheme)
        }
    }
    
    // MARK: Other
    
    /// Indicate if `enableCrashReport` settings has been set once.
    var isEnableCrashReportHasBeenSetOnce: Bool {
        return defaults.object(forKey: UserDefaultsKeys.enableCrashReport) != nil
    }
    
    var enableCrashReport: Bool {
        get {
            return defaults.bool(forKey: UserDefaultsKeys.enableCrashReport)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.enableCrashReport)
        }
    }
    
    var enableRageShake: Bool {
        get {
            return defaults.bool(forKey: UserDefaultsKeys.enableRageShake)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.enableRageShake)
        }
    }
    
    // MARK: Labs
    
    var createConferenceCallsWithJitsi: Bool {
        get {
            return defaults.bool(forKey: UserDefaultsKeys.createConferenceCallsWithJitsi)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.createConferenceCallsWithJitsi)
        }
    }

    // MARK: Calls

    /// Indicate if `allowStunServerFallback` settings has been set once.
    var isAllowStunServerFallbackHasBeenSetOnce: Bool {
        return defaults.object(forKey: UserDefaultsKeys.allowStunServerFallback) != nil
    }

    var allowStunServerFallback: Bool {
        get {
            return defaults.bool(forKey: UserDefaultsKeys.allowStunServerFallback)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.allowStunServerFallback)
        }
    }

    var stunServerFallback: String? {
        return defaults.string(forKey: UserDefaultsKeys.stunServerFallback)
    }
    
    // MARK: Key verification
    
    var hideVerifyThisSessionAlert: Bool {
        get {
            return defaults.bool(forKey: UserDefaultsKeys.hideVerifyThisSessionAlert)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.hideVerifyThisSessionAlert)
        }
    }
    
    var hideReviewSessionsAlert: Bool {
        get {
            return defaults.bool(forKey: UserDefaultsKeys.hideReviewSessionsAlert)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.hideReviewSessionsAlert)
        }
    }
}
