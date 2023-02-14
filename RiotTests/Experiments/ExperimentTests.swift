// 
// Copyright 2023 New Vector Ltd
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
import XCTest
@testable import Element

class ExperimentTests: XCTestCase {
    
    private func randomUserId() -> String {
        return "user_" + UUID().uuidString.prefix(6)
    }
    
    func test_singleVariant() {
        let experiment = Experiment(name: "single", variants: 1)
        for _ in 0 ..< 1000 {
            let variant = experiment.variant(userId: randomUserId())
            XCTAssertEqual(variant, 0)
        }
    }
    
    func test_twoVariants() {
        let experiment = Experiment(name: "two", variants: 2)
        
        var variants = Set<UInt>()
        for _ in 0 ..< 1000 {
            let variant = experiment.variant(userId: randomUserId())
            variants.insert(variant)
        }
        
        // We perform the test by collecting all assigned variants for 1000 users
        // and ensuring we only encounter variants 0 and 1
        XCTAssertEqual(variants.count, 2)
        XCTAssertTrue(variants.contains(0))
        XCTAssertTrue(variants.contains(1))
        XCTAssertFalse(variants.contains(2))
    }
    
    func test_manyVariants() {
        let experiment = Experiment(name: "many", variants: 5)
        
        var variants = Set<UInt>()
        for _ in 0 ..< 10000 {
            let variant = experiment.variant(userId: randomUserId())
            variants.insert(variant)
        }
        
        // We perform the test by collecting all assigned variants for 10000 users
        // and ensuring we only encounter variants between 0 and 4
        XCTAssertEqual(variants.count, 5)
        XCTAssertTrue(variants.contains(0))
        XCTAssertTrue(variants.contains(1))
        XCTAssertTrue(variants.contains(2))
        XCTAssertTrue(variants.contains(3))
        XCTAssertTrue(variants.contains(4))
        XCTAssertFalse(variants.contains(5))
    }
}
