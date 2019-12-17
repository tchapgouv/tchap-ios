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

enum AppVersionCheckerResultDecodingError: Error {
    case dataCorrupted
}

extension AppVersionCheckerResult: Codable {
    
    /// Serialization keys associated to AppVersionCheckerResult properties.
    enum CodingKeys: CodingKey {
        case upToDate
        case shouldUpdate
        case unknown
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .upToDate:
            try container.encode(true, forKey: .upToDate)
        case .shouldUpdate(versionInfo: let versionInfo):
            try container.encode(versionInfo, forKey: .shouldUpdate)
        case .unknown:
            try container.encode(true, forKey: .unknown)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let value = try? container.decode(Bool.self, forKey: .upToDate), value == true {
            self = .upToDate
            return
        } else if let versionInfo = try? container.decode(ClientVersionInfo.self, forKey: .shouldUpdate) {
            self = .shouldUpdate(versionInfo: versionInfo)
            return
        } else if let value = try? container.decode(Bool.self, forKey: .unknown), value == true {
            self = .unknown
            return
        } else {
            throw AppVersionCheckerResultDecodingError.dataCorrupted
        }
    }
}
