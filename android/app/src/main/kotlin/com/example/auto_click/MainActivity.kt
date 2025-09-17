package com.auto.tasks

import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.auto.tasks/accessibility"
    private val OVERLAY_CHANNEL = "com.auto.tasks/overlay"
    private val TAG = "TikTokAutoScroll"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Setup overlay method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL)
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        "showTerminationOverlay" -> {
                            // Check overlay permission first
                            if (!checkOverlayPermission()) {
                                Log.w(TAG, "Overlay permission not granted, requesting permission")
                                requestOverlayPermission()
                                result.success(false)
                                return@setMethodCallHandler
                            }

                            val taskType = call.argument<String>("taskType")
                            val taskId = call.argument<String>("taskId")
                            val success = showTerminationOverlay(taskType, taskId)
                            result.success(success)
                        }
                        "hideTerminationOverlay" -> {
                            val success = hideTerminationOverlay()
                            result.success(success)
                        }
                        "cancelEventSequence" -> {
                            val success = cancelEventSequence()
                            result.success(success)
                        }
                        "checkOverlayPermission" -> {
                            val hasPermission = checkOverlayPermission()
                            result.success(hasPermission)
                        }
                        "requestOverlayPermission" -> {
                            requestOverlayPermission()
                            result.success(true)
                        }
                        "isOverlayVisible" -> {
                            val isVisible = isTerminationOverlayVisible()
                            result.success(isVisible)
                        }
                        else -> {
                            result.notImplemented()
                        }
                    }
                }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            when (call.method) {
                "isAccessibilityServiceEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "performSwipe" -> {
                    val direction = call.argument<String>("direction")
                    if (direction != null) {
                        val success = performSwipe(direction)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "Direction is required", null)
                    }
                }
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings()
                    result.success(null)
                }
                "launchTikTok" -> {
                    val success = launchTikTokApp()
                    result.success(success)
                }
                "isTikTokInstalled" -> {
                    val installed = isTikTokInstalled()
                    result.success(installed)
                }
                "clickLikeButton" -> {
                    val success = clickLikeButton()
                    result.success(success)
                }
                "clickSaveButton" -> {
                    val success = clickSaveButton()
                    result.success(success)
                }
                "performCommentAction" -> {
                    val commentText = call.argument<String>("commentText")
                    if (commentText != null) {
                        val success = performCommentAction(commentText)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "Comment text is required", null)
                    }
                }
                "executeEventSequence" -> {
                    val events = call.argument<List<Map<String, Any>>>("events")
                    if (events != null) {
                        val success = executeEventSequenceWithCallback(events) { completed ->
                            // The callback will be called when the sequence is actually completed
                            result.success(completed)
                        }
                        if (!success) {
                            result.error("EXECUTION_FAILED", "Failed to start event sequence", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Events list is required", null)
                    }
                }
                "cancelEventSequence" -> {
                    val success = cancelEventSequence()
                    result.success(success)
                }
                "isEventSequenceRunning" -> {
                    val isRunning = isEventSequenceRunning()
                    result.success(isRunning)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        return AutoClickAccessibilityService.isServiceEnabled()
    }

    private fun performSwipe(direction: String): Boolean {
        val service = AutoClickAccessibilityService.getInstance()
        return service?.performSwipeGesture(direction) ?: false
    }

    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }

    private fun isTikTokInstalled(): Boolean {
        val packageManager = packageManager
        val tiktokPackages = listOf("com.ss.android.ugc.trill", "com.zhiliaoapp.musically")

        for (packageName in tiktokPackages) {
            try {
                packageManager.getPackageInfo(packageName, 0)
                return true
            } catch (e: PackageManager.NameNotFoundException) {
                // Continue checking other packages
                continue
            }
        }
        return false
    }

    private fun launchTikTokApp(): Boolean {
        val packageManager = packageManager
        val tiktokPackages = listOf("com.ss.android.ugc.trill", "com.zhiliaoapp.musically")

        for (packageName in tiktokPackages) {
            try {
                // First check if package is installed
                packageManager.getPackageInfo(packageName, 0)

                // Get launch intent
                val intent = packageManager.getLaunchIntentForPackage(packageName)
                if (intent != null) {
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    startActivity(intent)
                    Log.d(TAG, "Successfully launched TikTok with package: $packageName")
                    return true
                }
            } catch (e: PackageManager.NameNotFoundException) {
                Log.d(TAG, "Package not found: $packageName")
                continue
            } catch (e: Exception) {
                Log.e(TAG, "Error launching package $packageName: ${e.message}")
                continue
            }
        }

        Log.w(TAG, "Failed to launch TikTok - no valid packages found")
        return false
    }

    private fun clickLikeButton(): Boolean {
        val service = AutoClickAccessibilityService.getInstance()
        return service?.clickLikeButton() ?: false
    }

    private fun clickSaveButton(): Boolean {
        val service = AutoClickAccessibilityService.getInstance()
        return service?.clickSaveButton() ?: false
    }

    private fun performCommentAction(commentText: String): Boolean {
        val service = AutoClickAccessibilityService.getInstance()
        return service?.performCommentAction(commentText) ?: false
    }

    private fun executeEventSequence(events: List<Map<String, Any>>): Boolean {
        val service = AutoClickAccessibilityService.getInstance()
        return service?.executeEventSequence(events) ?: false
    }

    private fun executeEventSequenceWithCallback(events: List<Map<String, Any>>, callback: (Boolean) -> Unit): Boolean {
        val service = AutoClickAccessibilityService.getInstance()
        return service?.executeEventSequenceWithCallback(events, callback) ?: false
    }

    private fun cancelEventSequence(): Boolean {
        val service = AutoClickAccessibilityService.getInstance()
        if (service != null) {
            service.cancelEventSequence()
            return true
        }
        return false
    }

    private fun isEventSequenceRunning(): Boolean {
        val service = AutoClickAccessibilityService.getInstance()
        return service?.isEventSequenceRunning() ?: false
    }

    private fun showTerminationOverlay(taskType: String?, taskId: String?): Boolean {
        val service = AutoClickAccessibilityService.getInstance()
        return service?.showTerminationOverlay(taskType ?: "unknown", taskId ?: "unknown") ?: false
    }

    private fun hideTerminationOverlay(): Boolean {
        val service = AutoClickAccessibilityService.getInstance()
        return service?.hideTerminationOverlay() ?: false
    }

    private fun isTerminationOverlayVisible(): Boolean {
        val service = AutoClickAccessibilityService.getInstance()
        return service?.isTerminationOverlayVisible() ?: false
    }

    private fun checkOverlayPermission(): Boolean {
        return if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            android.provider.Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            if (!android.provider.Settings.canDrawOverlays(this)) {
                val intent =
                        Intent(
                                android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                android.net.Uri.parse("package:$packageName")
                        )
                startActivity(intent)
            }
        }
    }
}
