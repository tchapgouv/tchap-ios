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

extension ClientVersionInfo: Codable {
    
    /// JSON keys associated to ClientVersionInfo properties.
    enum CodingKeys: String, CodingKey {
        case criticity
        case minBundleShortVersion
        case minBundleVersion
        case messages = "message"
        case displayOnlyOnce
        case allowOpeningApp
    }    
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let criticityOptional: ClientVersionInfoCriticity?
        
        // Decode from WS
        if let criticityString = decoder.codingPath.last?.stringValue {
            criticityOptional = ClientVersionInfoCriticity(rawValue: criticityString)
        } else {
            // Decode from UserDefaults
            criticityOptional = try container.decodeIfPresent(ClientVersionInfoCriticity.self, forKey: .criticity)
        }
    
        guard let criticity = criticityOptional  else {
            throw DecodingError.dataCorruptedError(forKey: .criticity, in: container, debugDescription: "Cannot initialize criticty")
        }
        
        let minBundleShortVersion = try container.decode(String.self, forKey: .minBundleShortVersion)
        let minBundleVersion = try container.decode(String.self, forKey: .minBundleVersion)
        let messagesDict = try container.decodeIfPresent([String: String].self, forKey: .messages)
        
        var versionInfoMessages: [ClientVersionInfoMessage] = []
        
        if let messagesDict = messagesDict {
            for (key, value) in messagesDict {
                versionInfoMessages.append(ClientVersionInfoMessage(language: key, message: value))
            }
        }
        
        let displayOnlyOnce = try container.decodeIfPresent(Bool.self, forKey: .displayOnlyOnce)
        let allowOpeningApp = try container.decodeIfPresent(Bool.self, forKey: .allowOpeningApp)
        
        self.init(criticity: criticity,
                  minBundleShortVersion: minBundleShortVersion,
                  minBundleVersion: minBundleVersion,
                  messages: versionInfoMessages,
                  displayOnlyOnce: displayOnlyOnce ?? false,
                  allowOpeningApp: allowOpeningApp ?? false)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.criticity, forKey: .criticity)
        
        try container.encode(self.minBundleShortVersion, forKey: .minBundleShortVersion)
        try container.encode(self.minBundleVersion, forKey: .minBundleVersion)
        
        let initialMessagesDict: [String: String] = [:]
        
        let messagesDict = self.messages.reduce(into: initialMessagesDict) { (accumulatingMessagesDict, versionInfoMessage) in
            accumulatingMessagesDict[versionInfoMessage.language] = versionInfoMessage.message
        }
        
        try container.encode(messagesDict, forKey: .messages)
        try container.encode(self.displayOnlyOnce, forKey: .displayOnlyOnce)
        try container.encode(self.allowOpeningApp, forKey: .allowOpeningApp)
    }
}
