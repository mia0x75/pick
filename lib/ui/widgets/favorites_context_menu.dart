import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FavoritesContextMenu extends StatefulWidget {
  final VoidCallback onRename;
  final VoidCallback onReorder;
  final VoidCallback onChangeCover;
  final VoidCallback onUnpin;
  final VoidCallback onClose;

  const FavoritesContextMenu({
    super.key,
    required this.onRename,
    required this.onReorder,
    required this.onChangeCover,
    required this.onUnpin,
    required this.onClose,
  });

  @override
  State<FavoritesContextMenu> createState() => _FavoritesContextMenuState();
}

class _FavoritesContextMenuState extends State<FavoritesContextMenu> {
  int _focusedIndex = 0;

  final List<_ContextMenuItem> _items = const [
    _ContextMenuItem(icon: Icons.edit, label: '重命名别名'),
    _ContextMenuItem(icon: Icons.swap_horiz, label: '调整排序'),
    _ContextMenuItem(icon: Icons.image, label: '更换封面'),
    _ContextMenuItem(icon: Icons.bookmark_remove, label: '取消收藏', isDanger: true),
  ];

  KeyEventResult _onItemKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        switch (index) {
          case 0: widget.onRename(); break;
          case 1: widget.onReorder(); break;
          case 2: widget.onChangeCover(); break;
          case 3: widget.onUnpin(); break;
        }
        widget.onClose();
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
  final bool isDanger;

  const _ContextMenuItem({
    required this.icon,
    required this.label,
    this.isDanger = false,
  });
}
