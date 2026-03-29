package com.example.anime_waifu

import ai.onnxruntime.*
import android.content.Context
import android.util.Log
import io.flutter.FlutterInjector
import java.nio.FloatBuffer
import java.nio.LongBuffer

/**
 * OnnxInferenceHelper — Loads and runs ONNX models for:
 *   1. Whisper (speech → text)        — whisper.onnx
 *   2. DistilBERT (text → sentiment)  — distilbert.onnx
 *
 * Models must be placed in: app/src/main/assets/
 *
 * Audio input MUST be:
 *   ✅ WAV, 16kHz, Mono, Float32
 *
 * Flow:  Mic → Audio → Whisper → text → DistilBERT → sentiment (😄/😡)
 */
class OnnxInferenceHelper(private val context: Context) {

    companion object {
        private const val TAG = "OnnxInference"
    }

    private var ortEnv: OrtEnvironment? = null
    private var whisperSession: OrtSession? = null
    private var sentimentSession: OrtSession? = null

    // ─── INITIALIZATION ──────────────────────────────────────────────

    fun initialize(): Boolean {
        return try {
            ortEnv = OrtEnvironment.getEnvironment()
            Log.d(TAG, "✅ ONNX Runtime environment created")
            true
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to create ONNX environment: ${e.message}")
            false
        }
    }

