import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RecentlyPlayedContextMenu extends StatefulWidget {
  final bool isHistoryButton;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onLocate;
  final VoidCallback onRemove;
  final VoidCallback onClearAll;
  final VoidCallback onClose;

  const RecentlyPlayedContextMenu({
    super.key,
    required this.isHistoryButton,
    required this.onResume,
    required this.onRestart,
    required this.onLocate,
    required this.onRemove,
    required this.onClearAll,
    required this.onClose,
  });

  @override
  State<RecentlyPlayedContextMenu> createState() => _RecentlyPlayedContextMenuState();
}

class _RecentlyPlayedContextMenuState extends State<RecentlyPlayedContextMenu> {
  int _focusedIndex = 0;

  List<_ContextMenuItem> get _items {
    if (widget.isHistoryButton) {
      return [
        _ContextMenuItem(
          icon: Icons.delete_sweep,
          label: '清空全部历史',
          onTap: widget.onClearAll,
          isDanger: true,
        ),
      ];
    }
    return [
      _ContextMenuItem(icon: Icons.play_arrow, label: '继续播放', onTap: widget.onResume),
      _ContextMenuItem(icon: Icons.replay, label: '重新开始', onTap: widget.onRestart),
      _ContextMenuItem(icon: Icons.folder_open, label: '定位资源', onTap: widget.onLocate),
      _ContextMenuItem(icon: Icons.delete_outline, label: '移除记录', onTap: widget.onRemove),
    ];
  }

  KeyEventResult _onItemKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        _items[index].onTap();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() => _focusedIndex = (index - 1 + _items.length) % _items.length);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() => _focusedIndex = (index + 1) % _items.length);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.goBack) {
        widget.onClose();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) => _onItemKeyEvent(_focusedIndex, event),
      child: Center(
        child: Container(
          width: 240.w,
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.all(Radius.circular(12)),
            boxShadow: [
              BoxShadow(color: Colors.black54, blurRadius: 20),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              _items.length,
              (index) => _buildMenuItem(index, _items[index]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(int index, _ContextMenuItem item) {
    final isFocused = _focusedIndex == index;
    final textColor = item.isDanger ? const Color(0xFFFF6B35) : null;
    return Focus(
      onFocusChange: (focused) {
        if (focused) setState(() => _focusedIndex = index);
      },
      onKeyEvent: (node, event) => _onItemKeyEvent(index, event),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isFocused ? const Color(0xFFBB86FC) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 20.sp,
              color: isFocused ? Colors.black : (textColor ?? Colors.white70),
            ),
            SizedBox(width: 12.w),
            Text(
              item.label,
              style: TextStyle(
                color: isFocused ? Colors.black : (textColor ?? Colors.white70),
                fontSize: 16.sp,
                fontWeight: isFocused ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContextMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  const _ContextMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });
}
