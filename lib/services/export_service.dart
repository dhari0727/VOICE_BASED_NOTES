import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../models/voice_note.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  Future<File> exportNoteAsText(VoiceNote note) async {
    final buffer = StringBuffer()
      ..writeln(note.title)
      ..writeln('')
      ..writeln('Description: ${note.description}')
      ..writeln('Tags: ${note.tags.join(', ')}')
      ..writeln('Priority: ${note.priority}')
      ..writeln('Created: ${note.createdAt}')
      ..writeln('Updated: ${note.updatedAt}')
      ..writeln('')
      ..writeln('Transcript:')
      ..writeln(note.transcript ?? '');

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/note_${note.id ?? DateTime.now().millisecondsSinceEpoch}.txt');
    return file.writeAsString(buffer.toString());
  }

  Future<File> exportNoteAsPdf(VoiceNote note) async {
    final pdf = pw.Document();

    final contentStyle = pw.TextStyle(fontSize: 12);
    final titleStyle = pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Text(note.title, style: titleStyle),
          pw.SizedBox(height: 8),
          pw.Text('Description: ${note.description}', style: contentStyle),
          pw.SizedBox(height: 4),
          pw.Text('Tags: ${note.tags.join(', ')}', style: contentStyle),
          pw.Text('Priority: ${note.priority}', style: contentStyle),
          pw.SizedBox(height: 6),
          pw.Text('Created: ${note.createdAt}', style: contentStyle),
          pw.Text('Updated: ${note.updatedAt}', style: contentStyle),
          pw.SizedBox(height: 12),
          pw.Text('Transcript', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text(note.transcript ?? '', style: contentStyle),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/note_${note.id ?? DateTime.now().millisecondsSinceEpoch}.pdf');
    final bytes = await pdf.save();
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> printPdf(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }
}


