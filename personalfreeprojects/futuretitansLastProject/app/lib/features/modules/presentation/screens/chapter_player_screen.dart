import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/module_provider.dart';
import '../../data/models/module_model.dart';
import '../../../ai_chat/data/repositories/chat_repository.dart';
class ChapterPlayerScreen extends ConsumerStatefulWidget {
  final String moduleId;
  final String chapterId;

  const ChapterPlayerScreen({
    super.key,
    required this.moduleId,
    required this.chapterId,
  });

  @override
  ConsumerState<ChapterPlayerScreen> createState() => _ChapterPlayerScreenState();
}

class _ChapterPlayerScreenState extends ConsumerState<ChapterPlayerScreen> {
  YoutubePlayerController? _youtubeController;
  final ap.AudioPlayer _audioPlayer = ap.AudioPlayer();
  bool _isPlayingAudio = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  bool _wasPlaying = false;

  @override
  void dispose() {
    _youtubeController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initAudio(String url) async {
    await _audioPlayer.setSourceUrl(url);
    _audioPlayer.onDurationChanged.listen((d) => setState(() => _audioDuration = d));
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _audioPosition = p));
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() => _isPlayingAudio = state == ap.PlayerState.playing);
    });
  }

  void _initVideo(String url) {
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId != null) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
        ),
      )..addListener(_onYoutubeStateChange);
    }
  }

  void _onYoutubeStateChange() {
    if (_youtubeController == null) return;

    final isPlaying = _youtubeController!.value.isPlaying;
    final isEnded = _youtubeController!.value.playerState == PlayerState.ended;
    final isFullScreen = _youtubeController!.value.isFullScreen;

    // Transition from paused to playing -> Go fullscreen
    if (isPlaying && !_wasPlaying && !isFullScreen) {
      _youtubeController!.toggleFullScreenMode();
    }

    // When video ends and is still fullscreen -> Exit fullscreen
    if (isEnded && isFullScreen) {
      _youtubeController!.toggleFullScreenMode();
    }

    _wasPlaying = isPlaying;
  }

  @override
  Widget build(BuildContext context) {
    final chapterAsync = ref.watch(chapterProvider('${widget.moduleId}|${widget.chapterId}'));

    return chapterAsync.when(
      data: (chapter) {
        if (chapter.type == 'video' && chapter.videoUrl != null && _youtubeController == null) {
          _initVideo(chapter.videoUrl!);
        } else if (chapter.type == 'audio' && chapter.audioUrl != null && _audioDuration == Duration.zero) {
          _initAudio(chapter.audioUrl!);
        }

        if (chapter.type == 'video' && _youtubeController != null) {
          return YoutubePlayerBuilder(
            player: YoutubePlayer(
              controller: _youtubeController!,
              showVideoProgressIndicator: true,
              progressColors: const ProgressBarColors(
                playedColor: AppTheme.primaryGold,
                handleColor: AppTheme.primaryGoldDark,
              ),
            ),
            builder: (context, player) {
              return _buildScaffold(context, chapter, mediaWidget: player);
            },
          );
        } else {
          return _buildScaffold(context, chapter, mediaWidget: _buildMediaContent(chapter));
        }
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildScaffold(BuildContext context, ChapterModel chapter, {Widget? mediaWidget}) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chapter'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getIconForType(chapter.type), size: 14, color: AppTheme.primaryGoldDark),
                        const SizedBox(width: 4),
                        Text(
                          chapter.type.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primaryGoldDark,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    chapter.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  if (mediaWidget != null) mediaWidget,
                  
                  const SizedBox(height: 32),
                  
                  if (chapter.content.isNotEmpty)
                    Text(
                      chapter.content,
                      style: const TextStyle(height: 1.6, fontSize: 16),
                    ),
                    
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Back to Module'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await ref.read(chatRepositoryProvider).completeChapter(widget.moduleId, widget.chapterId);
                        ref.invalidate(modulesProvider);
                        
                        if (chapter.aiInteractionEnabled) {
                          if (context.mounted) {
                            context.push('/modules/${widget.moduleId}/chapter/${widget.chapterId}/chat');
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chapter Completed!')));
                            context.pop();
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to complete: $e')));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Continue'),
                        if (chapter.aiInteractionEnabled) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.auto_awesome, size: 16),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMediaContent(ChapterModel chapter) {
    if (chapter.type == 'audio' && chapter.audioUrl != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                _isPlayingAudio ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: AppTheme.primaryGold,
                size: 48,
              ),
              onPressed: () {
                if (_isPlayingAudio) {
                  _audioPlayer.pause();
                } else {
                  _audioPlayer.resume();
                }
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primaryGold,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: AppTheme.primaryGoldDark,
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _audioPosition.inSeconds.toDouble(),
                      max: _audioDuration.inSeconds.toDouble() > 0 ? _audioDuration.inSeconds.toDouble() : 1.0,
                      onChanged: (val) {
                         _audioPlayer.seek(Duration(seconds: val.toInt()));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(_audioPosition), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(_formatDuration(_audioDuration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      );
    } else if (chapter.type == 'pdf' && chapter.pdfUrl != null) {
      return Container(
         padding: const EdgeInsets.all(24),
         decoration: BoxDecoration(
           color: Colors.grey.shade100,
           borderRadius: BorderRadius.circular(16),
           border: Border.all(color: Colors.grey.shade300),
         ),
         child: Column(
           children: [
             const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
             const SizedBox(height: 16),
             const Text('This chapter contains a PDF document.'),
             const SizedBox(height: 16),
             ElevatedButton.icon(
               onPressed: () async {
                 final url = Uri.parse(chapter.pdfUrl!);
                 if (await canLaunchUrl(url)) {
                   await launchUrl(url);
                 }
               },
               icon: const Icon(Icons.download),
               label: const Text('Open PDF'),
             )
           ],
         ),
      );
    }
    return const SizedBox.shrink();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  IconData _getIconForType(String type) {
    switch(type.toLowerCase()) {
      case 'video': return Icons.play_circle_outline;
      case 'audio': return Icons.headphones_outlined;
      case 'pdf': return Icons.picture_as_pdf_outlined;
      default: return Icons.article_outlined;
    }
  }
}
