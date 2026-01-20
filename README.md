# Vocal Coach Studio 🎙️

A professional vocal analysis application built with **Flutter** (Frontend) and **Python/Flask** (Backend). This app helps users analyze their voice pitch, determine their voice type (e.g., Soprano, Tenor), and visualize their vocal range.

![App Screenshot](https://via.placeholder.com/800x400.png?text=Vocal+Coach+Studio+Preview)

## ✨ Features

*   **Real-time Pitch Analysis**: Visualizes pitch frequency and stability.
*   **Voice Type Classification**: Automatically detects voice types (Soprano, Mezzo, Contralto, Tenor, Baritone, Bass).
*   **Multi-Language Support**: Fully localized in 10 languages:
    *   🇹🇷 Turkish (Default)
    *   🇺🇸 English
    *   🇩🇪 German
    *   🇫🇷 French
    *   🇮🇹 Italian
    *   🇪🇸 Spanish
    *   🇨🇳 Chinese
    *   🇷🇺 Russian
    *   🇯🇵 Japanese
    *   🇰🇷 Korean
*   **Recording Management**: Save, rename, and manage your vocal recordings.
*   **Modern UI**: Sleek, dark-mode "Studio" aesthetic with smooth animations.

## 🚀 Getting Started

### Prerequisites

*   [Flutter SDK](https://flutter.dev/docs/get-started/install)
*   [Python 3.8+](https://www.python.org/downloads/)
*   [FFmpeg](https://ffmpeg.org/download.html) (Required for audio processing)

### 1. Backend Setup (Python API)

The backend handles audio processing using `librosa`.

1.  Navigate to the API directory:
    ```bash
    cd vocalcoach-api
    ```

2.  Install dependencies:
    ```bash
    pip install -r requirements.txt
    ```
    *(Note: If `requirements.txt` is missing, install: `flask`, `librosa`, `numpy`, `waitress`, `werkzeug`)*

3.  Run the server:
    ```bash
    python app.py
    ```
    The API will start on `http://localhost:5000` (or `http://10.0.2.2:5000` for Android emulator access).

### 2. Frontend Setup (Flutter App)

1.  Navigate to the project root:
    ```bash
    cd ..
    ```

2.  Get dependencies:
    ```bash
    flutter pub get
    ```

3.  Run the app:
    ```bash
    flutter run
    ```

## 📂 Project Structure

*   **`lib/`**: Flutter source code.
    *   `main.dart`: Entry point and theme configuration.
    *   `localization_manager.dart`: Handles language state and translations.
    *   `home_page.dart`: Main dashboard with language selection.
    *   `recorder_page.dart`: Audio recording interface.
    *   `pitch_graph_page.dart`: Analysis results and graphs.
*   **`vocalcoach-api/`**: Python Flask backend.
    *   `app.py`: Main API logic for pitch detection and classification.

## 🛠️ Tech Stack

*   **Frontend**: Flutter (Dart), Google Fonts, Fl Chart, Just Audio.
*   **Backend**: Python, Flask, Librosa, NumPy, FFMPEG.
*   **Localization**: Custom localization manager with `country_flags`.

## 📝 License

This project is open source and available under the [MIT License](LICENSE).
