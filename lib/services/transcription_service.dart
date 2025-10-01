import 'package:speech_to_text/speech_to_text.dart' as stt;

class TranscriptionService {
  static final TranscriptionService _instance = TranscriptionService._internal();
  factory TranscriptionService() => _instance;
  TranscriptionService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;
  bool _listening = false;
  String _buffer = '';

  Future<bool> initialize() async {
    _available = await _speech.initialize();
    return _available;
  }

  bool get isAvailable => _available;
  bool get isListening => _listening;
  String get currentTranscript => _buffer;

  Future<String?> transcribeLive({
    String localeId = 'en_US',
    Duration listenFor = const Duration(seconds: 60),
    Duration pauseFor = const Duration(seconds: 3),
    Function(String partial)? onPartial,
  }) async {
    if (!_available) {
      final ok = await initialize();
      if (!ok) return null;
    }

    String buffer = '';
    await _speech.listen(
      localeId: localeId,
      listenFor: listenFor,
      pauseFor: pauseFor,
      onResult: (result) {
        buffer = result.recognizedWords;
        if (result.hasConfidenceRating || result.finalResult) {
          onPartial?.call(buffer);
        }
      },
      partialResults: true,
    );

    await _speech.stop();
    return buffer.isEmpty ? null : buffer;
  }

  Future<void> startListening({
    String localeId = 'en_US',
    Duration listenFor = const Duration(minutes: 15),
    Duration pauseFor = const Duration(seconds: 3),
    Function(String partial)? onPartial,
  }) async {
    if (!_available) {
      final ok = await initialize();
      if (!ok) return;
    }
    _buffer = '';
    _listening = true;
    await _speech.listen(
      localeId: localeId,
      listenFor: listenFor,
      pauseFor: pauseFor,
      onResult: (result) {
        _buffer = result.recognizedWords;
        onPartial?.call(_buffer);
      },
      partialResults: true,
    );
  }

  Future<String?> stopListening() async {
    if (!_listening) return _buffer.isEmpty ? null : _buffer;
    await _speech.stop();
    _listening = false;
    return _buffer.isEmpty ? null : _buffer;
  }
}

