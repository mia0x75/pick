import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../shared/constants.dart';

class RecentlyPlayedCard extends StatefulWidget {
  final String title;
  final String? posterUrl;
  final String? previewUrl;
  final double? progress;
  final VoidCallback? onSelect;
  final bool isHistoryButton;

  const RecentlyPlayedCard({
    super.key,
    required this.title,
    this.posterUrl,
    this.previewUrl,
    this.progress,
    this.onSelect,
    this.isHistoryButton = false,
  });

  @override
  State<RecentlyPlayedCard> createState() => _RecentlyPlayedCardState();
}

class _RecentlyPlayedCardState extends State<RecentlyPlayedCard>
    with SingleTickerProviderStateMixin {
  bool _isFocused = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.row1AnimationDuration,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange(bool focused) {
    if (_isFocused != focused) {
      setState(() {
        _isFocused = focused;
      });
      if (focused) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: _onFocusChange,
      child: RepaintBoundary(
        child: AnimatedContainer(
          duration: AppConstants.row1AnimationDuration,
          curve: Curves.easeOutCubic,
          width: _isFocused
              ? AppConstants.row1ExpandedWidth.w
              : AppConstants.row1CollapsedWidth.w,
          height: AppConstants.row1Height.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            border: Border.all(
              color: _isFocused ? const Color(0xFFFF6B35) : Colors.transparent,
              width: 2,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.posterUrl != null && widget.posterUrl!.isNotEmpty)
                  Image.network(
                    widget.posterUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                else
                  _buildPlaceholder(),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                if (widget.progress != null && !widget.isHistoryButton)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: widget.progress!,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                      minHeight: 3,
                    ),
                  ),
                if (_isFocused)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: widget.isHistoryButton
            ? const Icon(Icons.history, color: Colors.grey, size: 48)
            : const Icon(Icons.movie, color: Colors.grey, size: 48),
      ),
    );
  }
}
