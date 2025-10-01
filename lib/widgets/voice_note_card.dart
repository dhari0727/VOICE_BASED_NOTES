import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/voice_note.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import '../screens/attachment_viewer_screen.dart';

class VoiceNoteCard extends StatelessWidget {
  final VoiceNote voiceNote;
  final VoidCallback onPlay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isPlaying;
  final Duration playbackPosition;
  final Duration playbackDuration;
  final Function(Duration) onSeek;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePinned;
  final VoidCallback? onShareRealtime;
  final VoidCallback? onShareFallback;

  const VoiceNoteCard({
    super.key,
    required this.voiceNote,
    required this.onPlay,
    required this.onEdit,
    required this.onDelete,
    required this.isPlaying,
    required this.playbackPosition,
    required this.playbackDuration,
    required this.onSeek,
    this.onToggleFavorite,
    this.onTogglePinned,
    this.onShareRealtime,
    this.onShareFallback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            _buildAudioControls(context),
            if (voiceNote.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDescription(context),
            ],
            if (voiceNote.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildTags(context),
            ],
            if (voiceNote.attachments.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildAttachments(context),
            ],
            const SizedBox(height: 12),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 28,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: _priorityColor(voiceNote.priority),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Expanded(
          child: Text(
            voiceNote.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onTogglePinned != null)
          IconButton(
            tooltip: 'Pin',
            onPressed: onTogglePinned,
            icon: Icon(
              voiceNote.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              size: 18,
              color: voiceNote.isPinned ? Theme.of(context).primaryColor : Colors.grey[600],
            ),
          ),
        if (onToggleFavorite != null)
          IconButton(
            tooltip: 'Favorite',
            onPressed: onToggleFavorite,
            icon: Icon(
              voiceNote.isFavorite ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: voiceNote.isFavorite ? const Color(0xFFE17055) : Colors.grey[600],
            ),
          ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
              case 'export':
                // handled by parent via onEdit hook or separate action if needed
                break;
              case 'share_rt':
                if (onShareRealtime != null) onShareRealtime!();
                break;
              case 'share':
                if (onShareFallback != null) onShareFallback!();
                break;
            }
          },
          itemBuilder:
              (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, size: 16),
                      SizedBox(width: 8),
                      Text('Export'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'share_rt',
                  child: Row(
                    children: [
                      Icon(Icons.wifi_tethering, size: 16),
                      SizedBox(width: 8),
                      Text('Share (Realtime)'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share, size: 16),
                      SizedBox(width: 8),
                      Text('Share'),
                    ],
                  ),
                ),
              ],
          child: Icon(Icons.more_vert, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Color _priorityColor(int p) {
    switch (p) {
      case 2:
        return Colors.red;
      case 0:
        return Colors.green;
      case 1:
      default:
        return Colors.orange;
    }
  }

  Widget _buildAudioControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPlay,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(child: _buildProgressSlider(context)),
              const SizedBox(width: 8),
              _buildSpeedMenu(context),
              Text(
                isPlaying
                    ? '${_formatDuration(playbackPosition)} / ${_formatDuration(playbackDuration)}'
                    : '00:00 / ${_formatDuration(voiceNote.duration)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedMenu(BuildContext context) {
    return PopupMenuButton<double>(
      tooltip: 'Speed',
      onSelected: (value) {
        // The parent should handle speed changes via provider; this is UI-only placeholder
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 0.75, child: Text('0.75x')),
        PopupMenuItem(value: 1.0, child: Text('1.0x')),
        PopupMenuItem(value: 1.25, child: Text('1.25x')),
        PopupMenuItem(value: 1.5, child: Text('1.5x')),
        PopupMenuItem(value: 2.0, child: Text('2.0x')),
      ],
      child: Icon(Icons.speed, size: 18, color: Colors.grey[600]),
    );
  }

  Widget _buildProgressSlider(BuildContext context) {
    final totalDuration = isPlaying ? playbackDuration : voiceNote.duration;
    // When not playing, show zero position (reset to beginning)
    final currentPosition = isPlaying ? playbackPosition : Duration.zero;

    return Slider(
      value:
          totalDuration.inSeconds > 0
              ? (currentPosition.inSeconds / totalDuration.inSeconds).clamp(
                0.0,
                1.0,
              )
              : 0.0,
      onChanged:
          isPlaying
              ? (value) {
                final newPosition = Duration(
                  seconds: (value * totalDuration.inSeconds).round(),
                );
                onSeek(newPosition);
              }
              : null,
      activeColor: Theme.of(context).primaryColor,
      inactiveColor: Colors.grey[300],
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      voiceNote.description,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTags(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children:
          voiceNote.tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tag,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final createdAt = DateFormat(
      'MMM d, y • h:mm a',
    ).format(voiceNote.createdAt);
    final updatedAt = DateFormat(
      'MMM d, y • h:mm a',
    ).format(voiceNote.updatedAt);
    final isUpdated = voiceNote.createdAt != voiceNote.updatedAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((voiceNote.transcript ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              (voiceNote.transcript!).length > 160
                  ? voiceNote.transcript!.substring(0, 160) + '…'
                  : voiceNote.transcript!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
          ),
        Row(
      children: [
        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            isUpdated ? 'Updated $updatedAt' : 'Created $createdAt',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
          ),
        ),
        Text(
          _formatDuration(voiceNote.duration),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
      ],
    );
  }

  Widget _buildAttachments(BuildContext context) {
    List<Widget> tiles = [];
    for (final path in voiceNote.attachments.take(6)) {
      final lower = path.toLowerCase();
      final isImage = lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.webp');
      final isVideo = lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.mkv') || lower.endsWith('.webm');
      final isAudio = lower.endsWith('.mp3') || lower.endsWith('.aac') || lower.endsWith('.wav') || lower.endsWith('.m4a');

      Widget content;
      if (isImage && File(path).existsSync()) {
        content = ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
          ),
        );
      } else {
        IconData icon = Icons.insert_drive_file;
        if (isVideo) icon = Icons.videocam;
        if (isAudio) icon = Icons.audiotrack;
        content = Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(icon, color: Colors.grey[700]),
          ),
        );
      }

      tiles.add(GestureDetector(
        onTap: () {
          if (isImage) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AttachmentViewerScreen(imagePaths: voiceNote.attachments.where((p){final l=p.toLowerCase();return l.endsWith('.png')||l.endsWith('.jpg')||l.endsWith('.jpeg')||l.endsWith('.webp');}).toList(), initialPath: path),
              ),
            );
          } else {
            OpenFilex.open(path);
          }
        },
        child: AspectRatio(
          aspectRatio: 1,
          child: content,
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: tiles,
        ),
      ],
    );
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
