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

final class ClientConfigurationServiceTests: XCTestCase {
    
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
    
    func testGetClientConfiguration() {
        
        let expectation = self.expectation(description: "Get client configuration")
        
        let configurationService = ClientConfigurationServiceFake()
        
        configurationService.getClientConfiguration { (result) in
            switch result {
            case .success(let clientConfiguration):
                
                // Critical version
                
                let criticalVersion = clientConfiguration.minimumClientVersion.critical
                
                XCTAssertEqual(criticalVersion.criticity, .critical)
                XCTAssertEqual(criticalVersion.minBundleShortVersion, "1.0.11")
                XCTAssertEqual(criticalVersion.minBundleVersion, "1")
                XCTAssertEqual(criticalVersion.displayOnlyOnce, false)
                XCTAssertEqual(criticalVersion.allowOpeningApp, false)
                
                let criticalMessages = criticalVersion.messages
                
                let isCriticalDefaultMessageValid = criticalMessages.contains { (versionInfoMessage) -> Bool in
                    return versionInfoMessage.language == ClientVersionInfoMessage.defaultLanguageValue && versionInfoMessage.message == "A new version is available, for security reason, you've been disconnected, please update your application first"
                }
                
                let isCriticalFRMessageValid = criticalMessages.contains { (versionInfoMessage) -> Bool in
                    return versionInfoMessage.language == "fr" && versionInfoMessage.message == "Une nouvelle version est disponible, pour des raisons de sécurité, vous avez été déconnecté du service. Veuillez mettre à jour votre application"
                    
                }
                
                XCTAssertEqual(criticalMessages.count, 2)
                XCTAssertTrue(isCriticalDefaultMessageValid)
                XCTAssertTrue(isCriticalFRMessageValid)
                
                // Mandatory version
                
                let mandatoryVersion = clientConfiguration.minimumClientVersion.mandatory
                
                XCTAssertEqual(mandatoryVersion.criticity, .mandatory)
                XCTAssertEqual(mandatoryVersion.minBundleShortVersion, "1.0.18")
                XCTAssertEqual(mandatoryVersion.minBundleVersion, "1")
                XCTAssertEqual(mandatoryVersion.displayOnlyOnce, false)
                XCTAssertEqual(mandatoryVersion.allowOpeningApp, true)
                
                let mandatoryMessages = mandatoryVersion.messages
                
                let isMandatoryDefaultMessageValid = mandatoryMessages.contains { (versionInfoMessage) -> Bool in
                    return versionInfoMessage.language == "default" && versionInfoMessage.message == "A new version is available, please update your application"
                }
                
                let isMandatoryFRMessageValid = mandatoryMessages.contains { (versionInfoMessage) -> Bool in
                    return versionInfoMessage.language == "fr" && versionInfoMessage.message == "Une nouvelle version est disponible, veuillez mettre à jour votre application"
                }
                
                XCTAssertEqual(mandatoryMessages.count, 2)
                XCTAssertTrue(isMandatoryDefaultMessageValid)
                XCTAssertTrue(isMandatoryFRMessageValid)
                
                // Minimum version
                
                let infoVersion = clientConfiguration.minimumClientVersion.info
                
                XCTAssertEqual(infoVersion.criticity, .info)
                XCTAssertEqual(infoVersion.minBundleShortVersion, "1.0.19")
                XCTAssertEqual(infoVersion.minBundleVersion, "1")
                XCTAssertEqual(infoVersion.displayOnlyOnce, true)
                XCTAssertEqual(infoVersion.allowOpeningApp, true)
                
                let infoMessages = infoVersion.messages
                
                let isInfoDefaultMessageValid = infoMessages.contains { (versionInfoMessage) -> Bool in
                    return versionInfoMessage.language == "default" && versionInfoMessage.message == "A new version is available!"
                }
                
                let isInfoFRMessageValid = infoMessages.contains { (versionInfoMessage) -> Bool in
                    return versionInfoMessage.language == "fr" && versionInfoMessage.message == "Une nouvelle version est disponible!"
                }
                
                XCTAssertEqual(infoMessages.count, 2)
                XCTAssertTrue(isInfoDefaultMessageValid)
                XCTAssertTrue(isInfoFRMessageValid)
                
                expectation.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        
        waitForExpectations(timeout: self.defaultTimeout, handler: nil)
    }
}
