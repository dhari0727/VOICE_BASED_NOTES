import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/voice_note.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  Future<File> exportAsTxt(VoiceNote note) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/note_${note.id ?? DateTime.now().millisecondsSinceEpoch}.txt');
    final content = StringBuffer()
      ..writeln(note.title)
      ..writeln('Duration: ${note.duration.inSeconds}s')
      ..writeln('Created: ${note.createdAt.toIso8601String()}')
      ..writeln('Tags: ${note.tags.join(', ')}')
      ..writeln('\nTranscript:\n')
      ..writeln(note.transcript ?? '');
    await file.writeAsString(content.toString());
    return file;
  }

  Future<File> exportAsPdf(VoiceNote note) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(note.title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Duration: ${note.duration.inSeconds}s'),
            pw.Text('Created: ${note.createdAt.toIso8601String()}'),
            if (note.tags.isNotEmpty) pw.Text('Tags: ${note.tags.join(', ')}'),
            if ((note.summary ?? '').isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Text('Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text(note.summary!),
            ],
            pw.SizedBox(height: 12),
            pw.Text('Transcript', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text(note.transcript ?? ''),
          ],
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/note_${note.id ?? DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<File> exportAudio(VoiceNote note) async {
    // Just return the existing audio file path as a File reference (copy if needed)
    return File(note.filePath);
  }

  Future<void> shareFiles(List<File> files, {String? subject, String? text}) async {
    await Share.shareXFiles(files.map((f) => XFile(f.path)).toList(), subject: subject, text: text);
  }
}

