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

final class AppVersionUpdateViewModel: AppVersionUpdateViewModelType {
    
    // MARK: - Constants
    
    private enum Constants {
        static let tchapBundleIdentifier = "fr.gouv.tchap"
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let versionInfo: ClientVersionInfo
    
    // MARK: Public
    
    lazy var message: String = {
       return self.applicationUpdateMessage(from: self.versionInfo)
    }()

    lazy var showOpenAppStoreAction: Bool = {
        return self.canShowAppStoreButton()
    }()

    var showCancelAction: Bool {
        return self.versionInfo.allowOpeningApp
    }
    
    var displayOnce: Bool {
        return self.versionInfo.displayOnlyOnce
    }
    
    // MARK: - Setup
    
    init(versionInfo: ClientVersionInfo) {
        self.versionInfo = versionInfo
    }
    
    // MARK: - Private
    
    private func applicationUpdateMessage(from versionInfo: ClientVersionInfo) -> String {
        
        let updateMessage: String
        
        // Force to "fr" language for the moment use `Locale.current.languageCode` when app will be translated.
        let currentAppLanguage = TchapDefaults.appLanguage
        
        let currentLanguageMessage = versionInfo.messages.first { (versionInfoMessage) -> Bool in
            versionInfoMessage.language == currentAppLanguage
        }
        
        let defaultLanguageMessage = versionInfo.messages.first { (versionInfoMessage) -> Bool in
            versionInfoMessage.language == ClientVersionInfoMessage.defaultLanguageValue
        }
        
        if let currentLanguageMessage = currentLanguageMessage?.message {
            updateMessage = currentLanguageMessage
        } else if let defaultLanguageMessage = defaultLanguageMessage?.message {
            updateMessage = defaultLanguageMessage
        } else {
            switch versionInfo.criticity {
            case .critical:
                updateMessage = TchapL10n.appVersionUpdateCriticalUpdateMessageFallback
            case .mandatory:
                updateMessage = TchapL10n.appVersionUpdateMandatoryUpdateMessageFallback
            case .info:
                updateMessage = TchapL10n.appVersionUpdateInfoUpdateMessageFallback
            }
        }
        
        return updateMessage
    }
    
    private func canShowAppStoreButton() -> Bool {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return false
        }
        return bundleIdentifier == Constants.tchapBundleIdentifier
    }
}
