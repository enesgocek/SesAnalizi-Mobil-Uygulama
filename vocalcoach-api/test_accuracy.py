import requests
import numpy as np
import scipy.io.wavfile as wav
import os
import time

API_URL = "http://127.0.0.1:5000/analyze"

def generate_tone(filename, freq, duration=1.0, sr=44100):
    t = np.linspace(0, duration, int(sr * duration), endpoint=False)
    # Generate sine wave
    audio = 0.5 * np.sin(2 * np.pi * freq * t)
    # Convert to 16-bit PCM
    audio_int16 = (audio * 32767).astype(np.int16)
    wav.write(filename, sr, audio_int16)
    return filename

def test_voice(freq, gender_input, expected_label):
    filename = f"test_{freq}Hz.wav"
    generate_tone(filename, freq)
    
    try:
        with open(filename, 'rb') as f:
            files = {'file': f}
            data = {'gender': gender_input}
            response = requests.post(API_URL, files=files, data=data)
            
        if response.status_code == 200:
            result = response.json()
            actual_type = result['voice_type']
            pitch = result['average_pitch']
            
            # Simple check
            success = expected_label.lower() in actual_type.lower()
            status_icon = "✅" if success else "❌"
            
            print(f"{status_icon} Input: {freq}Hz | Gender: {gender_input.upper().ljust(6)} -> Result: {actual_type} ({pitch}Hz)")
            
            if not success:
               print(f"   Expected: {expected_label}, Got: {actual_type}")
               
        else:
            print(f"❌ API Error: {response.status_code} - {response.text}")

    except Exception as e:
        print(f"❌ Connection Failed: {e}")
    finally:
        if os.path.exists(filename):
            os.remove(filename)

print("🧪 STARTING ACCURACY TESTS...\n")

# Test 1: Low Pitch (140 Hz)
# Male -> Should be Baritone
test_voice(140, "male", "Bariton")
# Female -> Should be Contralto (The Logic Fix)
test_voice(140, "female", "Kontralto")

print("-" * 40)

# Test 2: Mid-High Pitch (230 Hz)
# Male -> Should be Tenor
test_voice(230, "male", "Tenor")
# Female -> Should be Mezzo
test_voice(230, "female", "Mezzo")

print("-" * 40)

# Test 3: High Pitch (300 Hz)
# Male -> Should be Countertenor
test_voice(300, "male", "Countertenor")
# Female -> Should be Soprano
test_voice(300, "female", "Soprano")

print("\n🧪 TESTS COMPLETED.")
