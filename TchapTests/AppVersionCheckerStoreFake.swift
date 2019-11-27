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

// FIXME: Import main app bridging header into unit tests briding header. Also import Jitsi framework.
@testable import Tchap

final class AppVersionCheckerStoreFake: AppVersionCheckerStoreType {
    
    func saveLastResult(_ appVersionCheckerResult: AppVersionCheckerResult) {
    }
    
    func getLastResult() -> AppVersionCheckerResult? {
        return nil
    }
    
    func saveLastDisplayedClientVersionInfo(_ versionInfo: ClientVersionInfo) {
    }
    
    func getLastDisplayedClientVersionInfo() -> ClientVersionInfo? {
        return nil
    }
    
    func saveLastDisplayedClientVersionDate(_ date: Date) {
    }
    
    func getLastDisplayedClientVersionDate() -> Date? {
        return nil;
    }
}
