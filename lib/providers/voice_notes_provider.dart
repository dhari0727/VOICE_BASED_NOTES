import 'package:flutter/material.dart';
import '../models/voice_note.dart';
import '../services/database_service.dart';
import '../services/audio_service.dart';
import '../services/transcription_service.dart';

class VoiceNotesProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final AudioService _audioService = AudioService();
  final TranscriptionService _transcriptionService = TranscriptionService();

  List<VoiceNote> _voiceNotes = [];
  List<VoiceNote> get voiceNotes => _voiceNotes;

  List<String> _allTags = [];
  List<String> get allTags => _allTags;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String? _selectedTag;
  String? get selectedTag => _selectedTag;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Current recording state
  bool _isRecording = false;
  bool get isRecording => _isRecording;

  Duration _recordingDuration = Duration.zero;
  Duration get recordingDuration => _recordingDuration;

  // Live transcription state
  String? _liveTranscript;
  String? get liveTranscript => _liveTranscript;
  String _languageCode = 'en_US';
  String get languageCode => _languageCode;

  // Current playback state
  String? _currentlyPlayingId;
  String? get currentlyPlayingId => _currentlyPlayingId;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Duration _playbackPosition = Duration.zero;
  Duration get playbackPosition => _playbackPosition;

  Duration _playbackDuration = Duration.zero;
  Duration get playbackDuration => _playbackDuration;

  VoiceNotesProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _audioService.initialize();
    _setupAudioServiceListeners();
    await _transcriptionService.initialize();
    await loadVoiceNotes();
    await loadAllTags();
  }

  void _setupAudioServiceListeners() {
    _audioService.onStateChanged = (AudioState state) {
      _isRecording = state == AudioState.recording;
      _isPlaying = state == AudioState.playing;

      // Clear currently playing ID when audio stops
      if (state == AudioState.stopped && _isPlaying == false) {
        _currentlyPlayingId = null;
        _playbackPosition = Duration.zero;
        _playbackDuration = Duration.zero;
      }

      notifyListeners();
    };

    _audioService.onRecordingDurationChanged = (Duration duration) {
      _recordingDuration = duration;
      notifyListeners();
    };

    _audioService.onPlaybackPositionChanged = (Duration position) {
      _playbackPosition = position;
      notifyListeners();
    };

    _audioService.onPlaybackDurationChanged = (Duration duration) {
      _playbackDuration = duration;
      notifyListeners();
    };
  }

  Future<void> loadVoiceNotes() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_searchQuery.isNotEmpty) {
        _voiceNotes = await _databaseService.searchVoiceNotes(_searchQuery);
      } else if (_selectedTag != null) {
        _voiceNotes = await _databaseService.getVoiceNotesByTag(_selectedTag!);
      } else {
        _voiceNotes = await _databaseService.getAllVoiceNotes();
      }
    } catch (e) {
      _error = 'Failed to load voice notes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllTags() async {
    try {
      _allTags = await _databaseService.getAllTags();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load tags: $e';
      notifyListeners();
    }
  }

  Future<void> searchVoiceNotes(String query) async {
    _searchQuery = query;
    _selectedTag = null;
    await loadVoiceNotes();
  }

  Future<void> filterByTag(String? tag) async {
    _selectedTag = tag;
    _searchQuery = '';
    await loadVoiceNotes();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedTag = null;
    loadVoiceNotes();
  }

  // Recording methods
  Future<String?> startRecording() async {
    try {
      _error = null;
      final path = await _audioService.startRecording();
      // Start live transcription optionally
      _liveTranscript = null;
      _transcriptionService.startListening(
        localeId: _languageCode,
        onPartial: (text) {
          _liveTranscript = text;
          notifyListeners();
        },
      );
      return path;
    } catch (e) {
      _error = 'Failed to start recording: $e';
      notifyListeners();
      return null;
    }
  }

  Future<String?> stopRecording() async {
    try {
      _error = null;
      final filePath = await _audioService.stopRecording();
      // stop live transcription and hold text for next save
      final finalText = await _transcriptionService.stopListening();
      _liveTranscript = finalText ?? _liveTranscript;
      return filePath;
    } catch (e) {
      _error = 'Failed to stop recording: $e';
      notifyListeners();
      return null;
    }
  }

  /// Stop recording and return both the saved audio path and final transcript.
  /// Uses AudioService.stopRecordingAndGetTranscript for reliable finalization.
  Future<Map<String, String?>?> stopRecordingAndGetTranscript() async {
    try {
      _error = null;
      final result = await _audioService.stopRecordingAndGetTranscript();
      // Sync provider live transcript state for subsequent save if needed
      _liveTranscript = result['transcript'] ?? _liveTranscript;
      return result;
    } catch (e) {
      _error = 'Failed to stop recording: $e';
      notifyListeners();
      return null;
    }
  }

  // Playback methods
  Future<void> playVoiceNote(VoiceNote voiceNote) async {
    try {
      _error = null;
      if (_currentlyPlayingId == voiceNote.id.toString() && _isPlaying) {
        await _audioService.pausePlayback();
      } else if (_currentlyPlayingId == voiceNote.id.toString() &&
          !_isPlaying) {
        await _audioService.resumePlayback();
      } else {
        _currentlyPlayingId = voiceNote.id.toString();
        await _audioService.playAudio(voiceNote.filePath);
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to play voice note: $e';
      notifyListeners();
    }
  }

  Future<void> stopPlayback() async {
    try {
      _error = null;
      await _audioService.stopPlayback();
      _currentlyPlayingId = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to stop playback: $e';
      notifyListeners();
    }
  }

  Future<void> seekToPosition(Duration position) async {
    try {
      await _audioService.seekToPosition(position);
    } catch (e) {
      _error = 'Failed to seek: $e';
      notifyListeners();
    }
  }

  // CRUD operations
  Future<bool> saveVoiceNote({
    required String title,
    required String description,
    required String filePath,
    required List<String> tags,
    String? transcript,
  }) async {
    try {
      _error = null;

      // Get audio duration
      final duration = await _audioService.getAudioDuration(filePath);

      final voiceNote = VoiceNote(
        title: title,
        description: description,
        filePath: filePath,
        duration: duration,
        tags: tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        transcript: (transcript != null && transcript.trim().isNotEmpty)
            ? transcript.trim()
            : _liveTranscript,
        languageCode: _languageCode,
      );

      await _databaseService.insertVoiceNote(voiceNote);
      _liveTranscript = null;
      await loadVoiceNotes();
      await loadAllTags();
      return true;
    } catch (e) {
      _error = 'Failed to save voice note: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateVoiceNote({
    required VoiceNote voiceNote,
    String? title,
    String? description,
    List<String>? tags,
    String? transcript,
    bool? isFavorite,
    bool? isPinned,
  }) async {
    try {
      _error = null;

      final updatedNote = voiceNote.copyWith(
        title: title ?? voiceNote.title,
        description: description ?? voiceNote.description,
        tags: tags ?? voiceNote.tags,
        transcript: transcript ?? voiceNote.transcript,
        isFavorite: isFavorite ?? voiceNote.isFavorite,
        isPinned: isPinned ?? voiceNote.isPinned,
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateVoiceNote(updatedNote);
      await loadVoiceNotes();
      await loadAllTags();
      return true;
    } catch (e) {
      _error = 'Failed to update voice note: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteVoiceNote(VoiceNote voiceNote) async {
    try {
      _error = null;

      // Stop playback if this note is currently playing
      if (_currentlyPlayingId == voiceNote.id.toString()) {
        await stopPlayback();
      }

      // Delete the audio file
      await _audioService.deleteAudioFile(voiceNote.filePath);

      // Delete from database
      await _databaseService.deleteVoiceNote(voiceNote.id!);

      await loadVoiceNotes();
      await loadAllTags();
      return true;
    } catch (e) {
      _error = 'Failed to delete voice note: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
