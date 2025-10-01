import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/voice_note.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'voicenotes.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE voice_notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        filePath TEXT NOT NULL,
        duration INTEGER NOT NULL,
        tags TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        transcript TEXT,
        languageCode TEXT,
        isFavorite INTEGER DEFAULT 0,
        isPinned INTEGER DEFAULT 0
      )
    ''');

    // Create optional FTS5 table for transcript search if supported
    await _createFtsObjects(db);
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns if they do not already exist
      await _safeAddColumn(db, 'voice_notes', 'transcript', 'TEXT');
      await _safeAddColumn(db, 'voice_notes', 'languageCode', 'TEXT');
      await _safeAddColumn(db, 'voice_notes', 'isFavorite', 'INTEGER DEFAULT 0');
      await _safeAddColumn(db, 'voice_notes', 'isPinned', 'INTEGER DEFAULT 0');
      await _createFtsObjects(db);
    }
  }

  Future<void> _safeAddColumn(Database db, String table, String column, String type) async {
    final List<Map<String, Object?>> columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((c) => (c['name'] as String?) == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  Future<void> _createFtsObjects(Database db) async {
    // Create a contentless FTS5 table for transcript text, synchronized via triggers
    try {
      await db.execute('''
        CREATE VIRTUAL TABLE IF NOT EXISTS voice_notes_fts USING fts5(
          note_id UNINDEXED,
          transcript,
          content=''
        )
      ''');

      // Seed existing data
      await db.execute('''
        INSERT INTO voice_notes_fts(note_id, transcript)
        SELECT id, COALESCE(transcript, '') FROM voice_notes
      ''');

      // Triggers to keep FTS in sync
      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS voice_notes_ai AFTER INSERT ON voice_notes BEGIN
          INSERT INTO voice_notes_fts(note_id, transcript) VALUES (NEW.id, COALESCE(NEW.transcript, ''));
        END;
      ''');

      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS voice_notes_au AFTER UPDATE ON voice_notes BEGIN
          UPDATE voice_notes_fts SET transcript = COALESCE(NEW.transcript, '') WHERE note_id = NEW.id;
        END;
      ''');

      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS voice_notes_ad AFTER DELETE ON voice_notes BEGIN
          DELETE FROM voice_notes_fts WHERE note_id = OLD.id;
        END;
      ''');
    } catch (_) {
      // If FTS5 is unavailable on the platform, ignore and fall back to LIKE queries
    }
  }

  // Create a new voice note
  Future<int> insertVoiceNote(VoiceNote voiceNote) async {
    final db = await database;
    return await db.insert('voice_notes', voiceNote.toMap());
  }

  // Get all voice notes
  Future<List<VoiceNote>> getAllVoiceNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'voice_notes',
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return VoiceNote.fromMap(maps[i]);
    });
  }

  // Get a voice note by ID
  Future<VoiceNote?> getVoiceNoteById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'voice_notes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return VoiceNote.fromMap(maps.first);
    }
    return null;
  }

  // Update a voice note
  Future<int> updateVoiceNote(VoiceNote voiceNote) async {
    final db = await database;
    return await db.update(
      'voice_notes',
      voiceNote.toMap(),
      where: 'id = ?',
      whereArgs: [voiceNote.id],
    );
  }

  // Delete a voice note
  Future<int> deleteVoiceNote(int id) async {
    final db = await database;
    return await db.delete('voice_notes', where: 'id = ?', whereArgs: [id]);
  }

  // Search voice notes by title, tags, or transcript (FTS if available)
  Future<List<VoiceNote>> searchVoiceNotes(String query) async {
    final db = await database;

    // Try FTS first
    try {
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT vn.* FROM voice_notes vn
        LEFT JOIN voice_notes_fts fts ON fts.note_id = vn.id
        WHERE vn.title LIKE ? OR vn.tags LIKE ? OR (fts.transcript MATCH ?)
        ORDER BY vn.updatedAt DESC
      ''', ['%$query%', '%$query%', query]);

      if (maps.isNotEmpty) {
        return List.generate(maps.length, (i) => VoiceNote.fromMap(maps[i]));
      }
    } catch (_) {
      // Fallback to LIKE on transcript if FTS is not available
    }

    final List<Map<String, dynamic>> fallbackMaps = await db.query(
      'voice_notes',
      where: 'title LIKE ? OR tags LIKE ? OR transcript LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'updatedAt DESC',
    );

    return List.generate(fallbackMaps.length, (i) => VoiceNote.fromMap(fallbackMaps[i]));
  }

  // Get voice notes by tag
  Future<List<VoiceNote>> getVoiceNotesByTag(String tag) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'voice_notes',
      where: 'tags LIKE ?',
      whereArgs: ['%$tag%'],
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return VoiceNote.fromMap(maps[i]);
    });
  }

  // Get all unique tags
  Future<List<String>> getAllTags() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'voice_notes',
      columns: ['tags'],
    );

    Set<String> allTags = {};
    for (var map in maps) {
      if (map['tags'] != null && map['tags'].toString().isNotEmpty) {
        allTags.addAll(map['tags'].toString().split(','));
      }
    }

    return allTags.toList()..sort();
  }

  // Close database connection
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
