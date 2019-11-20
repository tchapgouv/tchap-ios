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

private enum AppVersionCheckerFetchResult {
    case cache(result: AppVersionCheckerResult?)
    case remote(result: AppVersionCheckerResult)
    case error(_ error: Error)
}

final class AppVersionChecker: AppVersionCheckerType {
    
    // MARK: - Constants
    
    private enum Constants {
        static let lastAppVersionCheckDateUserDefaultsKey = "AppVersionChecker_LastCurrentAppVersionCheckDate"
        static let appVersionRemoteFetchMinDelay: TimeInterval = 86_400_000
    }
    
    // MARK: - Properties
    
    private let clientConfigurationService: ClientConfigurationServiceType
    private let currentAppVersion = AppVersion.current
    private let appVersionCheckerStore: AppVersionCheckerStoreType
    
    private var lastAppVersionCheckDate: Date? {
        get {
            return UserDefaults.standard.object(forKey: Constants.lastAppVersionCheckDateUserDefaultsKey) as? Date
        } set {
            UserDefaults.standard.set(newValue, forKey: Constants.lastAppVersionCheckDateUserDefaultsKey)
        }
    }
    
    private var shouldFetchClientConfiguration: Bool {
        guard let lastVersionCheckDate = self.lastAppVersionCheckDate, self.appVersionCheckerStore.getLastResult() != nil else {
            return true
        }
        return -lastVersionCheckDate.timeIntervalSinceNow > Constants.appVersionRemoteFetchMinDelay
    }
    
    // MARK: - Setup
    
    init(clientConfigurationService: ClientConfigurationServiceType, appVersionCheckerStore: AppVersionCheckerStoreType) {
        self.clientConfigurationService = clientConfigurationService
        self.appVersionCheckerStore = appVersionCheckerStore
    }
    
    // MARK: - Public
    
    func checkCurrentAppVersion(completion: @escaping (AppVersionCheckerResult) -> Void) -> MXHTTPOperation? {
        guard let currentAppVersion = self.currentAppVersion else {
            completion(AppVersionCheckerResult.unknown)
            return nil
        }
        
        return self.internalCheckVersion(currentAppVersion) { (fetchResult) in
            switch fetchResult {
            case .remote(result: let versionResult):
                self.lastAppVersionCheckDate = Date()
                self.appVersionCheckerStore.saveLastResult(versionResult)
                completion(versionResult)
            case .cache(result: let versionResult):
                completion(versionResult ?? .unknown)
            case .error:
                let versionResult = self.appVersionCheckerStore.getLastResult()
                completion(versionResult ?? .unknown)
            }
        }
    }
    
    func checkAppVersion(_ appVersion: AppVersion, completion: @escaping (AppVersionCheckerResult) -> Void) -> MXHTTPOperation? {
        return self.internalCheckVersion(appVersion) { (fetchResult) in
            switch fetchResult {
            case .remote(result: let versionResult):
                completion(versionResult)
            case .cache(result: let versionResult):
                completion(versionResult ?? .unknown)
            case .error:
                let versionResult = self.appVersionCheckerStore.getLastResult()
                completion(versionResult ?? .unknown)
            }
        }
    }
    
    func isClientVersionInfoAlreadyDisplayed(_ versionInfo: ClientVersionInfo) -> Bool {
        guard let lastDisplayedUpdateVersionInfo = self.appVersionCheckerStore.getLastDisplayedClientVersionInfo() else {
            return false
        }
        let appVersion = self.appVersion(from: versionInfo)
        let lastDisplayedAppVersionUpdate = self.appVersion(from: lastDisplayedUpdateVersionInfo)
        return appVersion.compare(lastDisplayedAppVersionUpdate) == .orderedSame
    }
    
    // MARK: - Private
    
    private func internalCheckVersion(_ appVersion: AppVersion, completion: @escaping (AppVersionCheckerFetchResult) -> Void) -> MXHTTPOperation? {
        let httpOperation: MXHTTPOperation?
        
        if self.shouldFetchClientConfiguration {
            httpOperation = self.clientConfigurationService.getClientConfiguration { (clientConfigurationResult) in
                switch clientConfigurationResult {
                case .success(let clientConfiguration):
                    let versionResult = self.checkAppVersion(appVersion, with: clientConfiguration.minimumClientVersion)
                    let fetchResult = AppVersionCheckerFetchResult.remote(result: versionResult)
                    completion(fetchResult)
                case .failure(let error):
                    print("[AppVersionChecker] Fail to get client configuration with error: \(error)")
                    let fetchResult = AppVersionCheckerFetchResult.error(error)
                    completion(fetchResult)
                }
            }
        } else {
            httpOperation = nil
            let fetchResult = AppVersionCheckerFetchResult.cache(result: self.appVersionCheckerStore.getLastResult())
            completion(fetchResult)
        }
        
        return httpOperation
    }
    
    private func getLastAppVersionCheckerResultCached() -> AppVersionCheckerResult {
        return self.appVersionCheckerStore.getLastResult() ?? AppVersionCheckerResult.unknown
    }
    
    private func checkAppVersion(_ appVersion: AppVersion, with minimumClientVersion: MinimumClientVersion) -> AppVersionCheckerResult {
        
        let appVersionCheckerResult: AppVersionCheckerResult
        
        let criticalAppVersion = self.appVersion(from: minimumClientVersion.criticalVersion)
        let mandatoryAppVersion = self.appVersion(from: minimumClientVersion.mandatoryVersion)
        let infoAppVersion = self.appVersion(from: minimumClientVersion.infoVersion)
        
        if appVersion.compare(criticalAppVersion) == .orderedAscending {
            appVersionCheckerResult = .shouldUpdate(versionInfo: minimumClientVersion.criticalVersion)
        } else if appVersion.compare(mandatoryAppVersion) == .orderedAscending {
            appVersionCheckerResult = .shouldUpdate(versionInfo: minimumClientVersion.mandatoryVersion)
        } else if appVersion.compare(infoAppVersion) == .orderedAscending {
            appVersionCheckerResult = .shouldUpdate(versionInfo: minimumClientVersion.infoVersion)
        } else {
            appVersionCheckerResult = .upToDate
        }
        
        return appVersionCheckerResult
    }
    
    private func appVersion(from versionInfo: ClientVersionInfo) -> AppVersion {
        return AppVersion(bundleShortVersion: versionInfo.minBundleShortVersion, bundleVersion: versionInfo.minBundleVersion)
    }
}
