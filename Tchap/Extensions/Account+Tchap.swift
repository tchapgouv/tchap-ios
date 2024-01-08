// 
// Copyright 2024 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

@objc extension MXKAccount {
    
    func isFeatureActivated(_ featureId: String) -> Bool {
        guard let targetedFeature = BuildSettings.tchapFeatureByHomeServer[featureId] ?? BuildSettings.tchapFeatureByHomeServer[BuildSettings.tchapFeatureAnyFeature] else {
            return false
        }
        
        if targetedFeature.contains(BuildSettings.tchapFeatureAnyHomeServer) {
            return true
        }
        
        guard let homeServerURL = self.mxCredentials.homeServer else {
            return false
        }
        
        let homeServerDomain = homeServerURL.replacingOccurrences(of: BuildSettings.serverUrlPrefix, with: "")
        
        return targetedFeature.contains(homeServerDomain)
    }
}
