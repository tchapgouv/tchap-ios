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

import XCTest

// FIXME: Import main app bridging header into unit tests briding header. Also import Jitsi framework.
@testable import Tchap

class DisplayNameTests: XCTestCase {
    
    // MARK: - Tests
    
    // MARK: Display name components from user id
    
    func testComputeDisplayNameFromUserIdSimple() {
        let displayNameComponents = DisplayNameComponents(userId: "@jean.martin-modernisation.fr:matrix.org", isExternal: false)
        
        XCTAssertNotNil(displayNameComponents)
        XCTAssertEqual(displayNameComponents?.name, "Jean Martin")
        XCTAssertNil(displayNameComponents?.domain)
    }
    
    func testComputeDisplayNameFromUserIdWithDashInName() {
        
        let displayNameComponents = DisplayNameComponents(userId: "@jean-philippe.martin-modernisation.fr:matrix.org", isExternal: false)
        
        XCTAssertNotNil(displayNameComponents)
        XCTAssertEqual(displayNameComponents?.name, "Jean-Philippe Martin")
        XCTAssertNil(displayNameComponents?.domain)
    }
    
 
    func testComputeDisplayNameFromUserIdWithDashesInName() {
        let displayNameComponents = DisplayNameComponents(userId: "@jean.martin.de-la-rampe-modernisation.gouv.fr:a.tchap.gouv.fr", isExternal: false)
        
        XCTAssertNotNil(displayNameComponents)
        XCTAssertEqual(displayNameComponents?.name, "Jean Martin De-La-Rampe")
        XCTAssertNil(displayNameComponents?.domain)
    }

    func testComputeDisplayNameFromUserIdWithDashesInDomain() {
        
        let displayNameComponents = DisplayNameComponents(userId: "@jean.martin-dev-durable.gouv.fr:a.tchap.gouv.fr", isExternal: false)
        
        XCTAssertNotNil(displayNameComponents)
        XCTAssertEqual(displayNameComponents?.name, "Jean Martin-Dev")
        XCTAssertNil(displayNameComponents?.domain)
    }
    
    // MARK: Display name components from display name
    
    func testComputeDisplayNameComponentsFromDisplayNameWithoutDomain() {
        
        let displayNameComponents = DisplayNameComponents(displayName: "Jean Martin")
        
        XCTAssertEqual(displayNameComponents.name, "Jean Martin")
        XCTAssertNil(displayNameComponents.domain)
    }
    
    func testComputeDisplayNameComponentsFromDisplayNameWithDomain() {
        
        let displayNameComponents = DisplayNameComponents(displayName: "Jean-Martin [Modernisation]")
        
        XCTAssertEqual(displayNameComponents.name, "Jean-Martin")
        XCTAssertEqual(displayNameComponents.domain, "Modernisation")
    }
}
