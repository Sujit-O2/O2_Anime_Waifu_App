package com.example.anime_waifu

import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.KeyEvent
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.view.animation.AccelerateDecelerateInterpolator
import android.view.animation.DecelerateInterpolator
import android.view.animation.OvershootInterpolator
import android.view.inputmethod.EditorInfo
import android.widget.EditText
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.TextView

object AssistantOverlayController {
    private const val TAG = "AssistantOverlay"
    private const val DEFAULT_AUTO_HIDE_MS = 0L
    private const val DEDUPE_WINDOW_MS = 700L

    private const val ACTION_OVERLAY_SEND_TEXT = "OVERLAY_SEND_TEXT"
    private const val ACTION_OVERLAY_LISTEN_NOW = "OVERLAY_LISTEN_NOW"
    private const val ACTION_OVERLAY_CANCEL_SESSION = "OVERLAY_CANCEL_SESSION"

    private val mainHandler = Handler(Looper.getMainLooper())

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var overlayScrimView: View? = null
    private var overlaySheetView: View? = null
    private var statusView: TextView? = null
    private var overlayTranscriptScroll: android.widget.ScrollView? = null
    private var overlayChatList: LinearLayout? = null
    private var inputView: EditText? = null
    private var micButtonView: ImageButton? = null
    private var statusDotView: View? = null
    private var waveformRowView: LinearLayout? = null

    private var attached = false
    private var visible = false
    private var animatingOut = false
    private var animationToken = 0
    private var lastStatus = ""
    private var lastTranscript = ""
    private var lastShownAtMs = 0L

    private val sessionHistory = mutableListOf<Pair<String, String>>()

    // Pulse animation for status dot
    private var dotPulseRunnable: Runnable? = null
    private var hideRunnable: Runnable? = null

