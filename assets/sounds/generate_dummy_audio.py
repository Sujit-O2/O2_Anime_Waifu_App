import wave
import struct
import os

def create_silent_wav(filename, duration_seconds=1):
    """Create a silent WAV file for testing"""
    sample_rate = 44100
    n_frames = int(sample_rate * duration_seconds)
    
    with wave.open(filename, 'w') as w:
        w.setnchannels(1)  # mono
        w.setsampwidth(2)  # 2 bytes per sample
        w.setframerate(sample_rate)
        # Write zeros (silence)
        w.writeframes(b'\x00' * (n_frames * 2))
    
    print(f"Created: {filename}")

# Create silent WAV files for testing
if __name__ == "__main__":
    create_silent_wav('background_music.wav', 3)
    create_silent_wav('tap.wav', 1)
    create_silent_wav('mini_game_win.wav', 1)
    create_silent_wav('mini_game_lose.wav', 1)
    create_silent_wav('click_effect.wav', 1)
    create_silent_wav('win_effect.wav', 1)
    create_silent_wav('game_arcade_bgm.mp3', 5)
    create_silent_wav('game_puzzle_bgm.mp3', 5)
    create_silent_wav('game_reaction_bgm.mp3', 5)
    create_silent_wav('game_brain_bgm.mp3', 5)
    print("All dummy audio files created successfully!")
