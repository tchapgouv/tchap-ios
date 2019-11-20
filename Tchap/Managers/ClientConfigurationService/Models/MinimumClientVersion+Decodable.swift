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

extension MinimumClientVersion: Decodable {
    
    /// JSON keys associated to MinimumClientVersion properties.
    enum CodingKeys: String, CodingKey {
        case critical
        case mandatory
        case info
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let criticalVersion = try container.decode(ClientVersionInfo.self, forKey: .critical)
        let mandatoryVersion = try container.decode(ClientVersionInfo.self, forKey: .mandatory)
        let infoVersion = try container.decode(ClientVersionInfo.self, forKey: .info)
        
        self.init(criticalVersion: criticalVersion, mandatoryVersion: mandatoryVersion, infoVersion: infoVersion)
    }
}
