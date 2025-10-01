import 'dart:async';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'supabase_service.dart';
import '../models/voice_note.dart';

class RealtimeShareService {
  static final RealtimeShareService _instance = RealtimeShareService._internal();
  factory RealtimeShareService() => _instance;
  RealtimeShareService._internal();

  final SupabaseService _supabase = SupabaseService();

  Future<void> shareNoteRealtime(VoiceNote note) async {
    if (!SupabaseConfig.isConfigured) {
      await shareNoteFallback(note);
      return;
    }
    await _supabase.initialize();
    final client = _supabase.client!;
    await client.from('shared_notes').insert({
      'title': note.title,
      'transcript': note.transcript,
      'created_at': DateTime.now().toIso8601String(),
      'sender_id': client.auth.currentUser?.id,
      'priority': note.priority,
      'tags': note.tags.join(','),
      'path_url': note.filePath,
    });
  }

  Stream<VoiceNote> subscribeToSharedNotes() async* {
    if (!SupabaseConfig.isConfigured) {
      yield* const Stream.empty();
      return;
    }
    await _supabase.initialize();
    final client = _supabase.client!;
    final stream = client
        .from('shared_notes')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((rows) => rows.map((r) => _mapRow(r)))
        .asyncExpand((notes) => Stream.fromIterable(notes));
    yield* stream;
  }

  VoiceNote _mapRow(Map<String, dynamic> r) {
    return VoiceNote(
      id: r['id'],
      title: r['title'] ?? 'Shared note',
      description: '',
      filePath: r['path_url'] ?? '',
      duration: const Duration(seconds: 0),
      tags: (r['tags'] as String?)?.split(',') ?? <String>[],
      createdAt: DateTime.tryParse(r['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(r['created_at'] ?? '') ?? DateTime.now(),
      transcript: r['transcript'],
      languageCode: null,
      isFavorite: false,
      isPinned: false,
      priority: (r['priority'] ?? 1),
      attachments: const [],
      reminderAt: null,
    );
  }

  Future<void> shareNoteFallback(VoiceNote note) async {
    final text = StringBuffer();
    if (note.title.isNotEmpty) text.writeln(note.title);
    if ((note.transcript ?? '').isNotEmpty) text.writeln('\n${note.transcript}');
    if (note.filePath.isNotEmpty) text.writeln('\nFile: ${note.filePath}');
    await Share.share(text.toString());
  }
}