    /**
     * Load Whisper model from assets.
     * File: assets/whisper.onnx
     */
    fun loadWhisperModel(): Boolean {
        return try {
            val env = ortEnv ?: return false
            val assetKey = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset("assets/wakeword/model_emo/encoder_model.onnx")
            val modelBytes = context.assets.open(assetKey).readBytes()
            val opts = OrtSession.SessionOptions()
            opts.setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT)
            // Use NNAPI for hardware acceleration on Android
            try {
                opts.addNnapi()
                Log.d(TAG, "✅ NNAPI acceleration enabled")
            } catch (e: Exception) {
                Log.w(TAG, "⚠️ NNAPI not available, using CPU")
            }
            whisperSession = env.createSession(modelBytes, opts)
            Log.d(TAG, "✅ Whisper model loaded (${modelBytes.size / 1024}KB)")
            true
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to load Whisper: ${e.message}")
            false
        }
    }

    /**
     * Load DistilBERT sentiment model from assets.
     * File: assets/distilbert.onnx
     */
    fun loadSentimentModel(): Boolean {
        return try {
            val env = ortEnv ?: return false
            val assetKey = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset("assets/wakeword/model_emo/model.onnx")
            val modelBytes = context.assets.open(assetKey).readBytes()
            val opts = OrtSession.SessionOptions()
            opts.setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT)
            sentimentSession = env.createSession(modelBytes, opts)
            Log.d(TAG, "✅ Sentiment model loaded (${modelBytes.size / 1024}KB)")
            true
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to load Sentiment model: ${e.message}")
            false
        }
    }

    // ─── WHISPER INFERENCE ──────────────────────────────────────────

    /**
     * Run Whisper inference on raw audio samples.
     *
     * @param audioSamples Float array of PCM audio (16kHz, mono, float32)
     * @return Transcribed text, or null on failure
     */
    fun runWhisperInference(audioSamples: FloatArray): String? {
        val session = whisperSession ?: run {
            Log.e(TAG, "❌ Whisper session not loaded")
            return null
        }
        val env = ortEnv ?: return null

        return try {
            // Create input tensor: shape [1, num_samples]
            val shape = longArrayOf(1, audioSamples.size.toLong())
            val buffer = FloatBuffer.wrap(audioSamples)
            val inputTensor = OnnxTensor.createTensor(env, buffer, shape)

            // Run inference
            val inputName = session.inputNames.first()
            val results = session.run(mapOf(inputName to inputTensor))

            // Extract output (depends on specific Whisper ONNX format)
            val output = results.get(0)
            val result = when (val value = output.value) {
                is Array<*> -> {
                    // Token IDs → would need decoder
                    // For now return raw output info
                    "Whisper output: ${value.size} tokens"
                }
                is String -> value
                else -> "Inference complete (type: ${value?.javaClass?.simpleName})"
            }

            inputTensor.close()
            results.close()
            Log.d(TAG, "✅ Whisper inference done: $result")
            result
        } catch (e: Exception) {
            Log.e(TAG, "❌ Whisper inference failed: ${e.message}")
            null
        }
    }

    // ─── SENTIMENT INFERENCE ─────────────────────────────────────────

    /**
     * Run sentiment analysis on tokenized text.
     *
     * @param inputIds Token IDs from tokenizer
     * @param attentionMask Attention mask (1 for real tokens, 0 for padding)
     * @return Pair of (label, confidence) e.g. ("POSITIVE", 0.95)
     */
    fun runSentimentInference(inputIds: LongArray, attentionMask: LongArray): Pair<String, Float>? {
        val session = sentimentSession ?: run {
            Log.e(TAG, "❌ Sentiment session not loaded")
            return null
        }
        val env = ortEnv ?: return null

        return try {
            val seqLen = inputIds.size.toLong()

            // Create input tensors
            val idsTensor = OnnxTensor.createTensor(
                env,
                LongBuffer.wrap(inputIds),
                longArrayOf(1, seqLen)
            )
            val maskTensor = OnnxTensor.createTensor(
                env,
                LongBuffer.wrap(attentionMask),
                longArrayOf(1, seqLen)
            )

            // Run inference
            val inputs = mapOf(
                "input_ids" to idsTensor,
                "attention_mask" to maskTensor
            )
            val results = session.run(inputs)

            // Parse output logits [1, 2] → [negative, positive]
            val output = results.get(0)
            val logits = (output.value as Array<FloatArray>)[0]

            // Softmax to get probabilities
            val maxLogit = logits.max()
            val expLogits = logits.map { Math.exp((it - maxLogit).toDouble()).toFloat() }
            val sum = expLogits.sum()
            val probs = expLogits.map { it / sum }

            val label = if (probs[1] > probs[0]) "POSITIVE" else "NEGATIVE"
            val confidence = maxOf(probs[0], probs[1])

            idsTensor.close()
            maskTensor.close()
            results.close()

            Log.d(TAG, "✅ Sentiment: $label (${(confidence * 100).toInt()}%)")
            Pair(label, confidence)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Sentiment inference failed: ${e.message}")
            null
        }
    }

    /**
     * Simple sentiment detection from raw text.
     * Uses basic tokenization (for production, use proper WordPiece tokenizer).
     */
    fun detectSentiment(text: String): Pair<String, Float>? {
        // Basic placeholder tokenization
        // In production, use a proper WordPiece tokenizer
        val maxLen = 128
        val words = text.lowercase().split(" ").take(maxLen)

        // Simple hash-based pseudo-tokenization (placeholder)
        val inputIds = LongArray(maxLen) { i ->
            if (i == 0) 101L // [CLS]
            else if (i <= words.size) (words[i - 1].hashCode().toLong() and 0x7FFFL) + 1000L
            else if (i == words.size + 1) 102L // [SEP]
            else 0L // [PAD]
        }
        val attentionMask = LongArray(maxLen) { i ->
            if (i <= words.size + 1) 1L else 0L
        }

        return runSentimentInference(inputIds, attentionMask)
    }

    // ─── CLEANUP ─────────────────────────────────────────────────────

    fun close() {
        try {
            whisperSession?.close()
            sentimentSession?.close()
            ortEnv?.close()
            Log.d(TAG, "✅ ONNX sessions closed")
        } catch (e: Exception) {
            Log.e(TAG, "Error closing ONNX: ${e.message}")
        }
    }

    fun isWhisperLoaded(): Boolean = whisperSession != null
    fun isSentimentLoaded(): Boolean = sentimentSession != null
}
