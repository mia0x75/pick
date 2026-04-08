import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RecentlyPlayedCard extends StatefulWidget {
  final String title;
  final String? posterUrl;
  final String? previewUrl;
  final double progress;
  final bool isHistoryButton;
  final VoidCallback? onSelect;
  final VoidCallback? onMenu;
  final FocusNode? focusNode;
  final bool autofocus;

  const RecentlyPlayedCard({
    super.key,
    required this.title,
    this.posterUrl,
    this.previewUrl,
    this.progress = 0.0,
    this.isHistoryButton = false,
    this.onSelect,
    this.onMenu,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<RecentlyPlayedCard> createState() => _RecentlyPlayedCardState();
}

class _RecentlyPlayedCardState extends State<RecentlyPlayedCard> {
  bool _hasFocus = false;
  Timer? _previewTimer;
  bool _showVideoPreview = false;

  final double _collapsedWidth = 180.w;
  final double _expandedWidth = 711.w;
  final double _cardHeight = 400.h;

  @override
  void dispose() {
    _previewTimer?.cancel();
    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        widget.onSelect?.call();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.contextMenu ||
          event.logicalKey == LogicalKeyboardKey.keyM) {
        widget.onMenu?.call();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _onFocusChange(bool hasFocus) {
    setState(() {
      _hasFocus = hasFocus;
      _showVideoPreview = false;
    });

    _previewTimer?.cancel();
    if (hasFocus && !widget.isHistoryButton) {
      _previewTimer = Timer(const Duration(seconds: 1), () {
        if (mounted && _hasFocus) {
          setState(() {
            _showVideoPreview = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: _onFocusChange,
      onKeyEvent: _onKeyEvent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: _hasFocus ? _expandedWidth : _collapsedWidth,
        height: _cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: const Color(0xFF1E1E1E),
          border: Border.all(
            color: _hasFocus ? const Color(0xFFBB86FC) : Colors.white10,
            width: _hasFocus ? 3.w : 1.w,
          ),
          boxShadow: _hasFocus
              ? [
                  BoxShadow(
                    color: const Color(0xFFBB86FC).withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBackground(),

            if (_showVideoPreview && _hasFocus)
              Container(
                color: Colors.black,
                child: const Center(
                  child: Icon(Icons.volume_off, color: Colors.white54, size: 48),
                ),
              ),

            // 底部半透明渐变遮罩 + 标题（始终显示）
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                  stops: const [0.5, 0.7, 1.0],
                ),
              ),
            ),

            // 底部标题栏（始终显示）
            Positioned(
              left: 16.w,
              right: 16.w,
              bottom: 16.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // 播放历史按钮提示
            if (_hasFocus && widget.isHistoryButton)
              Positioned(
                bottom: 32.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '查看完整播放历史',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (widget.isHistoryButton) {
      return Center(
        child: Icon(
          Icons.history,
          color: _hasFocus ? Colors.white : Colors.grey,
          size: _hasFocus ? 80.sp : 64.sp,
        ),
      );
    }

    if (widget.posterUrl != null && widget.posterUrl!.isNotEmpty) {
      return Container(
        color: const Color(0xFF2C2C2C),
        child: const Center(
          child: Text('Poster Image', style: TextStyle(color: Colors.white38)),
        ),
      );
    }

    return Container(color: const Color(0xFF2C2C2C));
  }
}
