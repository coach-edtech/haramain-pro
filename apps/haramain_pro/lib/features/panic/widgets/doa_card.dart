import 'package:flutter/material.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../design/tokens/app_typography.dart';
import '../../../design/tokens/app_spacing.dart';

/// Doa Card widget as per FRONTEND-SPEC.md Section 4.2
/// Content: Arabic text (Amiri Quran font), latin, terjemahan
/// Header: Location badge (e.g., "📍 Ka'bah")
/// Audio button: earphone icon (earphone-only playback)
/// Bookmark toggle
class DoaCard extends StatefulWidget {
  final String zoneId;
  final String zoneName;
  final String arabicText;
  final String latinText;
  final String indonesianText;
  final String? locationBadge;
  final String? audioUrl;
  final bool isBookmarked;
  final VoidCallback? onBookmarkToggle;
  final VoidCallback? onAudioPlay;

  const DoaCard({
    super.key,
    required this.zoneId,
    required this.zoneName,
    required this.arabicText,
    required this.latinText,
    required this.indonesianText,
    this.locationBadge,
    this.audioUrl,
    this.isBookmarked = false,
    this.onBookmarkToggle,
    this.onAudioPlay,
  });

  @override
  State<DoaCard> createState() => _DoaCardState();
}

class _DoaCardState extends State<DoaCard> {
  bool _isPlaying = false;
  bool _isExpanded = false;

  void _toggleAudio() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    widget.onAudioPlay?.call();
    // Auto-stop after 30 seconds
    if (_isPlaying) {
      Future.delayed(const Duration(seconds: 30), () {
        if (mounted && _isPlaying) {
          setState(() {
            _isPlaying = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: widget.isBookmarked
              ? Border.all(color: AppColors.amber500, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Location badge
                  if (widget.locationBadge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emerald100,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.emerald700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.locationBadge!,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.emerald700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  
                  // Zone name
                  Expanded(
                    child: Text(
                      widget.zoneName,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.slate900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Audio button (if available)
                  if (widget.audioUrl != null)
                    GestureDetector(
                      onTap: _toggleAudio,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _isPlaying
                              ? AppColors.amber500
                              : AppColors.slate200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlaying ? Icons.headphones : Icons.headset,
                          size: 18,
                          color: _isPlaying
                              ? Colors.white
                              : AppColors.slate600,
                        ),
                      ),
                    ),

                  const SizedBox(width: AppSpacing.sm),

                  // Bookmark button
                  GestureDetector(
                    onTap: widget.onBookmarkToggle,
                    child: Icon(
                      widget.isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      size: 24,
                      color: widget.isBookmarked
                          ? AppColors.amber500
                          : AppColors.slate600,
                    ),
                  ),
                ],
              ),
            ),

            // Arabic text
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: const BoxDecoration(
                color: AppColors.cream,
                border: Border(
                  top: BorderSide(color: AppColors.dividerLight, width: 1),
                ),
              ),
              child: Text(
                widget.arabicText,
                style: AppTypography.arabicLarge.copyWith(
                  color: AppColors.slate900,
                  height: 1.8,
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            ),

            // Expandable content
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Latin transliteration
                    Text(
                      widget.latinText,
                      style: AppTypography.latinMedium.copyWith(
                        color: AppColors.slate600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Indonesian translation
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        widget.indonesianText,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.slate700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),

            // Expand indicator
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Center(
                child: Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.slate400,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Doa card for compact display (horizontal scroll)
class DoaCardCompact extends StatelessWidget {
  final String zoneName;
  final String locationBadge;
  final VoidCallback? onTap;

  const DoaCardCompact({
    super.key,
    required this.zoneName,
    required this.locationBadge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Location icon
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.emerald100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mosque,
                size: 18,
                color: AppColors.emerald700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Zone name
            Text(
              zoneName,
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.slate900,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            // Location badge
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 12,
                  color: AppColors.slate600,
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    locationBadge,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.slate600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
