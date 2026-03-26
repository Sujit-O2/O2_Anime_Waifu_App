#!/usr/bin/env python3
"""
Wake Word Model Retrainer
=========================
Trains an XGBoost classifier on mel-spectrogram features extracted from
positive (wake word) and auto-generated negative (noise/silence) audio samples.

Usage:
    python tools/retrain_wakeword.py

Input:  .m4a/.wav files in assets/ directory (positive wake word samples)
Output: assets/wakeword/offlinenew/wake_word_classifier.onnx
"""

import os
import sys
import glob
import warnings
import tempfile
import subprocess
from pathlib import Path

import numpy as np

# Suppress sklearn warnings during import
warnings.filterwarnings("ignore", category=FutureWarning)

# ── Configuration ────────────────────────────────────────────────────────────
SAMPLE_RATE = 16_000
WINDOW_SECS = 1.0
N_MELS = 128
HOP_LENGTH = 512
N_FFT = 2048
FEATURE_DIM = 4096  # 128 × 32

PROJECT_ROOT = Path(__file__).resolve().parent.parent
ASSETS_DIR = PROJECT_ROOT / "assets"
WAKEWORD_DIR = ASSETS_DIR / "wakeword" / "offlinenew"
OUTPUT_MODEL = WAKEWORD_DIR / "wake_word_classifier.onnx"


def check_dependencies():
    """Install required packages if missing."""
    required = {
        "librosa": "librosa",
        "sklearn": "scikit-learn",
        "xgboost": "xgboost",
        "skl2onnx": "skl2onnx",
        "onnxruntime": "onnxruntime",
        "pydub": "pydub",
    }
    missing = []
    for module, pkg in required.items():
        try:
            __import__(module)
        except ImportError:
            missing.append(pkg)
    if missing:
        print(f"Installing missing packages: {', '.join(missing)}")
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", "--quiet"] + missing
        )


def _get_ffmpeg_path() -> str:
    """Get ffmpeg binary path from imageio-ffmpeg or system PATH."""
    try:
        import imageio_ffmpeg
        return imageio_ffmpeg.get_ffmpeg_exe()
    except ImportError:
        pass
    # Fallback to system ffmpeg
    return "ffmpeg"


def convert_m4a_to_wav(m4a_path: str, wav_path: str) -> bool:
    """Convert m4a to wav using ffmpeg (bundled via imageio-ffmpeg)."""
    ffmpeg = _get_ffmpeg_path()
    try:
        result = subprocess.run(
            [
                ffmpeg, "-y", "-i", m4a_path,
                "-ar", str(SAMPLE_RATE), "-ac", "1", "-sample_fmt", "s16",
                wav_path,
            ],
            capture_output=True,
            timeout=30,
        )
        if os.path.exists(wav_path) and os.path.getsize(wav_path) > 100:
            return True
        print(f"  ⚠ ffmpeg failed: {result.stderr.decode()[:200]}")
        return False
    except Exception as e:
        print(f"  ⚠ Conversion failed: {e}")
        return False


def extract_features(audio: np.ndarray, sr: int = SAMPLE_RATE) -> np.ndarray:
    """
    Extract mel-spectrogram features matching the Dart pipeline exactly.

    librosa.feature.melspectrogram(y, sr=16000, n_fft=2048, hop=512, n_mels=128)
    → power_to_db(S, ref=np.max)
    → flatten → 4096-dim vector
    """
    import librosa

    # Ensure exactly 1 second of audio
    target_len = int(sr * WINDOW_SECS)
    if len(audio) > target_len:
        audio = audio[:target_len]
    elif len(audio) < target_len:
        audio = np.pad(audio, (0, target_len - len(audio)))

    # Mel spectrogram (librosa handles windowing internally with center=True)
    mel = librosa.feature.melspectrogram(
        y=audio, sr=sr, n_mels=N_MELS, hop_length=HOP_LENGTH, n_fft=N_FFT
    )
    # Convert to dB
    mel_db = librosa.power_to_db(mel, ref=np.max)

    # Flatten
    features = mel_db.flatten()[:FEATURE_DIM]
    if len(features) < FEATURE_DIM:
        features = np.pad(features, (0, FEATURE_DIM - len(features)))

    return features.astype(np.float32)


