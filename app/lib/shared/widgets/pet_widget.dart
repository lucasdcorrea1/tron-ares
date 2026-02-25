import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

/// Widget that displays an animated pet video
class PetWidget extends StatefulWidget {
  final String assetPath;
  final double size;
  final BlendMode blendMode;
  final bool showSpeechBubble;
  final String? message;

  const PetWidget({
    super.key,
    this.assetPath = 'assets/videos/patov2.mp4',
    this.size = 120,
    this.blendMode = BlendMode.multiply,
    this.showSpeechBubble = false,
    this.message,
  });

  @override
  State<PetWidget> createState() => _PetWidgetState();
}

class _PetWidgetState extends State<PetWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.asset(widget.assetPath);

    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.setVolume(0);
      await _controller.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing pet video: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showSpeechBubble && widget.message != null)
          _SpeechBubble(message: widget.message!),
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.transparent,
            widget.blendMode,
          ),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Speech bubble for pet messages
class _SpeechBubble extends StatelessWidget {
  final String message;

  const _SpeechBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message,
        style: AppTypography.bodySmall(color: AppColors.textPrimary),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Card containing the pet with gamification info
class PetCard extends StatelessWidget {
  final String? petName;
  final String? message;
  final int? level;
  final double? experience;

  const PetCard({
    super.key,
    this.petName,
    this.message,
    this.level,
    this.experience,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Pet Video
          const PetWidget(
            size: 100,
            blendMode: BlendMode.multiply,
          ),
          const SizedBox(width: AppSpacing.md),

          // Pet Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      petName ?? 'Pato Imperial',
                      style: AppTypography.titleMedium(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (level != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.imperiumGold,
                          borderRadius: BorderRadius.circular(AppSpacing.xs),
                        ),
                        child: Text(
                          'Nv. $level',
                          style: AppTypography.labelSmall(
                            color: AppColors.backgroundDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message ?? 'Continue economizando!',
                  style: AppTypography.bodySmall(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (experience != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  // XP Progress bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'XP',
                            style: AppTypography.labelSmall(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${(experience! * 100).toInt()}%',
                            style: AppTypography.labelSmall(
                              color: AppColors.imperiumGold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.xxs),
                        child: LinearProgressIndicator(
                          value: experience!,
                          backgroundColor: AppColors.surfaceDark,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.imperiumGold,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
