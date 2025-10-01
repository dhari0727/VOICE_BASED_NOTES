import 'package:flutter/material.dart';
import '../models/voice_note.dart';
import '../services/database_service.dart';
import '../services/audio_service.dart';
import '../services/transcription_service.dart';
import '../services/notification_service.dart';

class VoiceNotesProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final AudioService _audioService = AudioService();
  final TranscriptionService _transcriptionService = TranscriptionService();
  final NotificationService _notificationService = NotificationService();

  List<VoiceNote> _voiceNotes = [];
  List<VoiceNote> get voiceNotes => _voiceNotes;

  List<String> _allTags = [];
  List<String> get allTags => _allTags;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String? _selectedTag;
  String? get selectedTag => _selectedTag;

  int? _selectedPriority; // null = all
  int? get selectedPriority => _selectedPriority;

  String _sortKey = 'updated_desc';
  String get sortKey => _sortKey; // 'updated_desc' | 'created_asc' | 'priority_desc'

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

    // Wire live transcription from AudioService
    _audioService.onTranscriptPartial = (String partial) {
      _liveTranscript = partial;
      notifyListeners();
    };
    _audioService.onTranscriptFinal = (String finalText) {
      _liveTranscript = finalText;
      notifyListeners();
    };
  }

  Future<void> loadVoiceNotes() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final orderBy = _orderByClause();

      if (_searchQuery.isNotEmpty) {
        _voiceNotes = await _databaseService.searchVoiceNotes(_searchQuery);
      } else if (_selectedTag != null) {
        _voiceNotes = await _databaseService.getVoiceNotesByTag(_selectedTag!);
      } else if (_selectedPriority != null) {
        _voiceNotes = await _databaseService.getVoiceNotesByPriority(_selectedPriority!, orderBy: orderBy);
      } else {
        _voiceNotes = await _databaseService.getAllVoiceNotes(orderBy: orderBy);
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
    _selectedPriority = null;
    loadVoiceNotes();
  }

  void setPriorityFilter(int? priority) {
    _selectedPriority = priority;
    loadVoiceNotes();
  }

  void setSortKey(String key) {
    _sortKey = key;
    loadVoiceNotes();
  }

  String _orderByClause() {
    switch (_sortKey) {
      case 'created_asc':
        return 'createdAt ASC';
      case 'priority_desc':
        return 'priority DESC, updatedAt DESC';
      case 'updated_desc':
      default:
        return 'updatedAt DESC';
    }
  }

  // Recording methods
  Future<String?> startRecording() async {
    try {
      _error = null;
      final path = await _audioService.startRecording();
      // Reset live transcript; AudioService will emit partials/finals
      _liveTranscript = null;
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
      // stop live transcription and hold text for next save (AudioService has it)
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
    int priority = 1,
    List<String> attachments = const [],
    DateTime? reminderAt,
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
        priority: priority,
        attachments: attachments,
        reminderAt: reminderAt,
      );

      await _databaseService.insertVoiceNote(voiceNote);
      // If a reminder is set, schedule it using a temporary ID based on timestamp is not ideal.
      // After insert, reload to fetch the DB id and then schedule. For simplicity, attempt quick reload.
      await loadVoiceNotes();
      try {
        final inserted = _voiceNotes.firstWhere((n) =>
            n.filePath == voiceNote.filePath && n.createdAt.millisecondsSinceEpoch == voiceNote.createdAt.millisecondsSinceEpoch);
        if (voiceNote.reminderAt != null && inserted.id != null) {
          await _notificationService.scheduleNoteReminder(
            noteId: inserted.id!,
            title: voiceNote.title.isNotEmpty ? voiceNote.title : 'Voice Note Reminder',
            body: voiceNote.description.isNotEmpty ? voiceNote.description : (voiceNote.transcript ?? ''),
            when: voiceNote.reminderAt!,
          );
        }
      } catch (_) {}
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
      if (voiceNote.id != null) {
        // cancel any existing reminder first
        await _notificationService.cancelReminder(voiceNote.id!);
        if (updatedNote.reminderAt != null) {
          await _notificationService.scheduleNoteReminder(
            noteId: voiceNote.id!,
            title: updatedNote.title,
            body: updatedNote.description.isNotEmpty ? updatedNote.description : (updatedNote.transcript ?? ''),
            when: updatedNote.reminderAt!,
          );
        }
      }
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
