import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/models/storage_node.dart';

class ResourceCard extends StatefulWidget {
  final StorageNode node;
  final VoidCallback? onSelect;
  final VoidCallback? onMenu;

  const ResourceCard({
    super.key,
    required this.node,
    this.onSelect,
    this.onMenu,
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
    return Focus(
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
            color: _getProtocolColor().withValues(alpha: _hasFocus ? 0.2 : 0.1),
            border: Border.all(
              color: _hasFocus ? _getProtocolColor() : Colors.white10,
              width: _hasFocus ? 3.w : 1.w,
            ),
            boxShadow: _hasFocus
                ? [
                    BoxShadow(
                      color: _getProtocolColor().withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  _getProtocolIcon(),
                  size: 64.sp,
                  color: _hasFocus ? _getProtocolColor() : Colors.white38,
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
              Positioned(
                bottom: 12.h,
                left: 8.w,
                right: 8.w,
                child: Text(
                  widget.node.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _hasFocus ? Colors.white : Colors.white54,
                    fontSize: 14.sp,
                    fontWeight: _hasFocus ? FontWeight.bold : FontWeight.normal,
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
