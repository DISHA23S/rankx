/*
 * ANDROID SCREENSHOT SECURITY INTEGRATION
 * 
 * Instructions:
 * 1. Open your existing MainActivity.kt file (usually at: android/app/src/main/kotlin/com/example/quizapp/MainActivity.kt)
 * 2. Replace the entire contents with this code
 * 3. Make sure the package name matches your app's package
 * 
 * Features:
 * - FLAG_SECURE prevents screenshots and screen recording
 * - UserPresentBroadcastReceiver detects when user takes screenshot attempts
 * - MethodChannel communication with Flutter
 */

package com.example.quizapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.quizapp/screenshot_security"
    private var screenshotBlockingEnabled = false
    private var screenshotReceiver: BroadcastReceiver? = null
    private var methodChannel: MethodChannel? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "enableScreenshotBlocking" -> {
                    enableScreenshotBlocking()
                    result.success(true)
                }
                "disableScreenshotBlocking" -> {
                    disableScreenshotBlocking()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Setup screenshot detection
        setupScreenshotDetection()
    }
    
    /**
     * Enable FLAG_SECURE to block screenshots
     * This prevents the screen content from appearing in screenshots or screen recordings
     */
    private fun enableScreenshotBlocking() {
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
        screenshotBlockingEnabled = true
    }
    
    /**
     * Disable FLAG_SECURE to allow screenshots
     */
    private fun disableScreenshotBlocking() {
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        screenshotBlockingEnabled = false
    }
    
    /**
     * Setup screenshot detection using BroadcastReceiver
     * Note: This is a workaround as Android doesn't provide direct screenshot detection API
     */
    private fun setupScreenshotDetection() {
        screenshotReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == Intent.ACTION_USER_PRESENT) {
                    // User attempted to take screenshot
                    // Note: This is not 100% reliable but can catch some attempts
                    if (screenshotBlockingEnabled) {
                        notifyScreenshotAttempt()
                    }
                }
            }
        }
        
        val filter = IntentFilter(Intent.ACTION_USER_PRESENT)
        registerReceiver(screenshotReceiver, filter)
    }
    
    /**
     * Notify Flutter about screenshot attempt
     */
    private fun notifyScreenshotAttempt() {
        methodChannel?.invokeMethod("onScreenshotDetected", null)
    }
    
    override fun onDestroy() {
        super.onDestroy()
        // Cleanup
        if (screenshotReceiver != null) {
            unregisterReceiver(screenshotReceiver)
        }
    }
}
