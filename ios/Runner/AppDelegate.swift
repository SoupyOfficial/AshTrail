import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Method to handle screenshot requests from Flutter
  func takeScreenshot(_ name: String) {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          let screenshot = UIScreen.main.snapshotView(afterScreenUpdates: true)
          let renderer = UIGraphicsImageRenderer(bounds: screenshot.bounds)
          let image = renderer.image { ctx in
              screenshot.drawHierarchy(in: screenshot.bounds, afterScreenUpdates: true)
          }
          
          // Save to Documents directory
          let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
          let screenshotsDirectory = documentsDirectory.appendingPathComponent("screenshots")
          
          try? FileManager.default.createDirectory(at: screenshotsDirectory, 
                                                 withIntermediateDirectories: true)
          
          let fileURL = screenshotsDirectory.appendingPathComponent("\(name).png")
          if let data = image.pngData() {
              try? data.write(to: fileURL)
              print("Screenshot saved to: \(fileURL.path)")
          }
      }
  }
}
