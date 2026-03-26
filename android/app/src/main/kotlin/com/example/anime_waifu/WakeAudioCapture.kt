package com.example.anime_waifu

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.HandlerThread
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.EventChannel

/**
 * Captures 16 kHz mono PCM audio and streams 100 ms chunks (1 600 samples)
 * to the Flutter side via an [EventChannel.EventSink].
 *
 * Each emitted event is a [DoubleArray] (Float64List on the Dart side)
 * containing 1 600 normalised PCM samples in the range [-1, 1].
 */
class WakeAudioCapture(private val context: Context) : EventChannel.StreamHandler {

    companion object {
        const val CHANNEL_NAME = "com.example.anime_waifu/wake_audio"
        private const val SAMPLE_RATE = 16_000
        private const val CHUNK_SAMPLES = 1_600          // 100 ms at 16 kHz
        private const val ENCODING = AudioFormat.ENCODING_PCM_16BIT
        private const val CHANNEL = AudioFormat.CHANNEL_IN_MONO
    }

    private var audioRecord: AudioRecord? = null
    private var recordThread: HandlerThread? = null
    private var recordHandler: Handler? = null
    @Volatile
    private var capturing = false

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        if (events == null) return
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED
        ) {
            events.error("NO_MIC_PERMISSION", "Microphone permission not granted", null)
            return
        }

        val minBuf = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL, ENCODING)
        val bufSize = maxOf(minBuf, CHUNK_SAMPLES * 2) // 2 bytes per 16-bit sample

        val recorder = try {
            AudioRecord(MediaRecorder.AudioSource.MIC, SAMPLE_RATE, CHANNEL, ENCODING, bufSize)
        } catch (e: SecurityException) {
            events.error("SECURITY", "Mic access denied: ${e.message}", null)
            return
        }

        if (recorder.state != AudioRecord.STATE_INITIALIZED) {
            events.error("INIT_FAILED", "AudioRecord failed to initialize", null)
            recorder.release()
            return
        }

        audioRecord = recorder
        capturing = true

        val thread = HandlerThread("WakeAudioCapture").also { it.start() }
        recordThread = thread
        val handler = Handler(thread.looper)
        recordHandler = handler

        recorder.startRecording()

        handler.post(object : Runnable {
            private val buffer = ShortArray(CHUNK_SAMPLES)

            override fun run() {
                if (!capturing) return
                val read = recorder.read(buffer, 0, CHUNK_SAMPLES)
                if (read > 0) {
                    // Normalise Short → Double [-1, 1] for Dart Float64List
                    val doubles = DoubleArray(read) { i -> buffer[i].toDouble() / 32768.0 }
                    val list = doubles.toList()
                    android.os.Handler(android.os.Looper.getMainLooper()).post {
                        try {
                            events.success(list)
                        } catch (_: Exception) {
                            stopCapture()
                        }
                    }
                }
                if (capturing) handler.post(this)
            }
        })
    }

    override fun onCancel(arguments: Any?) {
        stopCapture()
    }

    private fun stopCapture() {
        capturing = false
        try { audioRecord?.stop() } catch (_: Exception) {}
        try { audioRecord?.release() } catch (_: Exception) {}
        audioRecord = null
        recordThread?.quitSafely()
        recordThread = null
        recordHandler = null
    }
}
