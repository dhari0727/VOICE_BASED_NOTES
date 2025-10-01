import 'dart:io';
import 'package:flutter/material.dart';

class AttachmentViewerScreen extends StatefulWidget {
  final List<String> imagePaths;
  final String initialPath;

  const AttachmentViewerScreen({super.key, required this.imagePaths, required this.initialPath});

  @override
  State<AttachmentViewerScreen> createState() => _AttachmentViewerScreenState();
}

class _AttachmentViewerScreenState extends State<AttachmentViewerScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.imagePaths.indexOf(widget.initialPath);
    if (_index < 0) _index = 0;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('${_index + 1}/${widget.imagePaths.length}', style: const TextStyle(color: Colors.white)),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.imagePaths.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) {
          final path = widget.imagePaths[i];
          return InteractiveViewer(
            child: Center(
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}


