//
//  RunnerUITests.swift
//  RunnerUITests
//
//  Created by Soupy Campbell on 3/11/25.
//

import XCTest
@testable import SnapshotHelper

final class RunnerUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testScreenshots() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        
        // Take a screenshot of the main screen
        snapshot("01_MainScreen")

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
}
