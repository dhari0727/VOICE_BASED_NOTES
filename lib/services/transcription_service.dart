import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Service that wraps speech_to_text and provides simple live transcription.
class TranscriptionService {
  static final TranscriptionService _instance = TranscriptionService._internal();
  factory TranscriptionService() => _instance;
  TranscriptionService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;
  bool _listening = false;
  String _buffer = '';

  /// Initialize the underlying speech engine. Safe to call multiple times.
  Future<bool> initialize() async {
    if (_available) return true;
    try {
      _available = await _speech.initialize(onStatus: (_) {}, onError: (_) {});
      return _available;
    } catch (e) {
      // ignore: avoid_print
      print('Transcription initialize failed: $e');
      _available = false;
      return false;
    }
  }

  bool get isAvailable => _available;
  bool get isListening => _listening;
  String get currentTranscript => _buffer;

  /// Start listening with partial results. Returns true if listening started.
  Future<bool> startListening({
    String localeId = 'en_US',
    Duration listenFor = const Duration(minutes: 15),
    Duration pauseFor = const Duration(seconds: 2),
    Function(String partial)? onPartial,
  }) async {
    if (!_available) {
      final ok = await initialize();
      if (!ok) return false;
    }

    try {
      _buffer = '';
      final started = await _speech.listen(
        localeId: localeId,
        listenFor: listenFor,
        pauseFor: pauseFor,
        partialResults: true,
        onResult: (result) {
          final text = (result.recognizedWords ?? '').trim();
          if (text.isNotEmpty) {
            _buffer = text;
            // Emit on every partial and final
            onPartial?.call(_buffer);
          }
        },
      );
      _listening = started;
      return started;
    } catch (e) {
      // ignore: avoid_print
      print('startListening error: $e');
      _listening = false;
      return false;
    }
  }

  /// Stop listening and return the final transcript if any.
  Future<String?> stopListening() async {
    try {
      if (_listening) {
        await _speech.stop();
      }
      _listening = false;
      final text = _buffer.trim();
      return text.isEmpty ? null : text;
    } catch (e) {
      // ignore: avoid_print
      print('stopListening error: $e');
      _listening = false;
      return _buffer.trim().isEmpty ? null : _buffer.trim();
    }
  }
}

