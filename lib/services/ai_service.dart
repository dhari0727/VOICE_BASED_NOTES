import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // Configure via --dart-define=OPENAI_API_KEY=...
  static const String _apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  Future<String?> summarizeTranscript(String transcript, {String model = 'gpt-4o-mini'}) async {
    if (_apiKey.isEmpty || transcript.trim().isEmpty) return null;
    final payload = {
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content': 'You summarize audio note transcripts concisely (3-5 bullet points).'
        },
        {'role': 'user', 'content': transcript}
      ],
      'temperature': 0.2,
    };
    final res = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>;
      if (choices.isNotEmpty) {
        return choices.first['message']['content'] as String?;
      }
    }
    return null;
  }
}

