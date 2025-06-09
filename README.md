# 🎙️ VoiceNotes - Speak and Save

**An Audio Note-Taking Solution Using Flutter**

VoiceNotes is a modern, cross-platform mobile application built with Flutter that allows users to record, organize, and manage voice notes with ease. The app features a beautiful material design interface.

## 🌟 Features

### 🎵 Audio Recording & Playback
- **High-quality audio recording** using flutter_sound
- **Audio playback controls** with play, pause, and seek functionality
- **Real-time recording duration display**
- **Audio waveform visualization** during recording and playback

### 📝 Note Management
- **Add titles and descriptions** to voice notes
- **Tag system** for easy organization and categorization
- **Search and filter** notes by title, description, or tags
- **Edit note metadata** after recording
- **Delete unwanted recordings**

### 💾 Data Persistence
- **Local SQLite database** for storing note metadata
- **Secure file storage** for audio recordings
- **Automatic backup** of note information
- **Data integrity** with proper error handling

### 🎨 Modern UI/UX
- **Material 3 design system** with modern aesthetics
- **Light and dark theme support** with automatic switching
- **Smooth animations** using flutter_staggered_animations
- **Responsive design** that works across different screen sizes
- **Intuitive navigation** with clear visual feedback

### 🔒 Privacy & Permissions
- **Microphone permission handling** with proper user consent
- **Local storage only** - no cloud uploads
- **Privacy-focused** design with user data control

## 📱 Screenshots

*Add screenshots of your app here to showcase the UI*

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (version 3.7.2 or higher)
- **Dart SDK** (compatible with Flutter version)
- **Android Studio** or **Xcode** for device deployment
- **Git** for version control

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/voicenotes.git
   cd voicenotes
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Check Flutter setup**
   ```bash
   flutter doctor
   ```

4. **Run the app**
   ```bash
   # For development
   flutter run

   # For specific platform
   flutter run -d ios
   flutter run -d android
   ```

### Platform-Specific Setup

#### Android
- Minimum SDK version: 21 (Android 5.0)
- Permissions automatically handled in `android/app/src/main/AndroidManifest.xml`

#### iOS
- Minimum iOS version: 12.0
- Microphone usage description required in `ios/Runner/Info.plist`

#### macOS
- Minimum macOS version: 10.14
- Entitlements configured for microphone access

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point with theme configuration
├── models/
│   └── voice_note.dart      # VoiceNote data model
├── providers/
│   └── voice_notes_provider.dart  # State management
├── screens/
│   ├── home_screen.dart     # Main screen with notes list
│   └── add_edit_note_screen.dart  # Recording and editing interface
├── services/
│   ├── audio_service.dart   # Audio recording and playback logic
│   └── database_service.dart # SQLite database operations
└── widgets/
    └── ...                  # Reusable UI components
```

## 🛠️ Technical Stack

### Core Framework
- **Flutter 3.7.2+** - Cross-platform UI toolkit
- **Dart** - Programming language

### Key Dependencies
- **flutter_sound** `^9.2.13` - Audio recording and playback
- **audioplayers** `^6.0.0` - Additional audio functionality
- **permission_handler** `^11.3.1` - Device permissions management
- **provider** `^6.1.1` - State management solution
- **sqflite** `^2.3.2` - SQLite database for local storage
- **path_provider** `^2.1.2` - File system path management
- **intl** `^0.19.0` - Internationalization support
- **flutter_staggered_animations** `^1.1.1` - UI animations

### Architecture Patterns
- **Provider Pattern** for state management
- **Service Layer** for business logic separation
- **Repository Pattern** for data access abstraction
- **Widget Composition** for reusable UI components

## 🎯 Usage

### Recording a Voice Note

1. **Tap the microphone FAB** on the home screen
2. **Grant microphone permission** if prompted
3. **Start recording** by tapping the record button
4. **Stop recording** when finished
5. **Add title, description, and tags**
6. **Save the note** to your collection

### Managing Voice Notes

- **View all notes** on the home screen
- **Tap a note** to play audio
- **Long press** for edit/delete options
- **Use search** to find specific notes
- **Filter by tags** for organization

### Playback Controls

- **Play/Pause** audio with the central button
- **Seek** through audio using the progress slider
- **View duration** and current position
- **Control volume** with device controls

## 🤝 Contributing

We welcome contributions to VoiceNotes! Please follow these steps:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Commit your changes** (`git commit -m 'Add some amazing feature'`)
4. **Push to the branch** (`git push origin feature/amazing-feature`)
5. **Open a Pull Request**

### Development Guidelines

- Follow **Flutter style guidelines**
- Write **meaningful commit messages**
- Add **tests** for new features
- Update **documentation** as needed
- Ensure **code compatibility** across platforms

## 🐛 Known Issues

- Audio recording may require app restart on some Android devices
- Large audio files (>10 minutes) may impact performance
- iOS simulator doesn't support audio recording


## 🙏 Acknowledgments

- **Flutter Team** for the amazing framework
- **flutter_sound** contributors for audio capabilities
- **Material Design** for UI/UX inspiration
- **Open source community** for various packages and tools

## 📞 Support

If you encounter any issues or have questions:

1. **Check existing issues** on GitHub
2. **Create a new issue** with detailed information
3. **Contact the maintainers** for urgent matters

## 🔮 Future Enhancements

- [ ] Cloud storage integration
- [ ] Audio transcription features
- [ ] Voice note sharing capabilities
- [ ] Advanced search with voice recognition
- [ ] Export options (MP3, WAV)
- [ ] Note categorization improvements
- [ ] Widget support for quick recording

---

**Made with ❤️ using Flutter**