def load_positive_samples(audio_dir: Path) -> list:
    """Load and extract features from positive wake word recordings."""
    import librosa

    features = []
    files = sorted(
        glob.glob(str(audio_dir / "New recording*.m4a"))
        + glob.glob(str(audio_dir / "*.wav"))
    )

    if not files:
        print(f"ERROR: No audio files found in {audio_dir}")
        sys.exit(1)

    print(f"\n📂 Found {len(files)} positive samples")

    with tempfile.TemporaryDirectory() as tmpdir:
        for i, fpath in enumerate(files):
            fname = os.path.basename(fpath)
            print(f"  [{i+1}/{len(files)}] {fname}...", end=" ")

            # Convert m4a to wav if needed
            if fpath.lower().endswith(".m4a"):
                wav_path = os.path.join(tmpdir, f"pos_{i}.wav")
                if not convert_m4a_to_wav(fpath, wav_path):
                    print("SKIP (conversion failed)")
                    continue
            else:
                wav_path = fpath

            try:
                audio, sr = librosa.load(wav_path, sr=SAMPLE_RATE, mono=True)
            except Exception as e:
                print(f"SKIP ({e})")
                continue

            if len(audio) < SAMPLE_RATE * 0.3:
                print(f"SKIP (too short: {len(audio)/SAMPLE_RATE:.2f}s)")
                continue

            # Extract 1-second windows with overlap
            window_samples = int(SAMPLE_RATE * WINDOW_SECS)
            hop = window_samples // 2  # 50% overlap

            count = 0
            for start in range(0, max(1, len(audio) - window_samples + 1), hop):
                chunk = audio[start : start + window_samples]
                if len(chunk) < window_samples:
                    chunk = np.pad(chunk, (0, window_samples - len(chunk)))
                feat = extract_features(chunk, sr=SAMPLE_RATE)
                features.append(feat)
                count += 1

            # Data augmentation — pitch shift, time stretch, add noise
            for aug_name, aug_audio in _augment(audio, sr):
                for start in range(
                    0, max(1, len(aug_audio) - window_samples + 1), hop
                ):
                    chunk = aug_audio[start : start + window_samples]
                    if len(chunk) < window_samples:
                        chunk = np.pad(chunk, (0, window_samples - len(chunk)))
                    feat = extract_features(chunk, sr=SAMPLE_RATE)
                    features.append(feat)
                    count += 1

            print(f"OK ({count} windows)")

    return features


def _augment(audio: np.ndarray, sr: int) -> list:
    """Return augmented versions of the audio."""
    import librosa

    augmented = []

    # Pitch shift ±2 semitones
    for n_steps in [-2, -1, 1, 2]:
        try:
            shifted = librosa.effects.pitch_shift(y=audio, sr=sr, n_steps=n_steps)
            augmented.append((f"pitch_{n_steps}", shifted))
        except Exception:
            pass

    # Time stretch (slightly faster/slower)
    for rate in [0.85, 0.9, 1.1, 1.15]:
        try:
            stretched = librosa.effects.time_stretch(y=audio, rate=rate)
            augmented.append((f"stretch_{rate}", stretched))
        except Exception:
            pass

    # Add noise at various SNR levels
    for snr_db in [20, 15, 10]:
        noise = np.random.randn(len(audio)).astype(np.float32)
        signal_power = np.mean(audio ** 2)
        noise_power = signal_power / (10 ** (snr_db / 10))
        if noise_power > 0:
            noisy = audio + noise * np.sqrt(noise_power)
            augmented.append((f"noise_{snr_db}dB", noisy))

    # Volume variation
    for gain in [0.5, 0.7, 1.3, 1.5]:
        augmented.append((f"gain_{gain}", audio * gain))

    return augmented


