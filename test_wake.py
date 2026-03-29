import numpy as np
import librosa
import onnxruntime as ort
import sounddevice as sd
import time
import sys

MODEL_PATH = 'assets/wakeword/valid/production_zero_two.onnx'

try:
    session = ort.InferenceSession(MODEL_PATH)
    print(f"Loaded ONNX model: {MODEL_PATH}")
except Exception as e:
    print(f"Error loading model: {e}")
    sys.exit(1)

# Dart constants
SAMPLE_RATE = 16000
N_FFT = 2048
HOP_LENGTH = 512
N_MELS = 128
N_MFCC = 40
TARGET_FRAMES = 32

audio_buffer = np.zeros(SAMPLE_RATE, dtype=np.float32)

def audio_callback(indata, frames, time_info, status):
    global audio_buffer
    audio_buffer = np.roll(audio_buffer, -frames)
    audio_buffer[-frames:] = indata[:, 0]

def extract_features(audio):
    # Match the Dart Librosa-style pipeline
    mel_spec = librosa.feature.melspectrogram(
        y=audio,  
        sr=SAMPLE_RATE, 
        n_fft=N_FFT, 
        hop_length=HOP_LENGTH, 
        n_mels=N_MELS,
        center=True
    )
    
    mel_db = librosa.power_to_db(mel_spec, ref=np.max, amin=1e-10, top_db=80.0)
    
    mfcc = librosa.feature.mfcc(S=mel_db, n_mfcc=N_MFCC)
    
    # Pad or slice to exactly 32 frames (width)
    if mfcc.shape[1] < TARGET_FRAMES:
        pad_width = TARGET_FRAMES - mfcc.shape[1]
        mfcc = np.pad(mfcc, pad_width=((0, 0), (0, pad_width)), mode='constant')
    else:
        mfcc = mfcc[:, :TARGET_FRAMES]
        
    return mfcc  # Shape is (40, 32)
    # wait, input shape is (1, 40, 32, 1)

print("Starting audio stream...")
try:
    with sd.InputStream(samplerate=SAMPLE_RATE, channels=1, callback=audio_callback):
        print("-----------------------------------------")
        print("🎙️ Listening... Say 'Zero Two' to the PC Mic!")
        print("-----------------------------------------")
        while True:
            time.sleep(0.2) # evaluate 5 times a second
            
            rms = np.sqrt(np.mean(audio_buffer**2))
            if rms < 0.003:
                continue
                
            features = extract_features(audio_buffer)
            
            # Reshape to ONNX input [1, 40, 32, 1]
            input_tensor = features.astype(np.float32).reshape(1, N_MFCC, TARGET_FRAMES, 1)
            
            ort_inputs = {session.get_inputs()[0].name: input_tensor}
            ort_outs = session.run(None, ort_inputs)
            
            probs = np.array(ort_outs[0][0])
            
            if len(probs) == 1:
                prob = probs[0]
            else:
                # Assuming multi-class where 0=Background, max of rest=Wake
                prob = float(np.max(probs[1:]))
                
            if prob > 0.60:
                print(f"🔥 Prob: {prob:.4f} | RMS: {rms:.4f}  <-- DETECTED!")
            else:
                print(f"Prob: {prob:.4f} | RMS: {rms:.4f}")
                
except KeyboardInterrupt:
    print("\nStopped.")
except Exception as e:
    print(f"Audio error: {e}")
