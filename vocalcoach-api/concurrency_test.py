import requests
import numpy as np
import scipy.io.wavfile as wav
import os
import time
import concurrent.futures

API_URL = "http://127.0.0.1:5000/analyze"

def generate_tone(filename, freq, duration=1.0, sr=44100):
    t = np.linspace(0, duration, int(sr * duration), endpoint=False)
    audio = 0.5 * np.sin(2 * np.pi * freq * t)
    audio_int16 = (audio * 32767).astype(np.int16)
    wav.write(filename, sr, audio_int16)
    return filename

def single_request(i):
    freq = 140 if i % 2 == 0 else 300
    gender = "female" if i % 2 == 0 else "male"
    filename = f"concurrent_{i}_{freq}.wav"
    generate_tone(filename, freq)
    
    try:
        # Simulate slight user stagger
        time.sleep(np.random.uniform(0.01, 0.1)) 
        
        with open(filename, 'rb') as f:
            start = time.time()
            # Set a strict timeout to mimic mobile network sensitivity
            resp = requests.post(API_URL, files={'file': f}, data={'gender': gender}, timeout=5)
            elapsed = time.time() - start
            
        if resp.status_code == 200:
            return f"✅ Req {i} Success ({elapsed:.2f}s)"
        else:
            return f"❌ Req {i} Failed: {resp.status_code}"
            
    except Exception as e:
        return f"💥 Req {i} Connection Error: {str(e)}"
    finally:
        if os.path.exists(filename):
            try: os.remove(filename)
            except: pass

print("🔥 STARTING CONCURRENT FIRE TEST (20 Parallel Requests)...")
start_total = time.time()

with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
    futures = [executor.submit(single_request, i) for i in range(20)]
    for future in concurrent.futures.as_completed(futures):
        print(future.result())

print(f"\n🏁 Finished in {time.time() - start_total:.2f}s")
