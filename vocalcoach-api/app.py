import os
import logging
import uuid
import traceback
from datetime import datetime
from typing import Optional, Tuple, List, Dict, Any

import librosa
import numpy as np
from flask import Flask, request, jsonify
from werkzeug.utils import secure_filename
from werkzeug.exceptions import RequestEntityTooLarge
import subprocess
from dataclasses import dataclass
from enum import Enum

# ----------------------
# Configuration
# ----------------------
class Config:
    """Application configuration constants."""
    MAX_CONTENT_LENGTH = 10 * 1024 * 1024  # 10 MB
    UPLOAD_FOLDER = 'uploads'
    CONVERTED_FOLDER = 'converted'
    ALLOWED_EXTENSIONS = {'aac', 'wav', 'mp3', 'ogg'}
    DEFAULT_PORT = 5000

# ----------------------
# Enums and Data Classes
# ----------------------
class VoiceType(Enum):
    """Enumeration of standard voice types."""
    SOPRANO = "Soprano"
    MEZZO_SOPRANO = "Mezzo-soprano"
    CONTRALTO = "Kontralto"
    COUNTER_TENOR = "Countertenor"
    TENOR = "Tenor"
    BARITONE = "Bariton"
    BASS = "Bas"
    UNKNOWN = "Belirsiz"

@dataclass
class AnalysisResult:
    """Data class to store the result of a voice analysis."""
    voice_type: VoiceType
    average_pitch: float
    processing_time: str
    message: Optional[str] = None

# ----------------------
# Flask App Setup
# ----------------------
app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = Config.MAX_CONTENT_LENGTH

# ----------------------
# Logging Setup
# ----------------------
def setup_logging() -> None:
    """Configures the logging format and handlers."""
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler('api.log'),
            logging.StreamHandler()
        ]
    )

# ----------------------
# Helper Functions
# ----------------------
def create_folders() -> None:
    """Creates necessary directories for file storage if they don't exist."""
    os.makedirs(Config.UPLOAD_FOLDER, exist_ok=True)
    os.makedirs(Config.CONVERTED_FOLDER, exist_ok=True)
    logging.info("Upload and converted directories checked/created.")

def allowed_file(filename: str) -> bool:
    """Checks if the file extension is allowed."""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in Config.ALLOWED_EXTENSIONS

def generate_unique_filename(original_filename: str) -> Tuple[str, str]:
    """
    Generates a secure, unique filename for storage.
    
    Returns:
        Tuple containing the full input path and the target output path for conversion.
    """
    unique_id = uuid.uuid4().hex
    safe_filename = secure_filename(f"{unique_id}_{original_filename}")
    input_path = os.path.join(Config.UPLOAD_FOLDER, safe_filename)
    output_path = os.path.join(Config.CONVERTED_FOLDER, f"{os.path.splitext(safe_filename)[0]}.wav")
    return input_path, output_path

def clean_up_files(*file_paths: Optional[str]) -> None:
    """Deletes the specified files from the filesystem."""
    for path in file_paths:
        try:
            if path and os.path.exists(path):
                os.remove(path)
                logging.info(f"Deleted: {path}")
        except Exception as e:
            logging.warning(f"Error deleting file ({path}): {str(e)}")

