import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import '../models/voice_note.dart';
import 'supabase_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _supabase = SupabaseService();

  Future<void> initialize() async {
    await _supabase.initialize();
  }

  Future<String?> uploadAudio(String userId, VoiceNote note) async {
    final client = _supabase.client;
    if (client == null) return null;
    final file = File(note.filePath);
    if (!await file.exists()) return null;

    final path = 'users/$userId/audio/note_${note.id ?? DateTime.now().millisecondsSinceEpoch}${p.extension(note.filePath)}';
    await client.storage.from('audio').upload(path, file, fileOptions: const FileOptions(upsert: true));
    final publicUrl = client.storage.from('audio').getPublicUrl(path);
    return publicUrl;
  }

  Future<String?> upsertNote(String userId, VoiceNote note, {String? audioUrl}) async {
    final client = _supabase.client;
    if (client == null) return null;

    final data = {
      'user_id': userId,
      'title': note.title,
      'description': note.description,
      'audio_url': audioUrl,
      'duration_ms': note.duration.inMilliseconds,
      'tags': note.tags,
      'created_at': note.createdAt.toIso8601String(),
      'updated_at': note.updatedAt.toIso8601String(),
      'transcript': note.transcript,
      'language_code': note.languageCode,
      'is_favorite': note.isFavorite,
      'is_pinned': note.isPinned,
      'summary': note.summary,
    };

    if ((note.remoteId ?? '').isEmpty) {
      final res = await client.from('notes').insert(data).select('id').single();
      return res['id'] as String?;
    } else {
      await client.from('notes').update(data).eq('id', note.remoteId).eq('user_id', userId);
      return note.remoteId;
    }
  }
}

