import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart' as audio;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voice_based_notes/services/transcription_service.dart';

enum AudioState { recording, playing, paused, stopped, ready }

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  FlutterSoundRecorder? _recorder;
  audio.AudioPlayer? _player;
  String? _currentRecordingPath;
  String? _currentPlayingPath;

  // Transcription wiring: enable live partials and final transcript callbacks
  final TranscriptionService _transcription = TranscriptionService();
  Function(String)? onTranscriptPartial;
  Function(String)? onTranscriptFinal;

  AudioState _state = AudioState.stopped;
  AudioState get state => _state;

  Duration _recordingDuration = Duration.zero;
  Duration get recordingDuration => _recordingDuration;

  Duration _playbackDuration = Duration.zero;
  Duration get playbackDuration => _playbackDuration;

  Duration _playbackPosition = Duration.zero;
  Duration get playbackPosition => _playbackPosition;

  Function(AudioState)? onStateChanged;
  Function(Duration)? onRecordingDurationChanged;
  Function(Duration)? onPlaybackPositionChanged;
  Function(Duration)? onPlaybackDurationChanged;

  Future<void> initialize() async {
    _recorder = FlutterSoundRecorder();
    _player = audio.AudioPlayer();

    await _recorder!.openRecorder();

    // Set up player event listeners
    _player!.onDurationChanged.listen((Duration duration) {
      _playbackDuration = duration;
      onPlaybackDurationChanged?.call(duration);
    });

    _player!.onPositionChanged.listen((Duration position) {
      _playbackPosition = position;
      onPlaybackPositionChanged?.call(position);
    });

    _player!.onPlayerStateChanged.listen((audio.PlayerState state) {
      switch (state) {
        case audio.PlayerState.stopped:
          _updateState(AudioState.stopped);
          break;
        case audio.PlayerState.playing:
          _updateState(AudioState.playing);
          break;
        case audio.PlayerState.paused:
          _updateState(AudioState.paused);
          break;
        case audio.PlayerState.completed:
          _currentPlayingPath = null;
          _playbackPosition = Duration.zero;
          _updateState(AudioState.stopped);
          break;
        default:
          break;
      }
    });

    _updateState(AudioState.ready);
  }

  Future<bool> requestPermissions() async {
    try {
      // Check current microphone permission status
      var microphoneStatus = await Permission.microphone.status;
      print('Current microphone permission status: $microphoneStatus');

      // Request microphone permission if not granted
      if (microphoneStatus != PermissionStatus.granted) {
        microphoneStatus = await Permission.microphone.request();
        print('Microphone permission after request: $microphoneStatus');
      }

      // Handle different permission states
      if (microphoneStatus == PermissionStatus.permanentlyDenied) {
        throw Exception(
          'Microphone permission permanently denied. Please enable it in system settings.',
        );
      }

      if (microphoneStatus != PermissionStatus.granted) {
        print('Microphone permission not granted: $microphoneStatus');
        return false;
      }

      // On macOS and iOS, storage permission might not be needed
      if (Platform.isIOS || Platform.isMacOS) {
        return true;
      }

      // For Android, we're using app's internal storage (getApplicationDocumentsDirectory)
      // which doesn't require special permissions since Android 10
      // Only need microphone permission for recording
      if (Platform.isAndroid) {
        print('Android detected - checking if we need additional permissions');

        // Try to get a storage status for debugging, but don't require it
        try {
          var storageStatus = await Permission.storage.status;
          print('Storage permission status (for info only): $storageStatus');
        } catch (e) {
          print('Could not check storage permission (this is OK): $e');
        }

        // For Android, microphone permission is sufficient since we use internal storage
        return microphoneStatus == PermissionStatus.granted;
      }

      return microphoneStatus == PermissionStatus.granted;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  Future<String?> startRecording() async {
    if (!await requestPermissions()) {
      throw Exception(
        'Microphone permission not granted. Please allow microphone access in your system settings and try again.',
      );
    }

    if (_recorder == null) {
      throw Exception('Recorder not initialized');
    }

    if (_state == AudioState.recording) {
      throw Exception('Already recording');
    }

    try {
      // Create unique filename
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.aac';
      _currentRecordingPath = '${directory.path}/$fileName';

      await _recorder!.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacADTS,
      );

      _updateState(AudioState.recording);
      _startRecordingTimer();

      // Best-effort transcription start (non-blocking, errors are logged only)
      // Initialize is idempotent per TranscriptionService contract
      try {
        final ok = await _transcription.initialize();
        if (ok) {
          await _transcription.startListening(
            onPartial: (s) {
              final partial = s.trim();
              if (partial.isNotEmpty) {
                onTranscriptPartial?.call(partial);
              }
            },
          );
        } else {
          // Do not interrupt recording if transcription unavailable
          // Keep a helpful log for debugging
          // ignore: avoid_print
          print('Transcription unavailable — proceeding with audio-only recording');
        }
      } catch (e, st) {
        // Non-blocking failure
        // ignore: avoid_print
        print('Failed to start transcription: $e');
        // ignore: avoid_print
        print(st);
      }

      return _currentRecordingPath;
    } catch (e) {
      throw Exception('Failed to start recording: $e');
    }
  }

  Future<String?> stopRecording() async {
    if (_recorder == null || _state != AudioState.recording) {
      throw Exception('Not currently recording');
    }

    try {
      await _recorder!.stopRecorder();
      _updateState(AudioState.stopped);

      final recordingPath = _currentRecordingPath;
      _currentRecordingPath = null;
      _recordingDuration = Duration.zero;

      return recordingPath;
    } catch (e) {
      throw Exception('Failed to stop recording: $e');
    }
  }

  /// Stop recording and return both the saved file path and the final transcript.
  /// This method preserves backward compatibility by not altering `stopRecording()`
  /// semantics; it captures the path before stopping to ensure it is available
  /// even if the underlying field is cleared by other flows.
  Future<Map<String, String?>> stopRecordingAndGetTranscript() async {
    if (_recorder == null || _state != AudioState.recording) {
      throw Exception('Not currently recording');
    }

    // Capture current path before stopping (in case other flows clear it)
    final pathBeforeStop = _currentRecordingPath;

    String? transcript;
    try {
      await _recorder!.stopRecorder();
      _updateState(AudioState.stopped);
    } catch (e) {
      throw Exception('Failed to stop recording: $e');
    } finally {
      // Reset recording timer/state bookkeeping
      _recordingDuration = Duration.zero;
      _currentRecordingPath = null;
    }

    // Best-effort: stop listening and read final transcript
    try {
      final finalText = await _transcription.stopListening();
      transcript = finalText?.trim().isEmpty == true ? null : finalText?.trim();
      if ((transcript ?? '').isNotEmpty) {
        onTranscriptFinal?.call(transcript!);
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('Failed to finalize transcription: $e');
      // ignore: avoid_print
      print(st);
      transcript = null;
    }

    return {
      'path': pathBeforeStop,
      'transcript': transcript,
    };
  }

  Future<void> playAudio(String filePath) async {
    if (_player == null) {
      throw Exception('Player not initialized');
    }

    if (_state == AudioState.playing && _currentPlayingPath == filePath) {
      return; // Already playing this file
    }

    try {
      if (_state == AudioState.playing) {
        await stopPlayback();
      }

      _currentPlayingPath = filePath;
      await _player!.play(audio.DeviceFileSource(filePath));
    } catch (e) {
      throw Exception('Failed to play audio: $e');
    }
  }

  Future<void> pausePlayback() async {
    if (_player == null || _state != AudioState.playing) {
      return;
    }

    try {
      await _player!.pause();
    } catch (e) {
      throw Exception('Failed to pause playback: $e');
    }
  }

  Future<void> resumePlayback() async {
    if (_player == null || _state != AudioState.paused) {
      return;
    }

    try {
      await _player!.resume();
    } catch (e) {
      throw Exception('Failed to resume playback: $e');
    }
  }

  Future<void> stopPlayback() async {
    if (_player == null) {
      return;
    }

    try {
      await _player!.stop();
      _currentPlayingPath = null;
      _playbackPosition = Duration.zero;
    } catch (e) {
      throw Exception('Failed to stop playback: $e');
    }
  }

  Future<void> seekToPosition(Duration position) async {
    if (_player == null || _currentPlayingPath == null) {
      return;
    }

    try {
      await _player!.seek(position);
    } catch (e) {
      throw Exception('Failed to seek: $e');
    }
  }

  Future<Duration> getAudioDuration(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return Duration.zero;
      }

      final tempPlayer = audio.AudioPlayer();
      await tempPlayer.setSource(audio.DeviceFileSource(filePath));

      Duration? duration;
      tempPlayer.onDurationChanged.listen((d) {
        duration = d;
      });

      // Wait a bit for duration to be loaded
      await Future.delayed(const Duration(milliseconds: 100));
      await tempPlayer.dispose();

      return duration ?? Duration.zero;
    } catch (e) {
      return Duration.zero;
    }
  }

  void _updateState(AudioState newState) {
    if (_state != newState) {
      _state = newState;
      onStateChanged?.call(_state);
    }
  }

  void _startRecordingTimer() {
    if (_state != AudioState.recording) return;

    _recordingDuration = Duration.zero;

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_state == AudioState.recording) {
        _recordingDuration = Duration(
          seconds: _recordingDuration.inSeconds + 1,
        );
        onRecordingDurationChanged?.call(_recordingDuration);
        return true;
      }
      return false;
    });
  }

  Future<void> dispose() async {
    try {
      if (_state == AudioState.recording) {
        await stopRecording();
      }
      if (_state == AudioState.playing) {
        await stopPlayback();
      }

      await _recorder?.closeRecorder();
      await _player?.dispose();

      _recorder = null;
      _player = null;
    } catch (e) {
      // Handle cleanup errors gracefully
    }
  }

  // Helper method to delete audio file
  Future<bool> deleteAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Debug method to check permission status
  Future<Map<String, String>> debugPermissionStatus() async {
    try {
      final micStatus = await Permission.microphone.status;

      Map<String, String> result = {
        'microphone': micStatus.toString(),
        'platform': Platform.operatingSystem,
      };

      // Only check storage on Android for debugging
      if (Platform.isAndroid) {
        try {
          final storageStatus = await Permission.storage.status;
          result['storage'] = storageStatus.toString();
        } catch (e) {
          result['storage_error'] = e.toString();
        }
      }

      // Test permission request
      final requestResult = await requestPermissions();
      result['requestResult'] = requestResult.toString();

      // Test if we can access the directory where recordings will be saved
      try {
        final directory = await getApplicationDocumentsDirectory();
        result['documentsDirectory'] = directory.path;
        result['directoryExists'] = directory.existsSync().toString();
      } catch (e) {
        result['directoryError'] = e.toString();
      }

      return result;
    } catch (e) {
      return {'error': e.toString(), 'platform': Platform.operatingSystem};
    }
  }
}
