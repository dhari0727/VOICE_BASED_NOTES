import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import '../providers/voice_notes_provider.dart';
import '../models/voice_note.dart';
import '../widgets/voice_note_card.dart';
import '../widgets/recording_fab.dart';
import '../widgets/simple_header.dart';
import '../services/audio_service.dart';
import 'add_edit_note_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoiceNotesProvider>().loadVoiceNotes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<VoiceNotesProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                SimpleHeader(
                  searchController: _searchController,
                  onSearchChanged: (query) {
                    provider.searchVoiceNotes(query);
                  },
                  allTags: provider.allTags,
                  selectedTag: provider.selectedTag,
                  onTagSelected: (tag) {
                    provider.filterByTag(tag);
                  },
                  onClearFilters: () {
                    _searchController.clear();
                    provider.clearFilters();
                  },
                ),
                if (provider.error != null)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            provider.error!,
                            style: TextStyle(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: provider.clearError,
                          icon: const Icon(Icons.close),
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child:
                      provider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : provider.voiceNotes.isEmpty
                          ? _buildEmptyState(context, provider)
                          : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: provider.voiceNotes.length,
                            itemBuilder: (context, index) {
                              final note = provider.voiceNotes[index];
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: VoiceNoteCard(
                                        voiceNote: note,
                                        onPlay:
                                            () => provider.playVoiceNote(note),
                                        onEdit:
                                            () => _navigateToEditNote(
                                              context,
                                              note,
                                            ),
                                        onDelete:
                                            () => _showDeleteDialog(
                                              context,
                                              note,
                                            ),
                                        isPlaying:
                                            provider.currentlyPlayingId ==
                                            note.id.toString(),
                                        playbackPosition:
                                            provider.playbackPosition,
                                        playbackDuration:
                                            provider.playbackDuration,
                                        onSeek:
                                            (position) => provider
                                                .seekToPosition(position),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                ),
              ],
            );
          },
        ),
      ),

      floatingActionButton: const RecordingFAB(),
    );
  }

  Widget _buildEmptyState(BuildContext context, VoiceNotesProvider provider) {
    String message;
    String subtitle;
    IconData icon;

    if (provider.searchQuery.isNotEmpty || provider.selectedTag != null) {
      message = 'No matching notes found';
      subtitle = 'Try adjusting your search or filters';
      icon = Icons.search_off;
    } else {
      message = 'No voice notes yet';
      subtitle = 'Tap the microphone button to record your first note';
      icon = Icons.mic_none;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: const Color(0xFF6C5CE7)),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (provider.searchQuery.isNotEmpty ||
                provider.selectedTag != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  provider.clearFilters();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToEditNote(BuildContext context, VoiceNote note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditNoteScreen(voiceNote: note),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, VoiceNote note) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Delete Voice Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete "${note.title}"?'),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<VoiceNotesProvider>().deleteVoiceNote(note);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted "${note.title}"'),
                    backgroundColor: Colors.red[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Temporary debug method for testing permissions
  Future<void> _debugPermissions(BuildContext context) async {
    final audioService = AudioService();
    try {
      final debugInfo = await audioService.debugPermissionStatus();

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Permission Debug Info'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children:
                    debugInfo.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debug failed: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }
}
