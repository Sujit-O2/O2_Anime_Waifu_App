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
import android.view.WindowManager
import android.view.inputmethod.EditorInfo
import android.view.animation.AccelerateInterpolator
import android.view.animation.DecelerateInterpolator
import android.widget.EditText
import android.widget.ImageButton
import android.widget.TextView

object AssistantOverlayController {
    private const val TAG = "AssistantOverlay"
    private const val DEFAULT_AUTO_HIDE_MS = 9000L
    private const val DEDUPE_WINDOW_MS = 700L

    private const val ACTION_OVERLAY_SEND_TEXT = "OVERLAY_SEND_TEXT"
    private const val ACTION_OVERLAY_LISTEN_NOW = "OVERLAY_LISTEN_NOW"

    private val mainHandler = Handler(Looper.getMainLooper())

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var overlayScrimView: View? = null
    private var overlaySheetView: View? = null
    private var statusView: TextView? = null
    private var transcriptView: TextView? = null
    private var inputView: EditText? = null
    private var micButtonView: ImageButton? = null
    private var attached = false
    private var visible = false
    private var animatingOut = false
    private var animationToken = 0
    private var lastStatus = ""
    private var lastTranscript = ""
    private var lastShownAtMs = 0L

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

            val statusText = status.trim().ifBlank { "Assistant" }
            val transcriptText = transcript.trim().ifBlank { "Listening..." }
            statusView?.text = statusText
            transcriptView?.text = transcriptText
            syncMicButtonVisual(statusText, transcriptText)

            val now = System.currentTimeMillis()
            val contentChanged = !(
                statusText == lastStatus &&
                    transcriptText == lastTranscript &&
                    now - lastShownAtMs <= DEDUPE_WINDOW_MS
            )
            lastStatus = statusText
            lastTranscript = transcriptText
            lastShownAtMs = now

            // Animate only when the popup is entering; updates should not restart motion.
            if (!visible || animatingOut) {
                animateIn(appContext)
            } else if (contentChanged) {
                // Keep it smooth on status/transcript refresh without replaying full entrance.
                overlaySheetView?.animate()?.cancel()
            }

