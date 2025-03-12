//
//  RunnerUITests.swift
//  RunnerUITests
//
//  Created by Soupy Campbell on 3/11/25.
//

import XCTest

final class RunnerUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
        
        let app = XCUIApplication()
        
        // Configure the app to know it's in screenshot mode
        app.launchArguments += [
            "-SCREENSHOT_MODE"                  // Add a special launch argument that your Flutter app can detect
        ]
        
        app.launch()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called before the invocation of each test method in the class.
    }

    @MainActor
    func testScreenshots() throws {
        let app = XCUIApplication()
        
        // Wait for Flutter to stabilize
        sleep(10)
        
        // Take screenshot directly
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "01_HomeScreen.png"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // You can add more screenshots by navigating through your app
        // and taking more screenshots
    }
}