    fun canDrawOverlays(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(context)
        } else {
            true
        }
    }

    fun isShowing(): Boolean {
        return attached && overlayView != null && (visible || animatingOut)
    }

    fun show(
        context: Context,
        status: String,
        transcript: String,
        autoHideMs: Long = DEFAULT_AUTO_HIDE_MS
    ) {
        val appContext = context.applicationContext
        mainHandler.post {
            if (!canDrawOverlays(appContext)) return@post
            ensureAttached(appContext)
            if (!attached || overlayView == null) return@post

            val statusText = status.trim().ifBlank { "002" }
            val transcriptText = transcript.trim().ifBlank { "Say a wake word or tap the mic..." }
            
            // Record to history if it's a completed message
            if (!statusText.equals("Listening", ignoreCase = true) && 
                !statusText.equals("Processing", ignoreCase = true) &&
                !transcriptText.contains("Say a wake word", ignoreCase = true)) {
                
                // If the last history item was a temporary processing message, replace it
                if (sessionHistory.isNotEmpty() && sessionHistory.last().first.equals("Processing", ignoreCase = true)) {
                    sessionHistory.removeLast()
                }
                
                if (sessionHistory.isEmpty() || sessionHistory.last().second != transcriptText) {
                    sessionHistory.add(statusText to transcriptText)
                }
            }

            statusView?.text = statusText
            updateChatList(appContext, statusText, transcriptText)
            syncListeningVisuals(statusText, transcriptText)

            val now = System.currentTimeMillis()
            val contentChanged = !(
                statusText == lastStatus &&
                    transcriptText == lastTranscript &&
                    now - lastShownAtMs <= DEDUPE_WINDOW_MS
            )
            lastStatus = statusText
            lastTranscript = transcriptText
            lastShownAtMs = now

            if (!visible || animatingOut) {
                animateIn(appContext)
            }

            scheduleAutoHide(autoHideMs, appContext)
        }
    }

    fun update(
        context: Context,
        status: String,
        transcript: String,
        autoHideMs: Long = DEFAULT_AUTO_HIDE_MS
    ) {
        val appContext = context.applicationContext
        mainHandler.post {
            if (!attached || overlayView == null) {
                show(appContext, status, transcript, autoHideMs)
                return@post
            }
            val statusText = status.trim().ifBlank { "002" }
            val transcriptText = transcript.trim().ifBlank { "Say a wake word or tap the mic..." }
            
            // Record to history if it's a completed message
            if (!statusText.equals("Listening", ignoreCase = true) && 
                !statusText.equals("Processing", ignoreCase = true) &&
                !statusText.startsWith("Working on", ignoreCase = true) &&
                !transcriptText.contains("Say a wake word", ignoreCase = true)) {
                
                // If the last history item was a temporary processing message, replace it
                if (sessionHistory.isNotEmpty() && (
                    sessionHistory.last().first.equals("Processing", ignoreCase = true) ||
                    sessionHistory.last().first.startsWith("Working on", ignoreCase = true)
                )) {
                    sessionHistory.removeLast()
                }
                
                if (sessionHistory.isEmpty() || sessionHistory.last().second != transcriptText) {
                    sessionHistory.add(statusText to transcriptText)
                }
            }

            statusView?.text = statusText
            updateChatList(appContext, statusText, transcriptText)
            syncListeningVisuals(statusText, transcriptText)
            lastStatus = statusText
            lastTranscript = transcriptText
            lastShownAtMs = System.currentTimeMillis()
            if (!visible || animatingOut) {
                animateIn(appContext)
            }
            scheduleAutoHide(autoHideMs, appContext)
        }
    }

    private fun updateChatList(context: Context, currentStatus: String, currentTranscript: String) {
        val list = overlayChatList ?: return
        val scroll = overlayTranscriptScroll ?: return
        list.removeAllViews()
        val inflater = LayoutInflater.from(context)

        for (item in sessionHistory) {
            val isUser = item.first.equals("You", ignoreCase = true)
            val layoutId = if (isUser) R.layout.overlay_chat_bubble_user else R.layout.overlay_chat_bubble_assistant
            val bubble = inflater.inflate(layoutId, list, false)
            bubble.findViewById<TextView>(R.id.chatBubbleText).text = item.second
            list.addView(bubble)
        }

        if (currentStatus.equals("Listening", ignoreCase = true) && currentTranscript.isNotBlank()) {
            val bubble = inflater.inflate(R.layout.overlay_chat_bubble_assistant, list, false)
            val tv = bubble.findViewById<TextView>(R.id.chatBubbleText)
            tv.text = currentTranscript
            tv.alpha = 0.7f
            list.addView(bubble)
        }

        scroll.post {
            scroll.fullScroll(View.FOCUS_DOWN)
        }
    }

    fun hide(context: Context? = null) {
        mainHandler.post {
            stopDotPulse()
            cancelAutoHide()
            hideInternal(context)
        }
    }

    private fun ensureAttached(context: Context) {
        if (attached && overlayView != null) return
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        try {
            val wm = context.getSystemService(WindowManager::class.java) ?: return
            val root = LayoutInflater.from(context)
                .inflate(R.layout.assistant_overlay_compact, null)

            val scrim = root.findViewById<View>(R.id.overlayScrim)
            val sheet = root.findViewById<View>(R.id.assistantOverlaySheet)
            val status = root.findViewById<TextView>(R.id.overlayStatus)
            val transcriptScroll = root.findViewById<android.widget.ScrollView>(R.id.overlayTranscriptScroll)
            val chatList = root.findViewById<LinearLayout>(R.id.overlayChatList)
            val input = root.findViewById<EditText>(R.id.overlayInput)
            val micButton = root.findViewById<ImageButton>(R.id.overlayMicButton)
            val sendButton = root.findViewById<ImageButton>(R.id.overlaySendButton)
            val closeButton = root.findViewById<ImageButton>(R.id.overlayCloseButton)
            val statusDot = root.findViewById<View>(R.id.overlayStatusDot)
            val waveRow = root.findViewById<LinearLayout>(R.id.overlayWaveformRow)
            val dragHandle = root.findViewById<View>(R.id.overlayDragHandle)

            var initialY = 0f
            var initialHeight = 0
            dragHandle.setOnTouchListener { v, event ->
                when (event.action) {
                    android.view.MotionEvent.ACTION_DOWN -> {
                        initialY = event.rawY
                        initialHeight = transcriptScroll.height
                        true
                    }
                    android.view.MotionEvent.ACTION_MOVE -> {
                        val deltaY = initialY - event.rawY
                        var newHeight = (initialHeight + deltaY).toInt()
                        val minH = dpF(context, 140).toInt()
                        val maxH = dpF(context, 600).toInt()
                        newHeight = newHeight.coerceIn(minH, maxH)
                        
                        val lp = transcriptScroll.layoutParams as ViewGroup.LayoutParams
                        lp.height = newHeight
                        transcriptScroll.layoutParams = lp
                        true
                    }
                    android.view.MotionEvent.ACTION_UP, android.view.MotionEvent.ACTION_CANCEL -> {
                        v.performClick()
                        true
                    }
                    else -> false
                }
            }

            root.setOnClickListener { hide(context) }
            sheet.setOnClickListener { /* Consume touches inside sheet */ }

            input.setOnEditorActionListener { _, actionId, event ->
                val isSend = actionId == EditorInfo.IME_ACTION_SEND
                val isEnterUp = event?.keyCode == KeyEvent.KEYCODE_ENTER &&
                    event.action == KeyEvent.ACTION_UP
                if (isSend || isEnterUp) {
                    submitTypedCommand(context)
                    true
                } else {
                    false
                }
            }

            micButton.setOnClickListener { triggerVoiceListen(context) }
            sendButton.setOnClickListener { submitTypedCommand(context) }
            closeButton.setOnClickListener { hide(context) }

            // ✅ FIX: Drop FLAG_LAYOUT_IN_SCREEN so the system honours SOFT_INPUT_ADJUST_RESIZE
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
                y = 0
                softInputMode = WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE
            }

            wm.addView(root, params)
            windowManager = wm
            overlayView = root
            overlayScrimView = scrim
            overlaySheetView = sheet
            statusView = status
            overlayTranscriptScroll = transcriptScroll
            overlayChatList = chatList
            inputView = input
            micButtonView = micButton
            statusDotView = statusDot
            waveformRowView = waveRow

            // ✅ FIX: Keyboard listener — shift popup up so input stays above keyboard
            root.viewTreeObserver.addOnGlobalLayoutListener {
                val visibleRect = android.graphics.Rect()
                root.getWindowVisibleDisplayFrame(visibleRect)
                val screenHeight = root.rootView.height
                val keyboardHeight = screenHeight - visibleRect.bottom
                val newY = if (keyboardHeight > screenHeight * 0.15f) keyboardHeight else 0
                if (params.y != newY) {
                    params.y = newY
                    try { wm.updateViewLayout(root, params) } catch (_: Exception) {}
                }
            }

            scrim.alpha = 0f
            sheet.alpha = 0f
            sheet.translationY = dpF(context, 500)
            sheet.scaleX = 0.96f

            // Set initial height to 40% of screen height
            val metrics = context.resources.displayMetrics
            val lp = transcriptScroll.layoutParams as ViewGroup.LayoutParams
            lp.height = (metrics.heightPixels * 0.4f).toInt()
            transcriptScroll.layoutParams = lp

            attached = true
            visible = false
            animatingOut = false
        } catch (se: SecurityException) {
            Log.w(TAG, "Overlay permission denied: ${se.message}")
            clearRefs()
        } catch (t: Throwable) {
            Log.w(TAG, "Overlay attach failed: ${t.message}")
            clearRefs()
        }
    }

    private fun submitTypedCommand(context: Context) {
        val command = inputView?.text?.toString()?.trim().orEmpty()
        if (command.isBlank()) return
        // ✅ FIX: persist to sessionHistory so the bubble survives future updates
        sessionHistory.add("You" to command)
        dispatchServiceAction(context, ACTION_OVERLAY_SEND_TEXT, text = command)
        statusView?.text = "You"
        updateChatList(context, "You", command)
        lastStatus = "You"
        lastTranscript = command
        lastShownAtMs = System.currentTimeMillis()
        inputView?.setText("")
        syncListeningVisuals("You", command)
    }

    private fun triggerVoiceListen(context: Context) {
        dispatchServiceAction(context, ACTION_OVERLAY_LISTEN_NOW)
        statusView?.text = "Listening"
        updateChatList(context, "Listening", "Speak your command now.")
        lastStatus = "Listening"
        lastTranscript = "Speak your command now."
        lastShownAtMs = System.currentTimeMillis()
        syncListeningVisuals("Listening", "Speak your command now.")
    }

    private fun dispatchServiceAction(context: Context, action: String, text: String? = null) {
        val intent = Intent(context, AssistantForegroundService::class.java).apply {
            this.action = action
            if (!text.isNullOrBlank()) putExtra("OVERLAY_TEXT", text)
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        } catch (t: Throwable) {
            Log.w(TAG, "Overlay action dispatch failed ($action): ${t.message}")
        }
    }

    /** Show/hide waveform and pulse dot based on listening state. */
    private fun syncListeningVisuals(status: String, transcript: String) {
        val isListening = status.equals("Listening", ignoreCase = true) ||
            transcript.contains("speak your command", ignoreCase = true) ||
            transcript.contains("listening", ignoreCase = true)

        val waveRow = waveformRowView
        if (waveRow != null) {
            if (isListening) {
                waveRow.visibility = View.VISIBLE
                animateWaveform(waveRow)
            } else {
                waveRow.visibility = View.GONE
                waveRow.animate().cancel()
            }
        }

        val dot = statusDotView ?: return
        if (isListening) {
            startDotPulse(dot)
        } else {
            stopDotPulse()
            dot.animate().cancel()
            dot.alpha = 1f
            dot.scaleX = 1f
            dot.scaleY = 1f
        }
    }

    private fun animateWaveform(row: LinearLayout) {
        // Animate each bar child with a different delay/amplitude for a live waveform feel
        val count = row.childCount
        for (i in 0 until count) {
            val bar = row.getChildAt(i) as? View ?: continue
            val delay = (i * 80L)
            val targetScale = floatArrayOf(1.8f, 2.4f, 1.3f, 2.8f, 1.6f, 1.0f)
            val scale = if (i < targetScale.size) targetScale[i] else 1.5f
            bar.animate()
                .scaleY(scale)
                .setDuration(380L)
                .setStartDelay(delay)
                .setInterpolator(AccelerateDecelerateInterpolator())
                .withEndAction {
                    bar.animate()
                        .scaleY(1f)
                        .setDuration(380L)
                        .setInterpolator(AccelerateDecelerateInterpolator())
                        .start()
                }
                .start()
        }
    }

    private fun startDotPulse(dot: View) {
        stopDotPulse()
        val r = object : Runnable {
            override fun run() {
                if (!attached) return
                dot.animate()
                    .scaleX(1.55f)
                    .scaleY(1.55f)
                    .alpha(0.4f)
                    .setDuration(600L)
                    .setInterpolator(AccelerateDecelerateInterpolator())
                    .withEndAction {
                        dot.animate()
                            .scaleX(1f)
                            .scaleY(1f)
                            .alpha(1f)
                            .setDuration(600L)
                            .setInterpolator(AccelerateDecelerateInterpolator())
                            .start()
                    }
                    .start()
                mainHandler.postDelayed(this, 1200L)
            }
        }
        dotPulseRunnable = r
        mainHandler.post(r)
    }

    private fun stopDotPulse() {
        dotPulseRunnable?.let { mainHandler.removeCallbacks(it) }
        dotPulseRunnable = null
    }


    // ── Animation ──────────────────────────────────────────────────────────────

    private fun animateIn(context: Context) {
        val root = overlayView ?: return
        val sheet = overlaySheetView ?: return
        val scrim = overlayScrimView

        animationToken += 1
        val token = animationToken
        animatingOut = false

        sheet.animate().cancel()
        scrim?.animate()?.cancel()

        root.post {
            if (token != animationToken || overlayView == null) return@post

            // Start from well below and scaled down
            val startY = dpF(context, 480)
            sheet.translationY = startY
            sheet.alpha = 0f
            sheet.scaleX = 0.85f
            sheet.scaleY = 0.88f
            scrim?.alpha = 0f

            // Keep scrim transparent so the screen doesn't dim
            scrim?.animate()
                ?.alpha(0f)
                ?.setDuration(260L)
                ?.setInterpolator(DecelerateInterpolator(1.4f))
                ?.start()

            // Sheet slides up with satisfying bouncy spring catch
            sheet.animate()
                .alpha(1f)
                .translationY(0f)
                .scaleX(1f)
                .scaleY(1f)
                .setDuration(460L)
                .setInterpolator(OvershootInterpolator(1.35f))
                .withEndAction {
                    if (token != animationToken) return@withEndAction
                    visible = true
                    animatingOut = false
                    // Kick off status dot pulse after slide completes
                    val dot = statusDotView
                    val s = statusView?.text?.toString() ?: ""
                    if (dot != null) {
                        val isListening = s.equals("Listening", ignoreCase = true)
                        if (isListening) startDotPulse(dot)
                    }
                }
                .start()
        }
    }

    private fun hideInternal(context: Context?) {
        val root = overlayView ?: return
        val sheet = overlaySheetView ?: return
        val scrim = overlayScrimView

        animationToken += 1
        val token = animationToken
        animatingOut = true
        visible = false

        sessionHistory.clear()
        
        if (context != null) {
            dispatchServiceAction(context, ACTION_OVERLAY_CANCEL_SESSION)
        }

        sheet.animate().cancel()
        scrim?.animate()?.cancel()

        val downDistance = dpF(sheet.context, 380)

        scrim?.animate()
            ?.alpha(0f)
            ?.setDuration(200L)
            ?.setInterpolator(AccelerateDecelerateInterpolator())
            ?.start()

        sheet.animate()
            .alpha(0f)
            .translationY(downDistance)
            .scaleX(0.96f)
            .scaleY(0.97f)
            .setDuration(260L)
            .setInterpolator(AccelerateDecelerateInterpolator())
            .withEndAction {
                if (token != animationToken) return@withEndAction
                removeViewNow(root)
            }
            .start()
    }

    private fun removeViewNow(view: View) {
        try {
            windowManager?.removeView(view)
        } catch (_: Exception) {
        } finally {
            clearRefs()
        }
    }

    private fun clearRefs() {
        stopDotPulse()
        overlayView = null
        overlayScrimView = null
        overlaySheetView = null
        statusView = null
        overlayTranscriptScroll = null
        overlayChatList = null
        inputView = null
        micButtonView = null
        statusDotView = null
        waveformRowView = null
        windowManager = null
        attached = false
        visible = false
        animatingOut = false
        animationToken = 0
        lastStatus = ""
        lastTranscript = ""
        lastShownAtMs = 0L
        sessionHistory.clear()
    }

    private fun cancelAutoHide() {
        hideRunnable?.let { mainHandler.removeCallbacks(it) }
        hideRunnable = null
    }

    private fun scheduleAutoHide(autoHideMs: Long, context: Context) {
        cancelAutoHide()
        if (autoHideMs > 0) {
            val r = Runnable { hideInternal(context) }
            hideRunnable = r
            mainHandler.postDelayed(r, autoHideMs)
        }
    }

    private fun dp(context: Context, value: Int): Int =
        (value * context.resources.displayMetrics.density).toInt()

    private fun dpF(context: Context, value: Int): Float =
        value * context.resources.displayMetrics.density
}