            // Keep API compatibility; auto-hide is intentionally disabled.
            @Suppress("UNUSED_VARIABLE")
            val ignoredAutoHide = autoHideMs
            cancelAutoHide()
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
            statusView?.text = status.trim().ifBlank { "Assistant" }
            transcriptView?.text = transcript.trim().ifBlank { "Listening..." }
            syncMicButtonVisual(
                statusView?.text?.toString().orEmpty(),
                transcriptView?.text?.toString().orEmpty()
            )
            lastStatus = statusView?.text?.toString() ?: ""
            lastTranscript = transcriptView?.text?.toString() ?: ""
            lastShownAtMs = System.currentTimeMillis()
            if (!visible || animatingOut) {
                animateIn(appContext)
            }
            // Keep API compatibility; auto-hide is intentionally disabled.
            @Suppress("UNUSED_VARIABLE")
            val ignoredAutoHide = autoHideMs
            cancelAutoHide()
        }
    }

    fun hide() {
        mainHandler.post {
            cancelAutoHide()
            hideInternal()
        }
    }

    private fun ensureAttached(context: Context) {
        if (attached && overlayView != null) return
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            // Target modern Android only to avoid deprecated overlay window types.
            return
        }
        try {
            val wm = context.getSystemService(WindowManager::class.java) ?: return
            val root = LayoutInflater.from(context)
                .inflate(R.layout.assistant_overlay_compact, null)
            val scrim = root.findViewById<View>(R.id.overlayScrim)
            val sheet = root.findViewById<View>(R.id.assistantOverlaySheet)
            val status = root.findViewById<TextView>(R.id.overlayStatus)
            val transcript = root.findViewById<TextView>(R.id.overlayTranscript)
            val input = root.findViewById<EditText>(R.id.overlayInput)
            val micButton = root.findViewById<ImageButton>(R.id.overlayMicButton)
            val sendButton = root.findViewById<ImageButton>(R.id.overlaySendButton)
            val closeButton = root.findViewById<ImageButton>(R.id.overlayCloseButton)

            root.setOnClickListener { hide() }
            sheet.setOnClickListener { /* Consume touches inside sheet. */ }

            input.setOnFocusChangeListener { _, hasFocus ->
                if (hasFocus) {
                    cancelAutoHide()
                } else {
                    cancelAutoHide()
                }
            }
            input.setOnEditorActionListener { _, actionId, event ->
                val isSendAction = actionId == EditorInfo.IME_ACTION_SEND
                val isEnterUp = event?.keyCode == KeyEvent.KEYCODE_ENTER &&
                    event.action == KeyEvent.ACTION_UP
                if (isSendAction || isEnterUp) {
                    submitTypedCommand(context)
                    true
                } else {
                    false
                }
            }

            micButton.setOnClickListener {
                triggerVoiceListen(context)
            }
            sendButton.setOnClickListener {
                submitTypedCommand(context)
            }
            closeButton.setOnClickListener {
                hide()
            }

            val metrics = context.resources.displayMetrics
            val sheetHeight = (metrics.heightPixels * 0.52f).toInt()
            sheet.layoutParams = sheet.layoutParams.apply {
                height = sheetHeight
            }
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
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
            transcriptView = transcript
            inputView = input
            micButtonView = micButton
            scrim.alpha = 0f
            sheet.alpha = 0f
            attached = true
            visible = false
            animatingOut = false
            setMicButtonActive(false)
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
        dispatchServiceAction(
            context = context,
            action = ACTION_OVERLAY_SEND_TEXT,
            text = command
        )
        statusView?.text = "You"
        transcriptView?.text = command
        lastStatus = "You"
        lastTranscript = command
        lastShownAtMs = System.currentTimeMillis()
        inputView?.setText("")
        setMicButtonActive(false)
    }

    private fun triggerVoiceListen(context: Context) {
        dispatchServiceAction(
            context = context,
            action = ACTION_OVERLAY_LISTEN_NOW
        )
        statusView?.text = "Listening"
        transcriptView?.text = "Speak your command now."
        lastStatus = "Listening"
        lastTranscript = "Speak your command now."
        lastShownAtMs = System.currentTimeMillis()
        setMicButtonActive(true)
    }

    private fun dispatchServiceAction(
        context: Context,
        action: String,
        text: String? = null
    ) {
        val intent = Intent(context, AssistantForegroundService::class.java).apply {
            this.action = action
            if (!text.isNullOrBlank()) {
                putExtra("OVERLAY_TEXT", text)
            }
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

    private fun hideInternal() {
        val root = overlayView ?: return
        val sheet = overlaySheetView ?: return
        val scrim = overlayScrimView

        animationToken += 1
        val token = animationToken
        animatingOut = true
        visible = false

        sheet.animate().cancel()
        scrim?.animate()?.cancel()

        val downDistance = (sheet.height.takeIf { it > 0 } ?: dp(root.context, 360)).toFloat()

        scrim?.animate()
            ?.alpha(0f)
            ?.setDuration(170L)
            ?.setInterpolator(AccelerateInterpolator(1.15f))
            ?.start()

        sheet.animate()
            .alpha(0f)
            .translationY(downDistance)
            .setDuration(220L)
            .setInterpolator(AccelerateInterpolator(1.2f))
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
            // View can already be detached by the system.
        } finally {
            clearRefs()
        }
    }

    private fun clearRefs() {
        overlayView = null
        overlayScrimView = null
        overlaySheetView = null
        statusView = null
        transcriptView = null
        inputView = null
        micButtonView = null
        windowManager = null
        attached = false
        visible = false
        animatingOut = false
        animationToken = 0
        lastStatus = ""
        lastTranscript = ""
        lastShownAtMs = 0L
    }

    private fun cancelAutoHide() {
        // Auto hide disabled: popup stays until user dismisses (outside tap or close button).
    }

    private fun dp(context: Context, value: Int): Int {
        return (value * context.resources.displayMetrics.density).toInt()
    }

    private fun syncMicButtonVisual(status: String, transcript: String) {
        val active = status.equals("Listening", ignoreCase = true) ||
            transcript.contains("speak your command", ignoreCase = true)
        setMicButtonActive(active)
    }

    private fun setMicButtonActive(active: Boolean) {
        val button = micButtonView ?: return
        button.alpha = if (active) 1.0f else 0.88f
        button.setColorFilter(if (active) 0xFFFF3D5A.toInt() else 0xFFFF6A6A.toInt())
        button.isSelected = active
    }

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

            val startY = (sheet.height.takeIf { it > 0 } ?: dp(context, 360)).toFloat()
            sheet.translationY = startY
            sheet.alpha = 0f
            scrim?.alpha = 0f

            scrim?.animate()
                ?.alpha(1f)
                ?.setDuration(230L)
                ?.setInterpolator(DecelerateInterpolator(1.3f))
                ?.start()

            sheet.animate()
                .alpha(1f)
                .translationY(0f)
                .setDuration(320L)
                .setInterpolator(DecelerateInterpolator(1.55f))
                .withEndAction {
                    if (token != animationToken) return@withEndAction
                    visible = true
                    animatingOut = false
                }
                .start()
        }
    }
}
