import numpy as np
import librosa
import tensorflow as tf
import sounddevice as sd
import time
import sys

MODEL_PATH = 'assets/wakeword/model_float16.tflite'

try:
    interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    print(f"Loaded TFLite model: {MODEL_PATH}")
    print(f"Input shape expected: {input_details[0]['shape']}")
except Exception as e:
    print(f"Error loading model: {e}")
    sys.exit(1)

# Dart constants (Reconfigured for 64x101)
SAMPLE_RATE = 16000
N_FFT = 320         # 20ms window
HOP_LENGTH = 160    # 10ms step -> (16000/160) = 100 + 1 (center) = 101 frames!
N_MELS = 64         # 64 frequency bands
N_MFCC = 64         # Exporting 64 MFCCs
TARGET_FRAMES = 101 # Exact 101 frames required

audio_buffer = np.zeros(SAMPLE_RATE, dtype=np.float32)

def audio_callback(indata, frames, time_info, status):
    global audio_buffer
    audio_buffer = np.roll(audio_buffer, -frames)
    audio_buffer[-frames:] = indata[:, 0]

def extract_features(audio):
    # Match the librosa feature pipeline that we verified works!
    mel_spec = librosa.feature.melspectrogram(
        y=audio, 
        sr=SAMPLE_RATE, 
        n_fft=N_FFT, 
        hop_length=HOP_LENGTH, 
        n_mels=N_MELS,
        center=True
    )
    
    mel_db = librosa.power_to_db(mel_spec, ref=np.max, amin=1e-10, top_db=80.0)
    
    # Pad or slice to exactly TARGET_FRAMES
    if mel_db.shape[1] < TARGET_FRAMES:
        pad_width = TARGET_FRAMES - mel_db.shape[1]
        mel_db = np.pad(mel_db, pad_width=((0, 0), (0, pad_width)), mode='constant')
    else:
        mel_db = mel_db[:, :TARGET_FRAMES]
        
    return mel_db  # Shape is (64, 101)

print("Starting audio stream...")
try:
    with sd.InputStream(samplerate=SAMPLE_RATE, channels=1, callback=audio_callback):
        print("-----------------------------------------")
        print("🎙️ Listening... Say 'Zero Two' to the PC Mic!")
        print("-----------------------------------------")
        while True:
            time.sleep(0.2)
            
            rms = np.sqrt(np.mean(audio_buffer**2))
            if rms < 0.003:
                continue
                
            features = extract_features(audio_buffer)
            
            # Reshape based on exactly what the TFLite model expects
            expected_shape = tuple(input_details[0]['shape'])
            
            try:
                input_tensor = features.astype(np.float32).reshape(expected_shape)
            except Exception as e:
                print(f"Shape Error! Features (1280) cannot reshape to {expected_shape}. Did you change the MFCC/Time frames in training?")
                continue
            
            interpreter.set_tensor(input_details[0]['index'], input_tensor)
            interpreter.invoke()
            probs = interpreter.get_tensor(output_details[0]['index'])[0]
            
            # Assuming Google Teachable Machine multi-class output format
            if len(probs) == 1:
                prob = float(probs[0])
                debug = ""
            else:
                prob = float(np.max(probs[1:]))
                debug = f" | All Probabilities: {[round(float(p), 4) for p in probs]}"
                
            if prob > 0.60:
                print(f"🔥 Prob: {prob:.4f} | RMS: {rms:.4f}  <-- DETECTED!{debug}")
            else:
                print(f"Prob: {prob:.4f} | RMS: {rms:.4f}{debug}")
                
except KeyboardInterrupt:
    print("\nStopped.")
except Exception as e:
    print(f"Audio error: {e}")
