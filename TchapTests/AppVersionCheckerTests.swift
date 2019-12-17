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

import XCTest

// FIXME: Import main app bridging header into unit tests briding header. Also import Jitsi framework.
@testable import Tchap

final class AppVersionCheckerTests: XCTestCase {
    
    // MARK: - Constants
    
    let defaultTimeout: TimeInterval = 1.5
    
    // MARK: - Properties
    
    // MARK: - Test Setup & Teardown
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testVersionUpToDate() {
    
        let expectation = self.expectation(description: "Test version")
        
        let clientConfigurationService = ClientConfigurationServiceFake()
        let appVersionCheckerStore = AppVersionCheckerStoreFake()
        
        let appVersionChecker = AppVersionChecker(clientConfigurationService: clientConfigurationService, appVersionCheckerStore: appVersionCheckerStore)
        
        let appVersion = AppVersion(bundleShortVersion: "1.0.19", bundleVersion: "1")
        
        appVersionChecker.checkAppVersion(appVersion) { (appVersionCheckerResult) in
            if case .upToDate = appVersionCheckerResult {
                expectation.fulfill()
            } else {
                XCTFail("Expect app version checker result: \(AppVersionCheckerResult.upToDate) not \(appVersionCheckerResult)")
            }
        }
        
        waitForExpectations(timeout: self.defaultTimeout, handler: nil)
    }
    
    func testVersionShouldUpdateInfo() {
        
        let expectation = self.expectation(description: "Test version")
        
        let clientConfigurationService = ClientConfigurationServiceFake()
        let appVersionCheckerStore = AppVersionCheckerStoreFake()
        
        let appVersionChecker = AppVersionChecker(clientConfigurationService: clientConfigurationService, appVersionCheckerStore: appVersionCheckerStore)
        
        let appVersion = AppVersion(bundleShortVersion: "1.0.18", bundleVersion: "1")
        
        appVersionChecker.checkAppVersion(appVersion) { (appVersionCheckerResult) in
            if case let .shouldUpdate(versionInfo: versionInfo) = appVersionCheckerResult {
                
                XCTAssertEqual(versionInfo.criticity, .info)
                XCTAssertEqual(versionInfo.minBundleShortVersion, "1.0.19")
                XCTAssertEqual(versionInfo.minBundleVersion, "1")
                XCTAssertTrue(versionInfo.allowOpeningApp)
                XCTAssertTrue(versionInfo.displayOnlyOnce)
                
                expectation.fulfill()
            } else {
                XCTFail("Expect app version checker result: \(AppVersionCheckerResult.upToDate) not \(appVersionCheckerResult)")
            }
        }
        
        waitForExpectations(timeout: self.defaultTimeout, handler: nil)
    }
    
    func testVersionShouldUpdateMandatory() {
        
        let expectation = self.expectation(description: "Test version")
        
        let clientConfigurationService = ClientConfigurationServiceFake()
        let appVersionCheckerStore = AppVersionCheckerStoreFake()
        
        let appVersionChecker = AppVersionChecker(clientConfigurationService: clientConfigurationService, appVersionCheckerStore: appVersionCheckerStore)
        
        let appVersion = AppVersion(bundleShortVersion: "1.0.16", bundleVersion: "1")
        
        appVersionChecker.checkAppVersion(appVersion) { (appVersionCheckerResult) in
            if case let .shouldUpdate(versionInfo: versionInfo) = appVersionCheckerResult {
                
                XCTAssertEqual(versionInfo.criticity, .mandatory)
                XCTAssertEqual(versionInfo.minBundleShortVersion, "1.0.18")
                XCTAssertEqual(versionInfo.minBundleVersion, "1")
                XCTAssertTrue(versionInfo.allowOpeningApp)
                XCTAssertFalse(versionInfo.displayOnlyOnce)
                
                expectation.fulfill()
            } else {
                XCTFail("Expect app version checker result: \(AppVersionCheckerResult.upToDate) not \(appVersionCheckerResult)")
            }
        }
        
        waitForExpectations(timeout: self.defaultTimeout, handler: nil)
    }
    
    func testVersionShouldUpdateCritical() {
        
        let expectation = self.expectation(description: "Test version")
        
        let clientConfigurationService = ClientConfigurationServiceFake()
        let appVersionCheckerStore = AppVersionCheckerStoreFake()
        
        let appVersionChecker = AppVersionChecker(clientConfigurationService: clientConfigurationService, appVersionCheckerStore: appVersionCheckerStore)
        
        let appVersion = AppVersion(bundleShortVersion: "1.0.10", bundleVersion: "1")
        
        appVersionChecker.checkAppVersion(appVersion) { (appVersionCheckerResult) in
            if case let .shouldUpdate(versionInfo: versionInfo) = appVersionCheckerResult {
                
                XCTAssertEqual(versionInfo.criticity, .critical)
                XCTAssertEqual(versionInfo.minBundleShortVersion, "1.0.11")
                XCTAssertEqual(versionInfo.minBundleVersion, "1")
                XCTAssertFalse(versionInfo.allowOpeningApp)
                XCTAssertFalse(versionInfo.displayOnlyOnce)
                
                expectation.fulfill()
            } else {
                XCTFail("Expect app version checker result: \(AppVersionCheckerResult.upToDate) not \(appVersionCheckerResult)")
            }
        }
        
        waitForExpectations(timeout: self.defaultTimeout, handler: nil)
    }
}
