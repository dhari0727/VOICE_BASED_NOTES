import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_notes_provider.dart';
import '../screens/add_edit_note_screen.dart';

class RecordingFAB extends StatefulWidget {
  const RecordingFAB({super.key});

  @override
  State<RecordingFAB> createState() => _RecordingFABState();
}

class _RecordingFABState extends State<RecordingFAB>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceNotesProvider>(
      builder: (context, provider, child) {
        if (provider.isRecording) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }

        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: provider.isRecording ? _pulseAnimation.value : 1.0,
              child: FloatingActionButton.large(
                onPressed: () => _handleFABPressed(context, provider),
                backgroundColor:
                    provider.isRecording
                        ? const Color(0xFFE17055)
                        : const Color(0xFF6C5CE7),
                elevation: 8,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      provider.isRecording ? Icons.stop : Icons.mic,
                      size: 32,
                      color: Colors.white,
                    ),
                    if (provider.isRecording)
                      Positioned(
                        bottom: 8,
                        child: Text(
                          _formatDuration(provider.recordingDuration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleFABPressed(
    BuildContext context,
    VoiceNotesProvider provider,
  ) async {
    if (provider.isRecording) {
      // Stop recording and fetch final transcript
      final result = await provider.stopRecordingAndGetTranscript();
      if (result != null && result['path'] != null) {
        final initialTranscript =
            (result['transcript'] != null && result['transcript']!.trim().isNotEmpty)
                ? result['transcript']
                : provider.liveTranscript;
        _navigateToAddNote(
          context,
          result['path']!,
          initialTranscript: initialTranscript,
        );
      } else if (provider.error != null) {
        _showErrorSnackBar(context, provider.error!);
      }
    } else {
      // Start recording
      final filePath = await provider.startRecording();
      if (filePath == null && provider.error != null) {
        _showErrorSnackBar(context, provider.error!);
      }
    }
  }

  void _navigateToAddNote(BuildContext context, String filePath, {String? initialTranscript}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditNoteScreen(
          audioFilePath: filePath,
          initialTranscript: initialTranscript,
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}
