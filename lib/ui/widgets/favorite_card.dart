import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FavoriteCard extends StatefulWidget {
  final String name;
  final String? posterUrl;
  final IconData icon;
  final VoidCallback? onSelect;
  final VoidCallback? onMenu;
  final FocusNode? focusNode;
  final bool autofocus;

  const FavoriteCard({
    super.key,
    required this.name,
    this.posterUrl,
    this.icon = Icons.folder,
    this.onSelect,
    this.onMenu,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<FavoriteCard> createState() => _FavoriteCardState();
}

class _FavoriteCardState extends State<FavoriteCard> {
  bool _hasFocus = false;

  final double _cardSize = 160.w;

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

  @override
  Widget build(BuildContext context) {
    final focusShadows = [
      BoxShadow(
        color: const Color(0xFFBB86FC).withValues(alpha: 0.3),
        blurRadius: 15,
        spreadRadius: 2,
      ),
    ];
    final normalShadows = <BoxShadow>[];

    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (focus) => setState(() => _hasFocus = focus),
      onKeyEvent: _onKeyEvent,
      child: AnimatedScale(
        scale: _hasFocus ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: _cardSize,
          height: _cardSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            color: const Color(0xFF1E1E1E),
            border: Border.all(
              color: _hasFocus ? const Color(0xFFBB86FC) : Colors.white10,
              width: _hasFocus ? 3.w : 1.w,
            ),
            boxShadow: _hasFocus ? focusShadows : normalShadows,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildBackground(),
              // 底部半透明渐变遮罩
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: _cardSize * 0.3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ),
              // 底部标题栏
              Positioned(
                left: 8.w,
                right: 8.w,
                bottom: 8.h,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    widget.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (_hasFocus)
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: Icon(
                    Icons.star,
                    color: const Color(0xFFBB86FC),
                    size: 16.sp,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (widget.posterUrl != null && widget.posterUrl!.isNotEmpty) {
      return Opacity(
        opacity: _hasFocus ? 1.0 : 0.7,
        child: Image.network(
          widget.posterUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildIconFallback(),
        ),
      );
    }
    return _buildIconFallback();
  }

  Widget _buildIconFallback() {
    return Center(
      child: Icon(
        widget.icon,
        color: _hasFocus ? Colors.white54 : Colors.white24,
        size: 48.sp,
      ),
    );
  }
}
