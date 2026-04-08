import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/models/storage_node.dart';

class ResourceCard extends StatefulWidget {
  final StorageNode node;
  final VoidCallback? onSelect;
  final VoidCallback? onMenu;
  final FocusNode? focusNode;
  final bool autofocus;

  const ResourceCard({
    super.key,
    required this.node,
    this.onSelect,
    this.onMenu,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<ResourceCard> createState() => _ResourceCardState();
}

class _ResourceCardState extends State<ResourceCard> {
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
    final protocolColor = _getProtocolColor();
    final focusShadows = [
      BoxShadow(
        color: protocolColor.withValues(alpha: 0.3),
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
            color: protocolColor.withValues(alpha: _hasFocus ? 0.2 : 0.1),
            border: Border.all(
              color: _hasFocus ? protocolColor : Colors.white10,
              width: _hasFocus ? 3.w : 1.w,
            ),
            boxShadow: _hasFocus ? focusShadows : normalShadows,
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  _getProtocolIcon(),
                  size: 64.sp,
                  color: _hasFocus ? protocolColor : Colors.white38,
                ),
              ),
              if (widget.node.isPrivate)
                Positioned(
                  top: 10.h,
                  left: 10.w,
                  child: Icon(
                    Icons.security_rounded,
                    size: 16.sp,
                    color: Colors.white24,
                  ),
                ),
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
                    widget.node.name,
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
            ],
          ),
        ),
      ),
    );
  }

  Color _getProtocolColor() {
    switch (widget.node.type) {
      case StorageType.webdav:
        return const Color(0xFF2196F3);
      case StorageType.smb:
        return const Color(0xFF4CAF50);
      case StorageType.ftp:
        return const Color(0xFFFF9800);
      case StorageType.nfs:
        return const Color(0xFF9C27B0);
      case StorageType.usb:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _getProtocolIcon() {
    switch (widget.node.type) {
      case StorageType.webdav:
        return Icons.cloud_queue_rounded;
      case StorageType.smb:
        return Icons.storage_rounded;
      case StorageType.ftp:
        return Icons.folder_shared_rounded;
      case StorageType.nfs:
        return Icons.lan_rounded;
      case StorageType.usb:
        return Icons.usb_rounded;
    }
  }
}