# ----------------------
# Audio Processing
# ----------------------
def convert_to_wav(input_path: str, output_path: str) -> None:
    """
    Converts audio file to WAV format using ffmpeg.
    
    Args:
        input_path: Source file path.
        output_path: Destination file path.
        
    Raises:
        Exception: If ffmpeg processing fails.
    """
    try:
        subprocess.run(
            ['ffmpeg', '-i', input_path, '-acodec', 'pcm_s16le', '-ar', '44100', output_path, '-y'],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        logging.info(f"✅ Converted: {input_path} → {output_path}")
    except subprocess.CalledProcessError as e:
        error_msg = f"FFmpeg error: {e.stderr}"
        logging.error(error_msg)
        raise Exception(error_msg)

def analyze_pitch(y: np.ndarray, sr: int) -> Tuple[float, List[float]]:
    """
    Analyzes the pitch of the audio signal.
    
    1. Removes silence.
    2. Uses YIN algorithm for pitch detection.
    
    Returns:
        Tuple of (average_pitch, list_of_pitches).
    """
    # 1. Silence Removal (Quiet sections < 20db cut)
    y_trimmed, _ = librosa.effects.trim(y, top_db=20)
    
    if len(y_trimmed) / sr < 0.5:
        # Fallback to original if trim is too aggressive (short file)
        if len(y) / sr < 0.5:
            raise ValueError("Audio file is too short (minimum 0.5 seconds)")
        y_using = y
    else:
        y_using = y_trimmed

    # 2. Pitch Detection (YIN Algorithm)
    # fmin=60 (Bass low), fmax=1000 (Soprano high)
    pitch = librosa.yin(y_using, fmin=60, fmax=1000, sr=sr)
    
    # Filter out invalid/unvoiced segments
    pitch = pitch[np.isfinite(pitch)]
    pitch = pitch[pitch > 0]

    if pitch.size == 0:
        raise ValueError("No pitch detected")

    # Use Median for robustness against outliers
    return float(np.median(pitch)), pitch.tolist()

def classify_voice(avg_pitch: float, gender: Optional[str] = None) -> VoiceType:
    """
    Classifies voice based on average fundamental frequency and provided gender.
    
    Args:
        avg_pitch: The average Hz detected.
        gender: 'female' or 'male' (optional).
        
    Returns:
        VoiceType enum.
    """
    p = avg_pitch
    g = gender.lower() if gender else None

    # 1. If Gender is strictly provided, use specific scale.
    if g in ['female', 'kadın']:
        if p >= 260:
            return VoiceType.SOPRANO
        elif p >= 210:
            return VoiceType.MEZZO_SOPRANO
        else:
            # Even if low, usually Contralto for females
            return VoiceType.CONTRALTO

    elif g in ['male', 'erkek']:
        if p >= 260:
            return VoiceType.COUNTER_TENOR
        elif p >= 165:
            return VoiceType.TENOR
        elif p >= 110:
            return VoiceType.BARITONE
        else:
            return VoiceType.BASS

    # 2. If Gender is UNKNOWN, infer based on statistical probability
    if p >= 255:
        return VoiceType.SOPRANO
    elif p >= 175:
        return VoiceType.TENOR 
    elif p >= 110:
        return VoiceType.BARITONE
    else:
        return VoiceType.BASS

# ----------------------
# API Endpoints
# ----------------------
@app.route('/analyze', methods=['POST'])
def analyze() -> Tuple[Any, int]:
    """
    Endpoint to analyze an uploaded audio file.
    Expects a 'file' in the multipart/form-data.
    Optional 'gender' field.
    """
    start_time = datetime.now()
    input_path, output_path = None, None

    try:
        print("🎙️ /analyze request received.")
        if 'file' not in request.files:
            raise ValueError("No file part in request")
        
        gender = request.form.get('gender', None)
        file = request.files['file']

        if file.filename == '':
            raise ValueError("No file selected")
        if not allowed_file(file.filename):
            raise ValueError("Unsupported file format")

        input_path, output_path = generate_unique_filename(file.filename)
        logging.info(f"Uploading file: {input_path}")
        file.save(input_path)
        
        convert_to_wav(input_path, output_path)

        y, sr = librosa.load(output_path, sr=None)
        avg_pitch, pitch_series = analyze_pitch(y, sr)
        voice_type = classify_voice(avg_pitch, gender)

        result = AnalysisResult(
            voice_type=voice_type,
            average_pitch=round(avg_pitch, 2),
            processing_time=str(datetime.now() - start_time)
        )

        logging.info(f"Analysis result: {result}")

        return jsonify({
            'status': 'success',
            'voice_type': result.voice_type.value,
            'average_pitch': result.average_pitch,
            'pitch_series': pitch_series,
            'processing_time': result.processing_time
        }), 200

    except ValueError as e:
        logging.error(f"❌ Validation error: {str(e)}")
        return jsonify({'status': 'error', 'message': str(e)}), 400
    except RequestEntityTooLarge:
        error_msg = "File too large (limit 10MB)"
        logging.error(error_msg)
        return jsonify({'status': 'error', 'message': error_msg}), 413
    except Exception as e:
        logging.error(f"❌ Exception: {str(e)}")
        traceback.print_exc()
        return jsonify({'status': 'error', 'message': str(e)}), 500
    finally:
        clean_up_files(input_path, output_path)

@app.route('/health', methods=['GET'])
def health_check() -> Tuple[Any, int]:
    """Health check endpoint to verify service status."""
    ffmpeg_available = subprocess.run(['ffmpeg', '-version'], capture_output=True).returncode == 0
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'services': {
            'ffmpeg': 'available' if ffmpeg_available else 'unavailable',
            'storage': {
                'upload_folder': os.path.isdir(Config.UPLOAD_FOLDER),
                'converted_folder': os.path.isdir(Config.CONVERTED_FOLDER)
            }
        }
    }), 200

@app.route('/')
def home() -> Tuple[Any, int]:
    """Root endpoint."""
    return jsonify({
        'message': 'VocalCoach API is running!',
        'endpoints': {
            'analyze': '/analyze (POST)',
            'health_check': '/health (GET)'
        }
    }), 200

# ----------------------
# Initialization
# ----------------------
setup_logging()
create_folders()

if __name__ == '__main__':
    port = int(os.getenv('PORT', Config.DEFAULT_PORT))
    print(f"🚀 Starting VocalCoach API (Port: {port})...")
    from waitress import serve
    serve(app, host='0.0.0.0', port=port, threads=6)