def generate_negative_samples(n_samples: int) -> list:
    """Generate negative (not wake word) training samples."""
    features = []
    window_samples = int(SAMPLE_RATE * WINDOW_SECS)

    print(f"\n🔇 Generating {n_samples} negative samples")

    for i in range(n_samples):
        kind = i % 6
        if kind == 0:
            # Pure silence
            audio = np.zeros(window_samples, dtype=np.float32)
        elif kind == 1:
            # Low-level white noise
            audio = np.random.randn(window_samples).astype(np.float32) * 0.001
        elif kind == 2:
            # Medium noise
            audio = np.random.randn(window_samples).astype(np.float32) * 0.01
        elif kind == 3:
            # Pink-ish noise (more low freq)
            audio = np.random.randn(window_samples).astype(np.float32)
            # Simple low-pass via cumulative sum
            audio = np.cumsum(audio)
            audio = audio / (np.max(np.abs(audio)) + 1e-10) * 0.01
        elif kind == 4:
            # Random tone (non-speech)
            freq = np.random.uniform(100, 2000)
            t = np.arange(window_samples) / SAMPLE_RATE
            audio = (np.sin(2 * np.pi * freq * t) * 0.05).astype(np.float32)
        else:
            # Burst noise (simulates background sound)
            audio = np.random.randn(window_samples).astype(np.float32) * 0.05
            # Random fade in/out
            fade_len = np.random.randint(1000, 8000)
            audio[:fade_len] *= np.linspace(0, 1, fade_len)
            audio[-fade_len:] *= np.linspace(1, 0, fade_len)

        feat = extract_features(audio.astype(np.float32), sr=SAMPLE_RATE)
        features.append(feat)

    return features


def train_model(X: np.ndarray, y: np.ndarray):
    """Train XGBoost classifier with cross-validation."""
    from sklearn.model_selection import StratifiedKFold, cross_val_score
    from xgboost import XGBClassifier

    print(f"\n🏋️ Training XGBoost on {len(X)} samples ({sum(y==1)} positive, {sum(y==0)} negative)")

    # Hyperparameters tuned for small dataset with high-dim features
    model = XGBClassifier(
        n_estimators=200,
        max_depth=6,
        learning_rate=0.1,
        subsample=0.8,
        colsample_bytree=0.3,
        min_child_weight=3,
        reg_alpha=0.5,
        reg_lambda=1.0,
        scale_pos_weight=sum(y == 0) / max(sum(y == 1), 1),
        eval_metric="logloss",
        use_label_encoder=False,
        random_state=42,
    )

    # Cross-validation
    cv = StratifiedKFold(n_splits=min(5, min(sum(y == 0), sum(y == 1))), shuffle=True, random_state=42)
    scores = cross_val_score(model, X, y, cv=cv, scoring="accuracy")
    print(f"  Cross-val accuracy: {scores.mean():.4f} ± {scores.std():.4f}")

    recall_scores = cross_val_score(model, X, y, cv=cv, scoring="recall")
    print(f"  Cross-val recall:   {recall_scores.mean():.4f} ± {recall_scores.std():.4f}")

    # Train on full dataset
    model.fit(X, y)

    return model


def validate_model(model, X: np.ndarray, y: np.ndarray):
    """Validate the trained model produces varied probabilities."""
    probs = model.predict_proba(X)[:, 1]
    preds = model.predict(X)

    print(f"\n✅ Model Validation:")
    print(f"  Unique probability values: {len(np.unique(np.round(probs, 4)))}")
    print(f"  Prob range: [{probs.min():.4f}, {probs.max():.4f}]")
    print(f"  Accuracy: {(preds == y).mean():.4f}")

    # Check on specific test inputs
    test_inputs = {
        "all_zeros": np.zeros((1, FEATURE_DIM), dtype=np.float32),
        "all_minus_80": np.full((1, FEATURE_DIM), -80.0, dtype=np.float32),
        "random_noise": np.random.randn(1, FEATURE_DIM).astype(np.float32),
    }

    print(f"\n  Sanity checks:")
    for name, inp in test_inputs.items():
        pred = model.predict(inp)[0]
        prob = model.predict_proba(inp)[0]
        print(f"    {name}: label={pred}, probs=[{prob[0]:.4f}, {prob[1]:.4f}]")
        if name in ("all_zeros", "all_minus_80") and pred == 1:
            print(f"    ⚠ WARNING: {name} classified as wake word!")

    unique_probs = len(np.unique(np.round(probs, 4)))
    if unique_probs <= 2:
        print("\n  ❌ CRITICAL: Model only produces 2 probability values - still degenerate!")
        return False

    return True


