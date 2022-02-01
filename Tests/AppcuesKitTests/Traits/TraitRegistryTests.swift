//
//  TraitRegistryTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-02-01.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class TraitRegistryTests: XCTestCase {

    var appcues: MockAppcues!
    var traitRegistry: TraitRegistry!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        traitRegistry = TraitRegistry(container: appcues.container)
    }

    func testRegister() throws {
        // Arrange
        let traitModel = Experience.Trait(type: TestTrait.type, config: nil)

        // Act
        traitRegistry.register(trait: TestTrait.self)

        // Assert
        let traitInstances = traitRegistry.instances(for: [traitModel])
        XCTAssertEqual(traitInstances.count, 1)
    }

    func testUnknownTrait() throws {
        // Arrange
        let traitModel = Experience.Trait(type: "@unknown/trait", config: nil)

        // Act
        traitRegistry.register(trait: TestTrait.self)

        // Assert
        let traitInstances = traitRegistry.instances(for: [traitModel])
        XCTAssertEqual(traitInstances.count, 0)
    }

    func testDuplicateTypeRegistrations() throws {
        // Arrange
        let traitModel = Experience.Trait(type: TestTrait.type, config: nil)

        // Act
        traitRegistry.register(trait: TestTrait.self)
        // This will trigger an assertionFailure if we're not in a test cycle
        traitRegistry.register(trait: TestTrait.self)

        // Assert
        let traitInstances = traitRegistry.instances(for: [traitModel])
        XCTAssertEqual(traitInstances.count, 1)
    }
}

private extension TraitRegistryTests {
    struct TestTrait: ExperienceTrait {
        static let type = "@test/trait"

        var groupID: String?

        init?(config: [String: Any]?) {}
    }
}
