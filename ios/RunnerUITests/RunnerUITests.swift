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
            "--dart-define=SCREENSHOT_MODE=true"
        ]
        
        // Set specific orientation to ensure proper screenshot dimensions
        XCUIDevice.shared.orientation = .portrait
        
        app.launch()
        
        // Give time for status bar override to take effect
        sleep(1)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called before the invocation of each test method in the class.
    }

    @MainActor
    func testScreenshots() throws {
        let app = XCUIApplication()
        let window = app.windows.firstMatch
        
        // Wait for Flutter to stabilize
        sleep(20)
        
        // Home screen
        saveScreenshot(name: "01_HomeScreen")
        
        // Go to log list (bottom nav second tab)
        let bottomTabTwo = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
        bottomTabTwo.tap()
        sleep(15)
        saveScreenshot(name: "02_LogListScreen")
        
//        // Tap on first log entry to edit (adjust coordinates based on your testing)
//        let logItem = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
//        logItem.tap()
//        sleep(3)
//        saveScreenshot(name: "03_LogEditScreen")
//        
//        // Go back to list
//        let backButton = window.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.05))
//        backButton.tap()
//        sleep(2)
//        
//        // Go to charts tab (assuming third tab)
//        let chartsTab = window.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.95))
//        chartsTab.tap()
//        sleep(3)
//        saveScreenshot(name: "04_ChartsScreen") 
    }
    
    @MainActor
    func testFindCoordinates() throws {
        let app = XCUIApplication()
        
        // Keep the test running for 600 seconds to allow manual interaction
        // During this time, tap on UI elements to see their coordinates
        sleep(600)
    }
    
    // Helper function to save screenshots to both test results and file system
    private func saveScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        
        // Add to test results
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name + ".png"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // Get device name for device-specific folder
        let deviceName = UIDevice.current.name.replacingOccurrences(of: "Clone 1 of ", with: "").replacingOccurrences(of: " ", with: "_")
        
        // Also save to the project directory
        let pngData = screenshot.pngRepresentation
        let fileManager = FileManager.default
        let baseDir = URL(fileURLWithPath: "/Users/soupycampbell/Documents/smoke_log/ios/screenshots")
        let deviceDir = baseDir.appendingPathComponent(deviceName)
        
        do {
            // Create the device directory if it doesn't exist
            if !fileManager.fileExists(atPath: deviceDir.path) {
                try fileManager.createDirectory(at: deviceDir, withIntermediateDirectories: true)
            }
            
            let fileURL = deviceDir.appendingPathComponent(name + ".png")
            
            // Only resize for specific devices that need App Store dimensions
            if deviceName.contains("iPhone_16_Pro_Max") || deviceName.contains("iPhone_15_Pro") {
                if let image = UIImage(data: pngData), let resizedImageData = resizeImageForAppStore(image, isIPad: false).pngData() {
                    try resizedImageData.write(to: fileURL)
                    print("Screenshot saved (iPhone resized) to \(fileURL.path)")
                }
            } 
            else if deviceName.contains("iPad_Pro_13-inch_(M4)") {
                if let image = UIImage(data: pngData), let resizedImageData = resizeImageForAppStore(image, isIPad: true).pngData() {
                    try resizedImageData.write(to: fileURL)
                    print("Screenshot saved (iPad resized) to \(fileURL.path)")
                }
            } 
            else {
                // For all other devices, save without resizing
                try pngData.write(to: fileURL)
                print("Screenshot saved (original size) to \(fileURL.path)")
            }
        } catch {
            print("Error saving screenshot to file: \(error)")
        }
    }
    
    // Helper method to resize images to App Store dimensions
    private func resizeImageForAppStore(_ image: UIImage, isIPad: Bool) -> UIImage {
        // Set target dimensions based on device type
        let targetWidth: CGFloat
        let targetHeight: CGFloat
        
        if isIPad {
            // iPad Pro dimensions (2048 × 2732px)
            targetWidth = 2048.0
            targetHeight = 2732.0
        } else {
            // iPhone dimensions (1284 × 2778px)
            targetWidth = 1284.0
            targetHeight = 2778.0
        }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0 // Use actual pixel dimensions
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: targetWidth, height: targetHeight), format: format)
        return renderer.image { _ in
            // Draw original image scaled to fill the target dimensions
            image.draw(in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
        }
    }
}
