import 'package:flutter/material.dart';
import '../models/voice_note.dart';
import '../services/export_service.dart';
import 'package:share_plus/share_plus.dart';

class ExportScreen extends StatefulWidget {
  final VoiceNote note;
  const ExportScreen({super.key, required this.note});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Note')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.note.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              onTap: _busy ? null : _exportPdf,
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet),
              title: const Text('Export as Text'),
              onTap: _busy ? null : _exportText,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Colors.red[700])),
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    setState(() { _busy = true; _error = null; });
    try {
      final file = await ExportService().exportNoteAsPdf(widget.note);
      await Share.shareXFiles([XFile(file.path)], text: widget.note.title);
    } catch (e) {
      setState(() { _error = 'Export failed: $e'; });
    } finally {
      setState(() { _busy = false; });
    }
  }

  Future<void> _exportText() async {
    setState(() { _busy = true; _error = null; });
    try {
      final file = await ExportService().exportNoteAsText(widget.note);
      await Share.shareXFiles([XFile(file.path)], text: widget.note.title);
    } catch (e) {
      setState(() { _error = 'Export failed: $e'; });
    } finally {
      setState(() { _busy = false; });
    }
  }
}


