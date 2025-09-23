package com.auto.tasks

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Intent
import android.graphics.Color
import android.graphics.Path
import android.graphics.Rect
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.TextView
import io.flutter.plugin.common.MethodChannel


class AutoClickAccessibilityService : AccessibilityService() {

    companion object {
        private var instance: AutoClickAccessibilityService? = null
        private val TAG = "TikTokAutoScroll"

        fun getInstance(): AutoClickAccessibilityService? {
            return instance
        }

        fun isServiceEnabled(): Boolean {
            return instance != null
        }
    }

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var terminationOverlayView: View? = null
    private val handler = Handler(Looper.getMainLooper())
    private var isEventSequenceRunning = false
    private var methodResult: MethodChannel.Result? = null


    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        Log.d(TAG, "Accessibility service connected")
    }

    override fun onDestroy() {
        super.onDestroy()
        cancelEventSequence()
        hideClickOverlay()
        hideTerminationOverlay()
        instance = null
        windowManager = null
        Log.d(TAG, "Accessibility service destroyed")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Handle accessibility events if needed
    }

    override fun onInterrupt() {
        // Handle interruptions
    }

    fun performSwipeGesture(direction: String): Boolean {
        val displayMetrics = resources.displayMetrics
        val screenWidth = displayMetrics.widthPixels
        val screenHeight = displayMetrics.heightPixels

        val path = Path()

        when (direction) {
            "left" -> {
                // Swipe from right to left
                path.moveTo(screenWidth * 0.8f, screenHeight * 0.5f)
                path.lineTo(screenWidth * 0.2f, screenHeight * 0.5f)
            }
            "right" -> {
                // Swipe from left to right
                path.moveTo(screenWidth * 0.2f, screenHeight * 0.5f)
                path.lineTo(screenWidth * 0.8f, screenHeight * 0.5f)
            }
            "up" -> {
                // Swipe from bottom to top (scroll up in TikTok)
                path.moveTo(screenWidth * 0.5f, screenHeight * 0.8f)
                path.lineTo(screenWidth * 0.5f, screenHeight * 0.2f)
            }
            "down" -> {
                // Swipe from top to bottom (scroll down)
                path.moveTo(screenWidth * 0.5f, screenHeight * 0.2f)
                path.lineTo(screenWidth * 0.5f, screenHeight * 0.8f)
            }
            else -> return false
        }

        val gestureBuilder = GestureDescription.Builder()
        gestureBuilder.addStroke(GestureDescription.StrokeDescription(path, 0, 300))

        return dispatchGesture(gestureBuilder.build(), null, null)
    }

    fun clickLikeButton(): Boolean {
        try {
            val rootNode = rootInActiveWindow
            if (rootNode == null) {
                Log.w(TAG, "Root node is null")
                return false
            }

            // Look for like button using various strategies
            val likeButton = findLikeButton(rootNode)

            if (likeButton != null) {
                Log.d(TAG, "Found like button, attempting to click")
                val bounds = Rect()
                likeButton.getBoundsInScreen(bounds)

                // Click at the center of the like button
                val clickX = bounds.centerX().toFloat()
                val clickY = bounds.centerY().toFloat()

                Log.d(TAG, "Clicking like button at: ($clickX, $clickY)")
                return performClick(clickX, clickY)
            } else {
                Log.w(TAG, "Like button not found using detection methods")
                // Try multiple fallback positions based on different screen sizes
                return tryMultipleLikePositions()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error clicking like button: ${e.message}")
            return false
        }
    }

    fun clickSaveButton(): Boolean {
        try {
            val rootNode = rootInActiveWindow
            if (rootNode == null) {
                Log.w(TAG, "Root node is null")
                return false
            }

            // Look for save button using various strategies
            val saveButton = findSaveButton(rootNode)

            if (saveButton != null) {
                Log.d(TAG, "Found save button, attempting to click")
                val bounds = Rect()
                saveButton.getBoundsInScreen(bounds)

                // Click at the center of the save button
                val clickX = bounds.centerX().toFloat()
                val clickY = bounds.centerY().toFloat()

                Log.d(TAG, "Clicking save button at: ($clickX, $clickY)")
                return performClick(clickX, clickY)
            } else {
                Log.w(TAG, "Save button not found using detection methods")
                // Try multiple fallback positions based on different screen sizes
                return tryMultipleSavePositions()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error clicking save button: ${e.message}")
            return false
        }
    }

    private fun findLikeButton(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        // Strategy 1: Look for content description containing "like"
        if (node.contentDescription != null) {
            val description = node.contentDescription.toString().lowercase()
            if (description.contains("like") ||
                            description.contains("♥") ||
                            description.contains("❤") ||
                            description.contains("heart") ||
                            description.contains("favourite") ||
                            description.contains("favorite")
            ) {
                Log.d(TAG, "Found like button by content description: ${node.contentDescription}")
                return node
            }
        }

        // Strategy 2: Look for text containing "like"
        if (node.text != null) {
            val text = node.text.toString().lowercase()
            if (text.contains("like") || text.contains("♥") || text.contains("❤")) {
                Log.d(TAG, "Found like button by text: ${node.text}")
                return node
            }
        }

        // Strategy 3: Look for clickable elements in the right sidebar area (TikTok interaction
        // buttons)
        if (node.isClickable) {
            val bounds = Rect()
            node.getBoundsInScreen(bounds)
            val displayMetrics = resources.displayMetrics
            val screenWidth = displayMetrics.widthPixels
            val screenHeight = displayMetrics.heightPixels

            // TikTok like button is in the right sidebar, positioned at:
            // - Horizontally: ~92% from left (90-94% range for different screen sizes)
            // - Vertically: ~40% from top (35-45% range)
            // - Should be below profile image (~33%) and above comment button (~47%)
            if (bounds.centerX() > screenWidth * 0.90 &&
                            bounds.centerX() < screenWidth * 0.94 &&
                            bounds.centerY() > screenHeight * 0.35 &&
                            bounds.centerY() < screenHeight * 0.45
            ) {

                // Additional check: like button should be reasonably sized (not too small or too
                // large)
                val buttonWidth = bounds.width()
                val buttonHeight = bounds.height()
                if (buttonWidth > 30 && buttonWidth < 150 && buttonHeight > 30 && buttonHeight < 150
                ) {
                    Log.d(TAG, "Found potential like button by position: bounds=$bounds")
                    return node
                }
            }
        }

        // Recursively search child nodes
        for (i in 0 until node.childCount) {
            val childNode = node.getChild(i)
            if (childNode != null) {
                val result = findLikeButton(childNode)
                if (result != null) {
                    return result
                }
                childNode.recycle()
            }
        }

        return null
    }

    private fun findSaveButton(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        // Strategy 1: Look for content description containing "save", "bookmark", "add to
        // favorites"
        if (node.contentDescription != null) {
            val description = node.contentDescription.toString().lowercase()
            if (description.contains("save") ||
                            description.contains("bookmark") ||
                            description.contains("🔖") ||
                            description.contains("add to favorites") ||
                            description.contains("add to favourites") ||
                            description.contains("collect")
            ) {
                Log.d(TAG, "Found save button by content description: ${node.contentDescription}")
                return node
            }
        }

        // Strategy 2: Look for text containing "save" or bookmark related terms
        if (node.text != null) {
            val text = node.text.toString().lowercase()
            if (text.contains("save") || text.contains("bookmark") || text.contains("🔖")) {
                Log.d(TAG, "Found save button by text: ${node.text}")
                return node
            }
        }

        // Strategy 3: Look for clickable elements in the right sidebar area (TikTok interaction
        // buttons)
        if (node.isClickable) {
            val bounds = Rect()
            node.getBoundsInScreen(bounds)
            val displayMetrics = resources.displayMetrics
            val screenWidth = displayMetrics.widthPixels
            val screenHeight = displayMetrics.heightPixels

            // TikTok save button is in the right sidebar, positioned at:
            // - Horizontally: ~92% from left (90-94% range for different screen sizes)
            // - Vertically: ~54% from top (49-59% range)
            // - Should be below comment button (~47%) and above share button (~61%)
            if (bounds.centerX() > screenWidth * 0.90 &&
                            bounds.centerX() < screenWidth * 0.94 &&
                            bounds.centerY() > screenHeight * 0.49 &&
                            bounds.centerY() < screenHeight * 0.59
            ) {

                // Additional check: save button should be reasonably sized (not too small or too
                // large)
                val buttonWidth = bounds.width()
                val buttonHeight = bounds.height()
                if (buttonWidth > 30 && buttonWidth < 150 && buttonHeight > 30 && buttonHeight < 150
                ) {
                    Log.d(TAG, "Found potential save button by position: bounds=$bounds")
                    return node
                }
            }
        }

        // Recursively search child nodes
        for (i in 0 until node.childCount) {
            val childNode = node.getChild(i)
            if (childNode != null) {
                val result = findSaveButton(childNode)
                if (result != null) {
                    return result
                }
                childNode.recycle()
            }
        }

        return null
    }

    private fun tryMultipleLikePositions(): Boolean {
        val displayMetrics = resources.displayMetrics
        val screenWidth = displayMetrics.widthPixels
        val screenHeight = displayMetrics.heightPixels

        // Try multiple positions where the like button could be based on accurate position data:
        // Like button is at ~92% from left, ~40% from top
        val positions =
                listOf(
                        // Primary position (exact position from user data)
                        Pair(screenWidth * 0.92f, screenHeight * 0.40f),
                        // Alternative positions for different screen sizes/layouts
                        Pair(screenWidth * 0.91f, screenHeight * 0.39f), // Slightly left and up
                        Pair(screenWidth * 0.93f, screenHeight * 0.41f), // Slightly right and down
                        Pair(screenWidth * 0.92f, screenHeight * 0.38f), // Same X, slightly higher
                        Pair(screenWidth * 0.92f, screenHeight * 0.42f) // Same X, slightly lower
                )

        for ((index, position) in positions.withIndex()) {
            Log.d(TAG, "Trying like position ${index + 1}: (${position.first}, ${position.second})")

            if (performClick(position.first, position.second)) {
                // Add a small delay between attempts
                try {
                    Thread.sleep(200)
                } catch (e: InterruptedException) {
                    Thread.currentThread().interrupt()
                }

                // For now, return true after first attempt
                // In a real scenario, you might want to verify if the like was successful
                return true
            }
        }

        return false
    }

    private fun tryMultipleSavePositions(): Boolean {
        val displayMetrics = resources.displayMetrics
        val screenWidth = displayMetrics.widthPixels
        val screenHeight = displayMetrics.heightPixels

        // Try multiple positions where the save button could be based on accurate position data:
        // Save button is at ~92% from left, ~54% from top
        val positions =
                listOf(
                        // Primary position (exact position from user data)
                        Pair(screenWidth * 0.92f, screenHeight * 0.54f),
                        // Alternative positions for different screen sizes/layouts
                        Pair(screenWidth * 0.91f, screenHeight * 0.53f), // Slightly left and up
                        Pair(screenWidth * 0.93f, screenHeight * 0.55f), // Slightly right and down
                        Pair(screenWidth * 0.92f, screenHeight * 0.52f), // Same X, slightly higher
                        Pair(screenWidth * 0.92f, screenHeight * 0.56f) // Same X, slightly lower
                )

        for ((index, position) in positions.withIndex()) {
            Log.d(TAG, "Trying save position ${index + 1}: (${position.first}, ${position.second})")

            if (performClick(position.first, position.second)) {
                // Add a small delay between attempts
                try {
                    Thread.sleep(200)
                } catch (e: InterruptedException) {
                    Thread.currentThread().interrupt()
                }

                // For now, return true after first attempt
                // In a real scenario, you might want to verify if the save was successful
                return true
            }
        }

        return false
    }

    fun performCommentAction(commentText: String): Boolean {
        try {
            Log.d(TAG, "Starting comment action with text: $commentText")

            // Step 1: Click on comment button to open comment bottom sheet
            val commentButtonClicked = clickCommentButton()
            if (!commentButtonClicked) {
                Log.w(TAG, "Failed to click comment button")
                return false
            }

            // Step 2: Wait for comment bottom sheet to open
            Thread.sleep(2000)

            // Step 3: Find and click the comment input field
            val inputFieldClicked = clickCommentInputField()
            if (!inputFieldClicked) {
                Log.w(TAG, "Failed to click comment input field")
                return false
            }

            // Step 4: Wait for keyboard to appear and input field to be ready
            Thread.sleep(1500)

            // Step 5: Type the comment text
            val textEntered = typeCommentText(commentText)
            if (!textEntered) {
                Log.w(TAG, "Failed to enter comment text")
                return false
            }

            // Step 6: Wait a bit then click send button
            Thread.sleep(1000)
            val sendButtonClicked = clickSendButton()
            if (!sendButtonClicked) {
                Log.w(TAG, "Failed to click send button")
                return false
            }

            Log.d(TAG, "Comment action completed successfully")
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Error performing comment action: ${e.message}")
            return false
        }
    }

    private fun clickCommentButton(): Boolean {
        val rootNode = rootInActiveWindow
        if (rootNode == null) {
            Log.w(TAG, "Root node is null")
            return false
        }

        // Look for comment button using various strategies
        val commentButton = findCommentButton(rootNode)

        if (commentButton != null) {
            Log.d(TAG, "Found comment button, attempting to click")
            val bounds = Rect()
            commentButton.getBoundsInScreen(bounds)

            val clickX = bounds.centerX().toFloat()
            val clickY = bounds.centerY().toFloat()

            Log.d(TAG, "Clicking comment button at: ($clickX, $clickY)")
            return performClick(clickX, clickY)
        } else {
            Log.w(TAG, "Comment button not found, trying fallback positions")
            return tryMultipleCommentPositions()
        }
    }

    private fun findCommentButton(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        // Strategy 1: Look for content description containing "comment"
        if (node.contentDescription != null) {
            val description = node.contentDescription.toString().lowercase()
            if (description.contains("comment") ||
                            description.contains("💬") ||
                            description.contains("reply") ||
                            description.contains("discuss")
            ) {
                Log.d(
                        TAG,
                        "Found comment button by content description: ${node.contentDescription}"
                )
                return node
            }
        }

        // Strategy 2: Look for text containing "comment"
        if (node.text != null) {
            val text = node.text.toString().lowercase()
            if (text.contains("comment") || text.contains("💬")) {
                Log.d(TAG, "Found comment button by text: ${node.text}")
                return node
            }
        }

        // Strategy 3: Look for clickable elements in the right sidebar area (TikTok interaction
        // buttons)
        if (node.isClickable) {
            val bounds = Rect()
            node.getBoundsInScreen(bounds)
            val displayMetrics = resources.displayMetrics
            val screenWidth = displayMetrics.widthPixels
            val screenHeight = displayMetrics.heightPixels

            // TikTok comment button is in the right sidebar, positioned at:
            // - Horizontally: ~92% from left (90-94% range for different screen sizes)
            // - Vertically: ~47% from top (42-52% range)
            // - Should be below like button (~40%) and above save button (~54%)
            if (bounds.centerX() > screenWidth * 0.90 &&
                            bounds.centerX() < screenWidth * 0.94 &&
                            bounds.centerY() > screenHeight * 0.42 &&
                            bounds.centerY() < screenHeight * 0.52
            ) {

                val buttonWidth = bounds.width()
                val buttonHeight = bounds.height()
                if (buttonWidth > 30 && buttonWidth < 150 && buttonHeight > 30 && buttonHeight < 150
                ) {
                    Log.d(TAG, "Found potential comment button by position: bounds=$bounds")
                    return node
                }
            }
        }

        // Recursively search child nodes
        for (i in 0 until node.childCount) {
            val childNode = node.getChild(i)
            if (childNode != null) {
                val result = findCommentButton(childNode)
                if (result != null) {
                    return result
                }
                childNode.recycle()
            }
        }

        return null
    }

    private fun tryMultipleCommentPositions(): Boolean {
        val displayMetrics = resources.displayMetrics
        val screenWidth = displayMetrics.widthPixels
        val screenHeight = displayMetrics.heightPixels

        // Comment button is at ~92% from left, ~47% from top
        val positions =
                listOf(
                        Pair(screenWidth * 0.92f, screenHeight * 0.47f),
                        Pair(screenWidth * 0.91f, screenHeight * 0.46f),
                        Pair(screenWidth * 0.93f, screenHeight * 0.48f),
                        Pair(screenWidth * 0.92f, screenHeight * 0.45f),
                        Pair(screenWidth * 0.92f, screenHeight * 0.49f)
                )

        for ((index, position) in positions.withIndex()) {
            Log.d(
                    TAG,
                    "Trying comment position ${index + 1}: (${position.first}, ${position.second})"
            )

            if (performClick(position.first, position.second)) {
                Thread.sleep(200)
                return true
            }
        }

        return false
    }

    private fun clickCommentInputField(): Boolean {
        val rootNode = rootInActiveWindow
        if (rootNode == null) return false

        val inputField = findCommentInputField(rootNode)

        if (inputField != null) {
            Log.d(TAG, "Found comment input field, attempting to click")
            val bounds = Rect()
            inputField.getBoundsInScreen(bounds)

            val clickX = bounds.centerX().toFloat()
            val clickY = bounds.centerY().toFloat()

            return performClick(clickX, clickY)
        } else {
            // Fallback: try clicking at bottom of screen where input field usually is
            val displayMetrics = resources.displayMetrics
            val screenWidth = displayMetrics.widthPixels
            val screenHeight = displayMetrics.heightPixels

            // Comment input is usually at bottom of screen, around 85-95% down
            return performClick(screenWidth * 0.5f, screenHeight * 0.90f)
        }
    }

    private fun findCommentInputField(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        if (node.className != null && node.className.toString().contains("EditText")) {
            val bounds = Rect()
            node.getBoundsInScreen(bounds)
            val displayMetrics = resources.displayMetrics
            val screenHeight = displayMetrics.heightPixels

            // Input field should be in bottom half of screen
            if (bounds.centerY() > screenHeight * 0.6) {
                Log.d(TAG, "Found potential comment input field")
                return node
            }
        }

        // Recursively search child nodes
        for (i in 0 until node.childCount) {
            val childNode = node.getChild(i)
            if (childNode != null) {
                val result = findCommentInputField(childNode)
                if (result != null) {
                    return result
                }
                childNode.recycle()
            }
        }

        return null
    }

    private fun typeCommentText(text: String): Boolean {
        val rootNode = rootInActiveWindow
        if (rootNode == null) return false

        val inputField = findCommentInputField(rootNode)

        if (inputField != null && inputField.isEditable) {
            Log.d(TAG, "Pasting comment text: $text")
            // Use paste action to enter text
            val arguments = android.os.Bundle()
            arguments.putCharSequence(
                    AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE,
                    text
            )
            return inputField.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)
        }

        return false
    }

    private fun clickSendButton(): Boolean {
        val rootNode = rootInActiveWindow
        if (rootNode == null) return false

        val sendButton = findSendButton(rootNode)

        if (sendButton != null) {
            Log.d(TAG, "Found send button, attempting to click")
            val bounds = Rect()
            sendButton.getBoundsInScreen(bounds)

            val clickX = bounds.centerX().toFloat()
            val clickY = bounds.centerY().toFloat()

            return performClick(clickX, clickY)
        } else {
            // Fallback: try clicking at typical send button position
            val displayMetrics = resources.displayMetrics
            val screenWidth = displayMetrics.widthPixels
            val screenHeight = displayMetrics.heightPixels

            // Send button is usually at right side of comment input, around 85-95% down
            return performClick(screenWidth * 0.85f, screenHeight * 0.90f)
        }
    }

    private fun findSendButton(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        // Look for send button characteristics
        if (node.contentDescription != null) {
            val description = node.contentDescription.toString().lowercase()
            if (description.contains("send") ||
                            description.contains("post") ||
                            description.contains("submit") ||
                            description.contains("➤")
            ) {
                return node
            }
        }

        if (node.text != null) {
            val text = node.text.toString().lowercase()
            if (text.contains("send") || text.contains("post") || text.contains("➤")) {
                return node
            }
        }

        // Look for clickable elements near comment input field
        if (node.isClickable) {
            val bounds = Rect()
            node.getBoundsInScreen(bounds)
            val displayMetrics = resources.displayMetrics
            val screenWidth = displayMetrics.widthPixels
            val screenHeight = displayMetrics.heightPixels

            // Send button should be in bottom area and right side
            if (bounds.centerX() > screenWidth * 0.7 && bounds.centerY() > screenHeight * 0.8) {
                return node
            }
        }

        // Recursively search child nodes
        for (i in 0 until node.childCount) {
            val childNode = node.getChild(i)
            if (childNode != null) {
                val result = findSendButton(childNode)
                if (result != null) {
                    return result
                }
                childNode.recycle()
            }
        }

        return null
    }

    private fun performClick(x: Float, y: Float): Boolean {
        val displayMetrics = resources.displayMetrics
        val screenWidth = displayMetrics.widthPixels
        val screenHeight = displayMetrics.heightPixels

        // Log the click position with screen dimensions for debugging
        Log.d(TAG, "=== CLICK DEBUG INFO ===")
        Log.d(TAG, "Screen dimensions: ${screenWidth}x${screenHeight}")
        Log.d(TAG, "Click coordinates: (${x}, ${y})")
        Log.d(
                TAG,
                "Click position as percentage: (${(x/screenWidth*100).toInt()}%, ${(y/screenHeight*100).toInt()}%)"
        )
        Log.d(TAG, "=======================")

        val path = Path()
        path.moveTo(x, y)

        val gestureBuilder = GestureDescription.Builder()
        val strokeDescription =
                GestureDescription.StrokeDescription(path, 0, 200) // Increased from 100ms to 200ms
        gestureBuilder.addStroke(strokeDescription)

        val gesture = gestureBuilder.build()
        val result = dispatchGesture(gesture, null, null)

        // Show click overlay if enabled
        if (showOverlayEnabled) {
            showClickOverlay(x, y)
        }

        Log.d(TAG, "Click gesture dispatched: ${if (result) "SUCCESS" else "FAILED"}")
        return result
    }
   
     fun executeEventSequence(events: List<Map<String, Any>>, result: MethodChannel.Result): Boolean {
        try {
            if (isEventSequenceRunning) {
                Log.w(TAG, "Event sequence already running, cancelling previous one")
                cancelEventSequence() // ستلغي المهمة القديمة وتخبر Dart بفشلها
            }

            Log.d(TAG, "Starting event sequence with ${events.size} events")
            isEventSequenceRunning = true
            methodResult = result // احتفظ بالـ result لإرسال الرد لاحقًا
            executeEventSequenceAsync(events, 0)
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Error starting event sequence: ${e.message}")
            isEventSequenceRunning = false
            methodResult = null
            return false
        }
    }  

    private fun executeEventSequenceAsync(events: List<Map<String, Any>>, currentIndex: Int) {
            if (!isEventSequenceRunning) {
            Log.d(TAG, "Event sequence was cancelled, stopping execution")
            methodResult?.success(false) 
            methodResult = null
            return
        }

        if (currentIndex >= events.size) {
            Log.d(TAG, "Event sequence completed successfully")
            isEventSequenceRunning = false
            methodResult?.success(true)
            methodResult = null
            return
        }
        val event = events[currentIndex]
        Log.d(TAG, "Executing event $currentIndex: $event")

        val eventType = event["type"] as? String
        val eventData = event["data"] as? Map<String, Any>

        if (eventType == null || eventData == null) {
            Log.w(TAG, "Invalid event format at index $currentIndex")
            // Continue to next event
            executeEventSequenceAsync(events, currentIndex + 1)
            return
        }

        when (eventType) {
            "wait" -> {
                val milliseconds = (eventData["milliseconds"] as? Number)?.toLong()
                if (milliseconds != null) {
                    Log.d(TAG, "Waiting for ${milliseconds}ms before next event")
                    // Use Handler to delay execution without blocking main thread
                    handler.postDelayed(
                            { executeEventSequenceAsync(events, currentIndex + 1) },
                            milliseconds
                    )
                } else {
                    Log.w(TAG, "wait event missing milliseconds parameter")
                    executeEventSequenceAsync(events, currentIndex + 1)
                }
            }
            "openUrl" -> {
                val url = eventData["url"] as? String
                if (url != null) {
                    executeOpenUrl(url)
                } else {
                    Log.w(TAG, "openUrl event missing url parameter")
                }
                // Continue to next event with smart delay
                continueWithSmartDelay(eventType, events, currentIndex)
            }
            "click" -> {
                val x = (eventData["x"] as? Number)?.toFloat()
                val y = (eventData["y"] as? Number)?.toFloat()
                if (x != null && y != null) {
                    Log.d(TAG, "Executing click event from Flutter: ($x, $y)")
                    performClick(x, y)
                } else {
                    Log.w(TAG, "click event missing x or y parameter")
                }
                continueWithSmartDelay(eventType, events, currentIndex)
            }
            "swap" -> {
                val fromX = (eventData["from_x"] as? Number)?.toFloat()
                val fromY = (eventData["from_y"] as? Number)?.toFloat()
                val toX = (eventData["to_x"] as? Number)?.toFloat()
                val toY = (eventData["to_y"] as? Number)?.toFloat()
                val duration = (eventData["duration"] as? Number)?.toLong() ?: 70L
                if (fromX != null && fromY != null && toX != null && toY != null) {
                    performSwap(fromX, fromY, toX, toY, duration)
                } else {
                    Log.w(TAG, "swap event missing coordinate parameters")
                }
                continueWithSmartDelay(eventType, events, currentIndex)
            }
            "write" -> {
                val text = eventData["text"] as? String
                if (text != null) {
                    performWrite(text)
                } else {
                    Log.w(TAG, "write event missing text parameter")
                }
                continueWithSmartDelay(eventType, events, currentIndex)
            }
            "dismissKeyboard" -> {
                dismissKeyboard()
                continueWithSmartDelay(eventType, events, currentIndex)
            }
            "closeApp" -> {
                closeCurrentApp()
                continueWithSmartDelay(eventType, events, currentIndex)
            }
            "minimizeApp" -> {
                minimizeCurrentApp()
                continueWithSmartDelay(eventType, events, currentIndex)
            }
            "openThisApp" -> {
                openThisApp()
                continueWithSmartDelay(eventType, events, currentIndex)
            }
            "openThisAppIfNeeded" -> {
                openThisAppIfNeeded()
                continueWithSmartDelay(eventType, events, currentIndex)
            }
            "openApp" -> {
                val packageName = eventData["packageName"] as? String
                if (packageName != null) {
                    openAppByPackageName(packageName)
                } else {
                    Log.w(TAG, "openApp event missing packageName parameter")
                }
                continueWithSmartDelay(eventType, events, currentIndex)
            }
            "openTikTok" -> {
                openTikTok()
                continueWithSmartDelay(eventType, events, currentIndex)
            }
            "back" -> {
                performBackAction()
                continueWithSmartDelay(eventType, events, currentIndex)
            }
            else -> {
                Log.w(TAG, "Unknown event type: $eventType")
                executeEventSequenceAsync(events, currentIndex + 1)
            }
        }
    }

    private fun continueWithSmartDelay(
            eventType: String,
            events: List<Map<String, Any>>,
            currentIndex: Int
    ) {
        val delay = getOptimalDelay(eventType, currentIndex, events)
        Log.d(TAG, "Applying smart delay of ${delay}ms after $eventType event")

        handler.postDelayed({ executeEventSequenceAsync(events, currentIndex + 1) }, 0)
    }

    private fun getOptimalDelay(
            eventType: String,
            currentIndex: Int,
            events: List<Map<String, Any>>
    ): Long {
        val previousEventType =
                if (currentIndex > 0) events[currentIndex - 1]["type"] as? String else null
        val nextEventType =
                if (currentIndex + 1 < events.size) events[currentIndex + 1]["type"] as? String
                else null

        // Check if this is a rapid sequence (multiple swaps in a row)
        val isRapidSequence = isRapidSwapSequence(events, currentIndex)

        return when (eventType) {
            "click" -> {
                when (nextEventType) {
                    "click" -> if (isRapidSequence) 10L else 50L // Ultra-fast for rapid sequences
                    "swap" -> if (isRapidSequence) 20L else 100L
                    "write" -> 200L // Keep reasonable for text input
                    else -> if (isRapidSequence) 10L else 100L
                }
            }
            "swap" -> {
                when (nextEventType) {
                    "click" -> if (isRapidSequence) 10L else 100L
                    "swap" -> if (isRapidSequence) 5L else 30L // Ultra-fast for consecutive swaps
                    else -> if (isRapidSequence) 10L else 100L
                }
            }
            "write" -> {
                when (nextEventType) {
                    "click" -> 300L // Keep reasonable for text input
                    "dismissKeyboard" -> 200L
                    else -> 500L
                }
            }
            "openApp", "openTikTok", "openThisApp" -> {
                when (nextEventType) {
                    "click", "swap" -> 2000L // Keep reasonable for app loading
                    else -> 1500L
                }
            }
            "openUrl" -> {
                when (nextEventType) {
                    "click", "swap" -> 2500L // Keep reasonable for URL loading
                    else -> 2000L
                }
            }
            "dismissKeyboard" -> {
                when (nextEventType) {
                    "click", "swap" -> if (isRapidSequence) 50L else 300L
                    else -> if (isRapidSequence) 30L else 200L
                }
            }
            "closeApp", "minimizeApp" -> {
                when (nextEventType) {
                    "openApp", "openTikTok" -> 800L
                    else -> 500L
                }
            }
            "back" -> {
                when (nextEventType) {
                    "back" -> if (isRapidSequence) 50L else 200L
                    "click", "swap" -> if (isRapidSequence) 50L else 300L
                    else -> if (isRapidSequence) 30L else 200L
                }
            }
            else -> {
                when (previousEventType) {
                    "openApp", "openTikTok", "openUrl" -> 1000L
                    "write" -> 500L
                    else -> if (isRapidSequence) 10L else 100L
                }
            }
        }
    }

    // Helper function to detect rapid swap sequences
    private fun isRapidSwapSequence(events: List<Map<String, Any>>, currentIndex: Int): Boolean {
        // Check if we have multiple consecutive swap events
        var swapCount = 0
        var index = currentIndex

        // Count consecutive swaps before current event
        while (index >= 0 && index < events.size) {
            val eventType = events[index]["type"] as? String
            if (eventType == "swap") {
                swapCount++
            } else {
                break
            }
            index--
        }

        // Count consecutive swaps after current event
        index = currentIndex + 1
        while (index < events.size) {
            val eventType = events[index]["type"] as? String
            if (eventType == "swap") {
                swapCount++
            } else {
                break
            }
            index++
        }

        // Consider it rapid if we have 3 or more swaps in sequence
        return swapCount >= 3
    }

    // Cancel ongoing event sequence
    fun cancelEventSequence() {
        if (isEventSequenceRunning) {
            Log.d(TAG, "Cancelling ongoing event sequence")
            isEventSequenceRunning = false
            handler.removeCallbacksAndMessages(null)
            methodResult?.success(false)
            methodResult = null
        }
    }

    // Check if event sequence is currently running
    fun isEventSequenceRunning(): Boolean {
        return isEventSequenceRunning
    }

    private fun executeOpenUrl(url: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse(url))
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
            Log.d(TAG, "Successfully opened URL: $url")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open URL: $url, error: ${e.message}")
            false
        }
    }

    private fun performSwap(
            fromX: Float,
            fromY: Float,
            toX: Float,
            toY: Float,
            duration: Long
    ): Boolean {
        val path = Path()
        path.moveTo(fromX, fromY)
        path.lineTo(toX, toY)

        val gestureBuilder = GestureDescription.Builder()
        val strokeDescription = GestureDescription.StrokeDescription(path, 0, duration)
        gestureBuilder.addStroke(strokeDescription)

        val gesture = gestureBuilder.build()
        return dispatchGesture(gesture, null, null)
    }

    private fun performWrite(text: String): Boolean {
        val rootNode = rootInActiveWindow
        if (rootNode == null) {
            Log.w(TAG, "Root node is null, cannot write text")
            return false
        }

        val inputField = findFocusedEditText(rootNode)

        if (inputField != null && inputField.isEditable) {
            Log.d(TAG, "Writing text: $text")
            val arguments = android.os.Bundle()
            arguments.putCharSequence(
                    AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE,
                    text
            )
            return inputField.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)
        } else {
            Log.w(TAG, "No focused editable field found for writing text")
            return false
        }
    }

    private fun findFocusedEditText(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        if (node.isFocused &&
                        node.className != null &&
                        node.className.toString().contains("EditText")
        ) {
            return node
        }

        for (i in 0 until node.childCount) {
            val childNode = node.getChild(i)
            if (childNode != null) {
                val result = findFocusedEditText(childNode)
                if (result != null) {
                    return result
                }
                childNode.recycle()
            }
        }

        return null
    }

    // Debug method to test click at specific coordinates
    fun testClickAtCoordinates(x: Float, y: Float): Boolean {
        Log.d(TAG, "Testing click at coordinates: ($x, $y)")
        return performClick(x, y)
    }

    // Debug method to test click at percentage of screen
    fun testClickAtPercentage(xPercent: Float, yPercent: Float): Boolean {
        val displayMetrics = resources.displayMetrics
        val screenWidth = displayMetrics.widthPixels
        val screenHeight = displayMetrics.heightPixels

        val x = screenWidth * (xPercent / 100f)
        val y = screenHeight * (yPercent / 100f)

        Log.d(TAG, "Testing click at ${xPercent}%, ${yPercent}% (${x}, ${y})")
        return performClick(x, y)
    }

    // Method to log current screen info and TikTok button positions
    fun logScreenInfo() {
        val displayMetrics = resources.displayMetrics
        val screenWidth = displayMetrics.widthPixels
        val screenHeight = displayMetrics.heightPixels

        Log.d(TAG, "=== SCREEN & BUTTON INFO ===")
        Log.d(TAG, "Screen: ${screenWidth}x${screenHeight}")
        Log.d(TAG, "Like button (~92%, ~40%): (${screenWidth * 0.92f}, ${screenHeight * 0.40f})")
        Log.d(TAG, "Comment button (~92%, ~47%): (${screenWidth * 0.92f}, ${screenHeight * 0.47f})")
        Log.d(TAG, "Save button (~92%, ~54%): (${screenWidth * 0.92f}, ${screenHeight * 0.54f})")
        Log.d(TAG, "============================")
    }

    // Show click overlay at specified position
    private fun showClickOverlay(x: Float, y: Float) {
        try {
            if (windowManager == null) {
                Log.w(TAG, "WindowManager is null, cannot show overlay")
                return
            }

            // Remove existing overlay if any
            hideClickOverlay()

            // Create overlay view
            val overlayView =
                    TextView(this).apply {
                        text = "CLICK\n(${x.toInt()}, ${y.toInt()})"
                        setTextColor(Color.WHITE)
                        setBackgroundColor(Color.parseColor("#80FF0000")) // Semi-transparent red
                        textSize = 12f
                        gravity = Gravity.CENTER
                        setPadding(20, 20, 20, 20)
                    }

            // Set layout parameters for overlay
            val params =
                    WindowManager.LayoutParams().apply {
                        width = WindowManager.LayoutParams.WRAP_CONTENT
                        height = WindowManager.LayoutParams.WRAP_CONTENT
                        type = WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
                        flags =
                                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                                        WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
                        format = android.graphics.PixelFormat.TRANSLUCENT
                        gravity = Gravity.TOP or Gravity.LEFT

                        // Position the overlay at click coordinates (adjust for overlay size)
                        this.x = (x - 100).toInt() // Offset to center the overlay
                        this.y = (y - 50).toInt()
                    }

            // Add overlay to window
            windowManager?.addView(overlayView, params)
            this.overlayView = overlayView

            Log.d(TAG, "Overlay shown at: ($x, $y)")

            // Auto-hide after 3 seconds
            handler.postDelayed({ hideClickOverlay() }, 3000)
        } catch (e: Exception) {
            Log.e(TAG, "Error showing click overlay: ${e.message}")
        }
    }

    // Hide click overlay
    private fun hideClickOverlay() {
        try {
            overlayView?.let { view ->
                windowManager?.removeView(view)
                overlayView = null
                Log.d(TAG, "Overlay hidden")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error hiding click overlay: ${e.message}")
        }
    }

    // Enable/disable overlay visualization
    private var showOverlayEnabled = true

    fun enableClickOverlay(enabled: Boolean) {
        showOverlayEnabled = enabled
        Log.d(TAG, "Click overlay ${if (enabled) "enabled" else "disabled"}")
    }

    // Test method to show overlay at specific position without clicking
    fun testShowOverlay(x: Float, y: Float) {
        Log.d(TAG, "Testing overlay at: ($x, $y)")
        showClickOverlay(x, y)
    }

    // Dismiss keyboard using multiple strategies
    fun dismissKeyboard(): Boolean {
        try {
            Log.d(TAG, "Attempting to dismiss keyboard")

            // Strategy 1: Use back button action
            val backActionSuccess = performGlobalAction(GLOBAL_ACTION_BACK)
            if (backActionSuccess) {
                Log.d(TAG, "Keyboard dismissed using back action")
                return true
            }

            // Strategy 2: Click outside keyboard area (at top of screen)
            val displayMetrics = resources.displayMetrics
            val screenWidth = displayMetrics.widthPixels
            val screenHeight = displayMetrics.heightPixels

            // Click at center-top of screen where keyboard shouldn't be
            val clickOutsideSuccess = performClick(screenWidth * 0.5f, screenHeight * 0.1f)
            if (clickOutsideSuccess) {
                Log.d(TAG, "Keyboard dismissed by clicking outside")
                return true
            }

            // Strategy 3: Try to find and click a dismiss button or area
            val rootNode = rootInActiveWindow
            if (rootNode != null) {
                val dismissSuccess = findAndDismissKeyboard(rootNode)
                if (dismissSuccess) {
                    Log.d(TAG, "Keyboard dismissed using UI element")
                    return true
                }
            }

            Log.w(TAG, "All keyboard dismiss strategies failed")
            return false
        } catch (e: Exception) {
            Log.e(TAG, "Error dismissing keyboard: ${e.message}")
            return false
        }
    }

    private fun findAndDismissKeyboard(node: AccessibilityNodeInfo): Boolean {
        // Look for keyboard dismiss button or area
        if (node.contentDescription != null) {
            val description = node.contentDescription.toString().lowercase()
            if (description.contains("dismiss") ||
                            description.contains("close") ||
                            description.contains("hide") ||
                            description.contains("done")
            ) {
                val bounds = Rect()
                node.getBoundsInScreen(bounds)
                return performClick(bounds.centerX().toFloat(), bounds.centerY().toFloat())
            }
        }

        // Look for "Done" button or similar
        if (node.text != null) {
            val text = node.text.toString().lowercase()
            if (text.contains("done") || text.contains("close") || text.contains("hide")) {
                val bounds = Rect()
                node.getBoundsInScreen(bounds)
                return performClick(bounds.centerX().toFloat(), bounds.centerY().toFloat())
            }
        }

        // Recursively search child nodes
        for (i in 0 until node.childCount) {
            val childNode = node.getChild(i)
            if (childNode != null) {
                val result = findAndDismissKeyboard(childNode)
                if (result) {
                    return true
                }
                childNode.recycle()
            }
        }

        return false
    }

    // Alternative method using swipe down gesture to dismiss keyboard
    fun dismissKeyboardWithSwipe(): Boolean {
        try {
            Log.d(TAG, "Attempting to dismiss keyboard with swipe gesture")

            val displayMetrics = resources.displayMetrics
            val screenWidth = displayMetrics.widthPixels
            val screenHeight = displayMetrics.heightPixels

            // Swipe down from middle of screen to dismiss keyboard
            val path = Path()
            path.moveTo(screenWidth * 0.5f, screenHeight * 0.6f)
            path.lineTo(screenWidth * 0.5f, screenHeight * 0.8f)

            val gestureBuilder = GestureDescription.Builder()
            val strokeDescription = GestureDescription.StrokeDescription(path, 0, 300)
            gestureBuilder.addStroke(strokeDescription)

            val gesture = gestureBuilder.build()
            val result = dispatchGesture(gesture, null, null)

            Log.d(TAG, "Keyboard dismiss swipe executed: ${if (result) "SUCCESS" else "FAILED"}")
            return result
        } catch (e: Exception) {
            Log.e(TAG, "Error dismissing keyboard with swipe: ${e.message}")
            return false
        }
    }

    // Close current app using multiple strategies
    fun closeCurrentApp(): Boolean {
        try {
            Log.d(TAG, "Attempting to close current app")

            // Strategy 1: Use home button to go to launcher
            val homeActionSuccess = performGlobalAction(GLOBAL_ACTION_HOME)
            if (homeActionSuccess) {
                Log.d(TAG, "App minimized using home action")
                return true
            }

            // Strategy 2: Use recent apps and swipe away current app
            val recentAppsSuccess = closeAppThroughRecents()
            if (recentAppsSuccess) {
                Log.d(TAG, "App closed through recent apps")
                return true
            }

            // Strategy 3: Multiple back button presses to exit app
            val backButtonSuccess = closeAppWithBackButton()
            if (backButtonSuccess) {
                Log.d(TAG, "App closed using back button")
                return true
            }

            Log.w(TAG, "All app closing strategies failed")
            return false
        } catch (e: Exception) {
            Log.e(TAG, "Error closing current app: ${e.message}")
            return false
        }
    }

    private fun closeAppThroughRecents(): Boolean {
        try {
            // Open recent apps
            val recentAppsSuccess = performGlobalAction(GLOBAL_ACTION_RECENTS)
            if (!recentAppsSuccess) {
                Log.w(TAG, "Failed to open recent apps")
                return false
            }

            // Wait for recent apps to open
            Thread.sleep(1000)

            // Swipe up on the current app to close it
            val displayMetrics = resources.displayMetrics
            val screenWidth = displayMetrics.widthPixels
            val screenHeight = displayMetrics.heightPixels

            // Swipe up from center of screen (where current app should be)
            val path = Path()
            path.moveTo(screenWidth * 0.5f, screenHeight * 0.5f)
            path.lineTo(screenWidth * 0.5f, screenHeight * 0.1f)

            val gestureBuilder = GestureDescription.Builder()
            val strokeDescription = GestureDescription.StrokeDescription(path, 0, 400)
            gestureBuilder.addStroke(strokeDescription)

            val gesture = gestureBuilder.build()
            val swipeSuccess = dispatchGesture(gesture, null, null)

            if (swipeSuccess) {
                // Wait a bit then go home
                Thread.sleep(500)
                performGlobalAction(GLOBAL_ACTION_HOME)
                return true
            }

            return false
        } catch (e: Exception) {
            Log.e(TAG, "Error closing app through recents: ${e.message}")
            return false
        }
    }

    private fun closeAppWithBackButton(): Boolean {
        try {
            // Press back button multiple times to exit app
            var backPressCount = 0
            val maxBackPresses = 5

            while (backPressCount < maxBackPresses) {
                val backSuccess = performGlobalAction(GLOBAL_ACTION_BACK)
                if (!backSuccess) {
                    Log.w(TAG, "Back button press failed")
                    return false
                }

                backPressCount++

                // Wait between back presses
                Thread.sleep(500)

                // Check if we've reached home screen or launcher
                // This is a simplified check - in a real scenario you might want to
                // check the current package name or activity
                if (backPressCount >= 3) {
                    Log.d(TAG, "Performed $backPressCount back presses")
                    return true
                }
            }

            return true
        } catch (e: Exception) {
            Log.e(TAG, "Error closing app with back button: ${e.message}")
            return false
        }
    }

    // Force close current app by going home (simpler alternative)
    fun minimizeCurrentApp(): Boolean {
        try {
            Log.d(TAG, "Minimizing current app")
            val result = performGlobalAction(GLOBAL_ACTION_HOME)
            Log.d(TAG, "Home action executed: ${if (result) "SUCCESS" else "FAILED"}")
            return result
        } catch (e: Exception) {
            Log.e(TAG, "Error minimizing current app: ${e.message}")
            return false
        }
    }

    // Open/reopen this app (the current app)
    fun openThisApp(): Boolean {
        return openApp(getCurrentAppPackageName())
    }

    // Open this app only if it's not already open
    fun openThisAppIfNeeded(): Boolean {
        try {
            val currentPackageName = getCurrentAppPackageName()
            val ownPackageName = applicationContext.packageName

            if (currentPackageName == null) {
                Log.w(TAG, "Cannot determine current app package name, opening app anyway")
                return openApp(ownPackageName)
            }

            if (currentPackageName == ownPackageName) {
                Log.d(TAG, "App is already open ($currentPackageName), skipping reopen")
                return true
            } else {
                Log.d(
                        TAG,
                        "Different app is open ($currentPackageName), opening our app ($ownPackageName)"
                )
                return openApp(ownPackageName)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking if app needs to be opened: ${e.message}")
            // Fallback to opening the app
            return openThisApp()
        }
    }

    // Open a specific app by package name
    fun openApp(packageName: String?): Boolean {
        try {
            if (packageName == null) {
                Log.w(TAG, "Cannot open app: package name is null")
                return false
            }

            Log.d(TAG, "Attempting to open app: $packageName")

            val packageManager = packageManager
            val intent = packageManager.getLaunchIntentForPackage(packageName)

            if (intent != null) {
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                startActivity(intent)
                Log.d(TAG, "Successfully opened app: $packageName")
                return true
            } else {
                Log.w(TAG, "No launch intent found for package: $packageName")
                return false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error opening app $packageName: ${e.message}")
            return false
        }
    }

    // Get current app package name
    private fun getCurrentAppPackageName(): String? {
        try {
            // Method 1: Try to get from accessibility event
            val rootNode = rootInActiveWindow
            if (rootNode != null) {
                val packageName = rootNode.packageName?.toString()
                if (packageName != null && packageName.isNotEmpty()) {
                    Log.d(TAG, "Got current package name from root node: $packageName")
                    return packageName
                }
            }

            // Method 2: Use our own package name as fallback
            val ownPackageName = applicationContext.packageName
            Log.d(TAG, "Using own package name as fallback: $ownPackageName")
            return ownPackageName
        } catch (e: Exception) {
            Log.e(TAG, "Error getting current app package name: ${e.message}")
            return null
        }
    }

    // Open specific app with explicit package name
    fun openAppByPackageName(packageName: String): Boolean {
        Log.d(TAG, "Opening app by explicit package name: $packageName")
        return openApp(packageName)
    }

    // Open TikTok specifically (common use case)
    fun openTikTok(): Boolean {
        val tiktokPackages =
                listOf(
                        "com.zhiliaoapp.musically", // TikTok international
                        "com.ss.android.ugc.aweme", // TikTok China (Douyin)
                        "com.zhiliaoapp.musically.go" // TikTok Lite
                )

        for (packageName in tiktokPackages) {
            if (isAppInstalled(packageName)) {
                Log.d(TAG, "Found TikTok package: $packageName")
                return openApp(packageName)
            }
        }

        Log.w(TAG, "TikTok not found on device")
        return false
    }

    // Perform back action (Android back button)
    fun performBackAction(): Boolean {
        try {
            Log.d(TAG, "Performing back action")
            val result = performGlobalAction(GLOBAL_ACTION_BACK)
            Log.d(TAG, "Back action executed: ${if (result) "SUCCESS" else "FAILED"}")
            return result
        } catch (e: Exception) {
            Log.e(TAG, "Error performing back action: ${e.message}")
            return false
        }
    }

    // Check if an app is installed
    private fun isAppInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: Exception) {
            false
        }
    }

    // Show termination overlay
    fun showTerminationOverlay(taskType: String, taskId: String): Boolean {
        try {
            if (terminationOverlayView != null) {
                hideTerminationOverlay()
            }

            Log.d(TAG, "Showing termination overlay for task: $taskType ($taskId)")

            // Create overlay view
            terminationOverlayView = createTerminationOverlayView(taskType, taskId)

            // Set up window layout parameters for system overlay
            val layoutParams =
                    WindowManager.LayoutParams().apply {
                        // Use TYPE_ACCESSIBILITY_OVERLAY for system-wide overlay
                        type = WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY

                        // Flags to make it appear over other apps but not interfere with touch
                        // events elsewhere
                        flags =
                                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                                        WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                                        WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH or
                                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                                        WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS

                        format = android.graphics.PixelFormat.TRANSLUCENT
                        width = WindowManager.LayoutParams.WRAP_CONTENT
                        height = WindowManager.LayoutParams.WRAP_CONTENT

                        // Position at top-right corner
                        gravity = Gravity.TOP or Gravity.END
                        x = 20 // Margin from right edge
                        y = 100 // Margin from top (below status bar)

                        // Set window title for debugging
                        title = "TaskTerminationOverlay"
                    }

            // Ensure window manager is available
            if (windowManager == null) {
                windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
            }

            // Add overlay to window manager
            windowManager?.addView(terminationOverlayView, layoutParams)

            Log.d(
                    TAG,
                    "Termination overlay shown successfully at position (${layoutParams.x}, ${layoutParams.y})"
            )
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Error showing termination overlay: ${e.message}", e)
            return false
        }
    }

    // Hide termination overlay
    fun hideTerminationOverlay(): Boolean {
        try {
            terminationOverlayView?.let { view ->
                windowManager?.removeView(view)
                terminationOverlayView = null
                Log.d(TAG, "Termination overlay hidden successfully")
                return true
            }
            Log.d(TAG, "Termination overlay was already hidden")
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Error hiding termination overlay: ${e.message}", e)
            return false
        }
    }

    // Check if termination overlay is currently visible
    fun isTerminationOverlayVisible(): Boolean {
        return terminationOverlayView != null
    }

    // Create termination overlay view
    private fun createTerminationOverlayView(taskType: String, taskId: String): View {
        val context = this

        // Create a container for the overlay
        val container =
                android.widget.LinearLayout(context).apply {
                    orientation = android.widget.LinearLayout.VERTICAL
                    setPadding(16, 16, 16, 16)
                    setBackgroundColor(Color.parseColor("#E53E3E"))

                    // Make it rounded
                    background =
                            android.graphics.drawable.GradientDrawable().apply {
                                cornerRadius = 24f
                                setColor(Color.parseColor("#E53E3E"))
                            }
                }

        // Task type label
        val taskLabel =
                android.widget.TextView(context).apply {
                    text = getTaskTypeText(taskType)
                    setTextColor(Color.WHITE)
                    textSize = 10f
                    gravity = android.view.Gravity.CENTER
                    setPadding(8, 4, 8, 4)
                    setBackgroundColor(Color.parseColor("#80FFFFFF"))
                }

        // Termination button
        val button =
                android.widget.Button(context).apply {
                    text = "إيقاف"
                    setBackgroundColor(Color.WHITE)
                    setTextColor(Color.RED)
                    textSize = 12f
                    setPadding(16, 8, 16, 8)

                    // Make button circular
                    background =
                            android.graphics.drawable.GradientDrawable().apply {
                                cornerRadius = 20f
                                setColor(Color.WHITE)
                            }

                    // Set click listener
                    setOnClickListener {
                        Log.d(TAG, "Termination button clicked for task: $taskType ($taskId)")

                        // Cancel event sequence immediately
                        cancelEventSequence()

                        // Hide overlay
                        hideTerminationOverlay()

                        // Notify Flutter about termination
                        notifyFlutterTermination()
                    }
                }

        // Add views to container
        container.addView(taskLabel)
        container.addView(button)

        return container
    }

    private fun getTaskTypeText(type: String): String {
        return when (type.lowercase()) {
            "like" -> "إعجاب"
            "comment" -> "تعليق"
            "share" -> "مشاركة"
            "favorite" -> "مفضلة"
            "watch" -> "مشاهدة"
            "direct_message" -> "رسالة مباشرة"
            "automation" -> "مهمة تلقائية"
            "social" -> "مهمة اجتماعية"
            "content" -> "مهمة محتوى"
            "analysis" -> "مهمة تحليل"
            else -> "مهمة"
        }
    }

    // Notify Flutter about termination button press
    private fun notifyFlutterTermination() {
        try {
            // This will be handled by the method channel in MainActivity
            val intent = Intent("com.auto.tasks.TERMINATE_TASK")
            sendBroadcast(intent)
            Log.d(TAG, "Termination notification sent to Flutter")
        } catch (e: Exception) {
            Log.e(TAG, "Error notifying Flutter about termination: ${e.message}")
        }
    }
}
