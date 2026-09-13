import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../config/theme.dart';
import '../../models/sign.dart';

/// An interactive, looping video player for ASL reference sign demonstrations.
class SignVideoPlayer extends StatefulWidget {
  final String videoAsset;
  final double? width;
  final double? height;
  final bool autoPlay;
  final bool showControls;
  final String? fallbackImageAsset;

  const SignVideoPlayer({
    super.key,
    required this.videoAsset,
    this.width,
    this.height,
    this.autoPlay = true,
    this.showControls = true,
    this.fallbackImageAsset,
  });

  @override
  State<SignVideoPlayer> createState() => _SignVideoPlayerState();
}

class _SignVideoPlayerState extends State<SignVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;
  double _playbackSpeed = 1.0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(SignVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoAsset != widget.videoAsset) {
      _controller?.dispose();
      _controller = null;
      _initialized = false;
      _hasError = false;
      _initPlayer();
    }
  }

  Future<void> _initPlayer() async {
    try {
      final controller = VideoPlayerController.asset(widget.videoAsset);
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setPlaybackSpeed(_playbackSpeed);
      if (widget.autoPlay && mounted) {
        await controller.play();
      }
      if (mounted) {
        setState(() {
          _initialized = true;
          _isPlaying = controller.value.isPlaying;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null || !_initialized) return;
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
        _isPlaying = false;
      } else {
        controller.play();
        _isPlaying = true;
      }
    });
  }

  void _cycleSpeed() {
    final speeds = [1.0, 0.75, 0.5];
    final nextIndex = (speeds.indexOf(_playbackSpeed) + 1) % speeds.length;
    final nextSpeed = speeds[nextIndex];
    _controller?.setPlaybackSpeed(nextSpeed);
    setState(() => _playbackSpeed = nextSpeed);
  }

  void _replay() {
    final controller = _controller;
    if (controller == null || !_initialized) return;
    controller.seekTo(Duration.zero);
    controller.play();
    setState(() => _isPlaying = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      if (widget.fallbackImageAsset != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(LingoRadius.lg),
          child: Image.asset(
            widget.fallbackImageAsset!,
            width: widget.width,
            height: widget.height,
            fit: BoxFit.cover,
          ),
        );
      }
      return Container(
        width: widget.width ?? 260,
        height: widget.height ?? 220,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(LingoRadius.lg),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off, color: Colors.grey, size: 40),
              SizedBox(height: 8),
              Text('Video unavailable', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (!_initialized) {
      return Container(
        width: widget.width ?? 260,
        height: widget.height ?? 220,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(LingoRadius.lg),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: LingoColors.primary),
        ),
      );
    }

    final controller = _controller!;
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(LingoRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LingoRadius.lg),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: controller.value.aspectRatio > 0
                  ? controller.value.aspectRatio
                  : 1.0,
              child: VideoPlayer(controller),
            ),
            // Tap area to toggle play/pause
            Positioned.fill(
              child: GestureDetector(
                onTap: _togglePlayPause,
                behavior: HitTestBehavior.opaque,
                child: AnimatedOpacity(
                  opacity: _isPlaying ? 0.0 : 0.85,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    color: Colors.black38,
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Top overlay bar: badge & speed button
            if (widget.showControls)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.slow_motion_video,
                              color: LingoColors.secondary, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'ASL Video',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Speed toggle button (1x, 0.75x, 0.5x)
                    InkWell(
                      onTap: _cycleSpeed,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _playbackSpeed < 1.0
                                ? LingoColors.accent
                                : Colors.white30,
                          ),
                        ),
                        child: Text(
                          '${_playbackSpeed}x',
                          style: TextStyle(
                            color: _playbackSpeed < 1.0
                                ? LingoColors.accent
                                : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Replay button
                    InkWell(
                      onTap: _replay,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.replay,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Helper modal to view a sign's reference video from anywhere (such as camera practice).
void showSignVideoModal(BuildContext context, Sign sign) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      final videoAsset = sign.resolvedReferenceVideoAsset;
      final imageAsset = sign.resolvedReferenceImageAsset;
      return Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(sign.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sign: "${sign.text}"',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          sign.meaning,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (videoAsset != null)
                SignVideoPlayer(
                  videoAsset: videoAsset,
                  height: 240,
                  fallbackImageAsset: imageAsset,
                )
              else if (imageAsset != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    imageAsset,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No media preview available.'),
                ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LingoColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.tips_and_updates_outlined,
                        color: LingoColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sign.howToPerform,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}
