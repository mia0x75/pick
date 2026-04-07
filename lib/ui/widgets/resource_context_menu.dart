import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/models/storage_node.dart';

class ResourceContextMenu extends StatefulWidget {
  final StorageNode node;
  final Function(bool isPrivate) onTogglePrivate;
  final Function() onMove;
  final Function() onEdit;
  final Function() onDelete;
  final VoidCallback onClose;

  const ResourceContextMenu({
    super.key,
    required this.node,
    required this.onTogglePrivate,
    required this.onMove,
    required this.onEdit,
    required this.onDelete,
    required this.onClose,
  });

  @override
  State<ResourceContextMenu> createState() => _ResourceContextMenuState();
}

class _ResourceContextMenuState extends State<ResourceContextMenu> {
  int _focusedIndex = 0;

  List<_ContextMenuItem> get _items {
    final items = [
      _ContextMenuItem(
        icon: widget.node.isPrivate ? Icons.visibility : Icons.visibility_off,
        label: widget.node.isPrivate ? '恢复为公开' : '设置为私密',
        onTap: () {
          widget.onTogglePrivate(!widget.node.isPrivate);
          widget.onClose();
        },
      ),
      _ContextMenuItem(
        icon: Icons.drive_file_move_outline,
        label: '移动',
        onTap: () {
          widget.onMove();
          widget.onClose();
        },
      ),
      _ContextMenuItem(
        icon: Icons.edit,
        label: '编辑',
        onTap: () {
          widget.onEdit();
          widget.onClose();
        },
      ),
      _ContextMenuItem(
        icon: Icons.delete_outline,
        label: '删除',
        onTap: () {
          widget.onDelete();
          widget.onClose();
        },
      ),
    ];
    return items;
  }

  KeyEventResult _onItemKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        _items[index].onTap();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() => _focusedIndex = (index - 1) % _items.length);
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
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
              ),
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
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 20.sp,
              color: isFocused ? Colors.black : Colors.white70,
            ),
            SizedBox(width: 12.w),
            Text(
              item.label,
              style: TextStyle(
                color: isFocused ? Colors.black : Colors.white70,
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

  const _ContextMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
