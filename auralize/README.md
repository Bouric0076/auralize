# 🎵 Auralize

> **A modern, immersive music player built with Flutter, focusing on stunning audio visualizations and a fluid user experience.**

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Flutter](https://img.shields.io/badge/Built%20with-Flutter-02569B.svg)
![State Management](https://img.shields.io/badge/State-Riverpod-purple.svg)

## ✨ Features

- **🎧 Immersive Visualizations**: Experience your music with real-time, reactive visualizers:
  - **Wave**: Smooth, liquid-like waveforms with gradient fills.
  - **Bars**: Classic frequency analyzer with peak hold.
  - **Particles**: Dynamic particles that react to the beat.
  - **Circular**: A futuristic ring visualizer.
- **📱 Modern UI/UX**:
  - Fluid animations powered by `flutter_animate`.
  - Minimalist dark mode design.
  - Gesture-based controls.
- **📂 Local File Support**: Play audio files directly from your device storage.
- **🔊 Background Playback**: Keep the music playing even when the app is minimized or the screen is off.
- **🎛️ Audio Effects**: (Coming Soon) Equalizer and bass boost.

## 🛠️ Tech Stack

This project is built using the latest Flutter technologies and best practices:

- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Riverpod](https://riverpod.dev/) (Hooks & Code Generation)
- **Audio Engine**: 
  - [`just_audio`](https://pub.dev/packages/just_audio) for robust playback.
  - [`just_audio_background`](https://pub.dev/packages/just_audio_background) for background service support.
- **Visualizations**: Custom Painters & FFT analysis via `audio_waveforms`.
- **Animations**: [`flutter_animate`](https://pub.dev/packages/flutter_animate) for UI effects.
- **File Handling**: `file_picker` and `permission_handler`.

## 🚀 Getting Started

Follow these steps to run the project locally.

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.0+)
- Android Studio or VS Code
- An Android device or emulator (iOS simulator supported on macOS)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/bouric0076/auralize.git
    cd auralize
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the app:**
    ```bash
    flutter run
    ```

> **Note:** For Android 13+, ensure you grant the necessary media permissions when prompted.

## 🗺️ Roadmap

- [x] Basic Playback & Queue Management
- [x] Visualizers (Wave, Bars, Particles, Circular)
- [x] Background Playback
- [ ] **Group Session / Wi-Fi Sync**: Sync playback across multiple devices for a silent disco experience.
- [ ] **Lyrics Support**: Real-time synced lyrics.
- [ ] **Playlist Management**: Create and edit custom playlists.

## 🤝 Contributing

Contributions are welcome! If you have an idea for a new visualizer or feature:

1.  Fork the repository.
2.  Create a new branch (`git checkout -b feature/AmazingVisualizer`).
3.  Commit your changes.
4.  Push to the branch.
5.  Open a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
*Built by Bouric Okwaro*
