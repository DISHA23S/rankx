import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private let CHANNEL = "com.example.quizapp/screenshot_security"
    private var screenshotChannel: FlutterMethodChannel?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        
        // Setup method channel
        screenshotChannel = FlutterMethodChannel(
            name: CHANNEL,
            binaryMessenger: controller.binaryMessenger
        )
        
        screenshotChannel?.setMethodCallHandler({ [weak self]
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            
            switch call.method {
            case "enableScreenshotBlocking":
                // iOS doesn't support blocking screenshots
                // Return false to indicate it's not supported
                self?.setupScreenshotDetection()
                result(false)
                
            case "disableScreenshotBlocking":
                self?.removeScreenshotDetection()
                result(true)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        })
        
        // Setup screenshot detection observer
        setupScreenshotDetection()
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    /**
     * Setup screenshot detection using NotificationCenter
     */
    private func setupScreenshotDetection() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenshotTaken),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
    }
    
    /**
     * Remove screenshot detection observer
     */
    private func removeScreenshotDetection() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
    }
    
    /**
     * Called when user takes a screenshot
     */
    @objc private func screenshotTaken() {
        // Notify Flutter that screenshot was detected
        screenshotChannel?.invokeMethod("onScreenshotDetected", arguments: nil)
    }
    
    deinit {
        removeScreenshotDetection()
    }
}
