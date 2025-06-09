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

    return await openDatabase(path, version: 1, onCreate: _createDatabase);
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
        updatedAt INTEGER NOT NULL
      )
    ''');
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

  // Search voice notes by title or tags
  Future<List<VoiceNote>> searchVoiceNotes(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'voice_notes',
      where: 'title LIKE ? OR tags LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return VoiceNote.fromMap(maps[i]);
    });
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
