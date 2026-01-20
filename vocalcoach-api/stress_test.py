import requests
import numpy as np
import scipy.io.wavfile as wav
import os
import time
import concurrent.futures

API_URL = "http://127.0.0.1:5000/analyze"

def generate_tone(filename, freq, duration=0.5, sr=44100):
    t = np.linspace(0, duration, int(sr * duration), endpoint=False)
    audio = 0.5 * np.sin(2 * np.pi * freq * t)
    audio_int16 = (audio * 32767).astype(np.int16)
    wav.write(filename, sr, audio_int16)
    return filename

def single_request(freq, gender, i):
    filename = f"stress_{i}_{freq}.wav"
    generate_tone(filename, freq)
    try:
        start = time.time()
        with open(filename, 'rb') as f:
            resp = requests.post(API_URL, files={'file': f}, data={'gender': gender})
        elapsed = time.time() - start
        
        if resp.status_code == 200:
            data = resp.json()
            return f"✅ Req {i} [{gender.upper()} {freq}Hz] -> {data['voice_type']} ({elapsed:.2f}s)"
        else:
            return f"❌ Req {i} Failed: {resp.status_code}"
    except Exception as e:
        return f"💥 Req {i} Error: {str(e)}"
    finally:
        if os.path.exists(filename):
            try: os.remove(filename)
            except: pass

print("🚀 STARTING RAPID FIRE STRESS TEST (10 Requests)...")

# Alternating requests rapidly
requests_list = []
for i in range(10):
    gender = "male" if i % 2 == 0 else "female"
    freq = 300 if gender == "male" else 140 # Countertenor vs Contralto
    requests_list.append((freq, gender, i))

start_total = time.time()

# Run serially to mimic rapid user clicks (or parallel if we want to test concurrency)
# User asked "one after the other", so rapid serial is good.
results = []
for req in requests_list:
    res = single_request(*req)
    print(res)
    results.append(res)

print(f"\n🏁 Finished in {time.time() - start_total:.2f}s")