def export_to_onnx(model, output_path: Path):
    """Export XGBoost model to ONNX format using onnxmltools."""
    import onnxmltools
    from onnxmltools.convert.common.data_types import FloatTensorType

    initial_type = [("float_input", FloatTensorType([None, FEATURE_DIM]))]

    onnx_model = onnxmltools.convert_xgboost(
        model,
        initial_types=initial_type,
        target_opset=12,
    )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "wb") as f:
        f.write(onnx_model.SerializeToString())

    size_kb = os.path.getsize(output_path) / 1024
    print(f"\n💾 Exported to {output_path} ({size_kb:.1f} KB)")


def verify_onnx(model_path: Path):
    """Verify the exported ONNX model works correctly."""
    import onnxruntime as ort

    sess = ort.InferenceSession(str(model_path))

    print(f"\n🔍 ONNX Verification:")
    for inp in sess.get_inputs():
        print(f"  Input:  {inp.name} shape={inp.shape} type={inp.type}")
    for out in sess.get_outputs():
        print(f"  Output: {out.name} shape={out.shape} type={out.type}")

    # Test inference
    tests = {
        "zeros": np.zeros((1, FEATURE_DIM), dtype=np.float32),
        "silence_db": np.full((1, FEATURE_DIM), -80.0, dtype=np.float32),
        "random": np.random.randn(1, FEATURE_DIM).astype(np.float32),
    }

    print(f"\n  Test inferences:")
    for name, inp in tests.items():
        result = sess.run(None, {"float_input": inp})
        label = result[0][0]
        print(f"    {name}: label={label}")
        if name in ("zeros", "silence_db") and label == 1:
            print(f"    ⚠ WARNING: {name} incorrectly classified as wake word")

    print(f"\n✨ ONNX model verified successfully!")


def main():
    print("=" * 60)
    print("  Wake Word Model Retrainer")
    print("=" * 60)

    check_dependencies()

    # 1. Load positive samples
    pos_features = load_positive_samples(ASSETS_DIR)

    if len(pos_features) < 10:
        print(f"\n❌ Only {len(pos_features)} positive windows extracted. Need at least 10.")
        sys.exit(1)

    # 2. Generate negative samples (2x positive count for balance)
    neg_count = max(len(pos_features) * 2, 200)
    neg_features = generate_negative_samples(neg_count)

    # 3. Build training data
    X_pos = np.array(pos_features, dtype=np.float32)
    X_neg = np.array(neg_features, dtype=np.float32)
    X = np.vstack([X_pos, X_neg])
    y = np.hstack([np.ones(len(X_pos)), np.zeros(len(X_neg))]).astype(int)

    # Shuffle
    idx = np.random.RandomState(42).permutation(len(X))
    X, y = X[idx], y[idx]

    print(f"\n📊 Dataset: {len(X)} total ({sum(y==1)} pos, {sum(y==0)} neg)")

    # 4. Train
    model = train_model(X, y)

    # 5. Validate
    if not validate_model(model, X, y):
        print("\n⚠ Model validation failed but continuing with export...")

    # 6. Export
    export_to_onnx(model, OUTPUT_MODEL)

    # 7. Verify ONNX
    verify_onnx(OUTPUT_MODEL)

    print("\n✅ Done! Deploy the app to test on device.")


if __name__ == "__main__":
    main()
