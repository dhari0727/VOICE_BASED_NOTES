import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/voice_note.dart';
import '../providers/voice_notes_provider.dart';

class AddEditNoteScreen extends StatefulWidget {
  final VoiceNote? voiceNote;
  final String? audioFilePath;

  const AddEditNoteScreen({super.key, this.voiceNote, this.audioFilePath})
    : assert(
        voiceNote != null || audioFilePath != null,
        'Either voiceNote or audioFilePath must be provided',
      );

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _transcriptController;
  late TextEditingController _tagController;
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _tagFocus = FocusNode();

  List<String> _tags = [];
  bool _isLoading = false;
  String? _error;

  bool get isEditing => widget.voiceNote != null;
  String get audioFilePath =>
      widget.audioFilePath ?? widget.voiceNote!.filePath;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    if (isEditing) {
      _titleController = TextEditingController(text: widget.voiceNote!.title);
      _descriptionController = TextEditingController(
        text: widget.voiceNote!.description,
      );
      _transcriptController = TextEditingController(
        text: widget.voiceNote!.transcript ?? '',
      );
      _tags = List.from(widget.voiceNote!.tags);
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _transcriptController = TextEditingController();
      _tags = [];
    }
    _tagController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _transcriptController.dispose();
    _tagController.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _tagFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Note' : 'Add Note'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveNote,
            child: Text(
              'Save',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAudioPlayer(),
            const SizedBox(height: 24),
            _buildTitleField(),
            const SizedBox(height: 16),
            _buildDescriptionField(),
            const SizedBox(height: 16),
            _buildTagsSection(),
          const SizedBox(height: 16),
          _buildTranscriptEditor(),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _buildErrorCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayer() {
    return Consumer<VoiceNotesProvider>(
      builder: (context, provider, child) {
        final isCurrentlyPlaying =
            isEditing
                ? provider.currentlyPlayingId == widget.voiceNote!.id.toString()
                : false;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.audio_file,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Audio Recording',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed:
                            isEditing
                                ? () =>
                                    provider.playVoiceNote(widget.voiceNote!)
                                : null,
                        icon: Icon(
                          isCurrentlyPlaying && provider.isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          size: 32,
                        ),
                        color:
                            isEditing
                                ? Theme.of(context).primaryColor
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.4),
                      ),
                      Expanded(
                        child: Slider(
                          value:
                              isCurrentlyPlaying &&
                                      provider.playbackDuration.inSeconds > 0
                                  ? (provider.playbackPosition.inSeconds /
                                          provider.playbackDuration.inSeconds)
                                      .clamp(0.0, 1.0)
                                  : 0.0,
                          onChanged:
                              isCurrentlyPlaying
                                  ? (value) {
                                    final newPosition = Duration(
                                      seconds:
                                          (value *
                                                  provider
                                                      .playbackDuration
                                                      .inSeconds)
                                              .round(),
                                    );
                                    provider.seekToPosition(newPosition);
                                  }
                                  : null,
                          activeColor: Theme.of(context).primaryColor,
                          inactiveColor: Colors.grey[300],
                        ),
                      ),
                      Text(
                        isCurrentlyPlaying
                            ? _formatDuration(provider.playbackPosition)
                            : isEditing
                            ? _formatDuration(widget.voiceNote!.duration)
                            : '00:00',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Title',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          focusNode: _titleFocus,
          decoration: InputDecoration(
            hintText: 'Enter a title for your note',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _descriptionFocus.requestFocus(),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description (Optional)',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          focusNode: _descriptionFocus,
          decoration: InputDecoration(
            hintText: 'Add a description for your note',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLines: 3,
          textInputAction: TextInputAction.newline,
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildTagInput(),
        if (_tags.isNotEmpty) ...[const SizedBox(height: 12), _buildTagsList()],
      ],
    );
  }

  Widget _buildTranscriptEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transcript',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _transcriptController,
          decoration: InputDecoration(
            hintText: 'Auto-generated or enter manually...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLines: 8,
        ),
      ],
    );
  }

  Widget _buildTagInput() {
    return TextFormField(
      controller: _tagController,
      focusNode: _tagFocus,
      decoration: InputDecoration(
        hintText: 'Add tags (press Enter to add)',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
        suffixIcon: IconButton(onPressed: _addTag, icon: const Icon(Icons.add)),
      ),
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _addTag(),
    );
  }

  Widget _buildTagsList() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          _tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tag,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _removeTag(tag),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter a title for your note';
      });
      _titleFocus.requestFocus();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final provider = context.read<VoiceNotesProvider>();

    bool success;
    if (isEditing) {
      success = await provider.updateVoiceNote(
        voiceNote: widget.voiceNote!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: _tags,
        transcript: _transcriptController.text.trim(),
      );
    } else {
      success = await provider.saveVoiceNote(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        filePath: audioFilePath,
        tags: _tags,
      );
      // If there was a live transcript, persist edits if any
      if (success && _transcriptController.text.trim().isNotEmpty) {
        // reload to get the newly created note id and allow later edits; UI already refreshes
      }
    }

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Note updated!' : 'Note saved!'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } else {
      setState(() {
        _error = provider.error ?? 'Failed to save note';
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}
