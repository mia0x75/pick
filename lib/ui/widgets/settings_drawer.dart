import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingsDrawer extends StatefulWidget {
  final VoidCallback onClose;

  const SettingsDrawer({super.key, required this.onClose});

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  int _focusedIndex = -1;

  final List<_SettingsItem> _items = [
    _SettingsItem(
      icon: Icons.sync,
      title: '同步中心',
      subtitle: 'WebSocket: 运行中 · WebDAV: 已连接',
    ),
    _SettingsItem(
      icon: Icons.play_circle,
      title: '播放设置',
      subtitle: '硬解码 · 跳过片头 0s · 跳过片尾 0s',
    ),
    _SettingsItem(
      icon: Icons.palette,
      title: '界面定制',
      subtitle: '默公开 · 背景: 默认',
    ),
    _SettingsItem(
      icon: Icons.info_outline,
      title: '关于',
      subtitle: 'Pick 片刻 v0.1.0',
    ),
  ];

  KeyEventResult _onItemKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        // Open submodule (TODO)
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.goBack ||
          event.logicalKey == LogicalKeyboardKey.escape) {
        widget.onClose();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480.w,
      color: const Color(0xFF141414),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            top: 54.h,
            left: 48.w,
            right: 48.w,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '设置',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 48.h),
              Expanded(
                child: ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => SizedBox(height: 16.h),
                  itemBuilder: (context, index) {
                    return _buildSettingItem(index, _items[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(int index, _SettingsItem item) {
    return Focus(
      onFocusChange: (focused) {
        setState(() => _focusedIndex = focused ? index : -1);
      },
      onKeyEvent: (node, event) => _onItemKeyEvent(index, event),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 80.h,
        decoration: BoxDecoration(
          color: _focusedIndex == index
              ? const Color(0xFFBB86FC).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: _focusedIndex == index
              ? const Border(
                  left: BorderSide(color: Color(0xFFBB86FC), width: 4),
                )
              : null,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 28.sp,
              color: _focusedIndex == index
                  ? const Color(0xFFFF6B35)
                  : Colors.grey,
            ),
            SizedBox(width: 16.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                  ),
                ),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14.sp,
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

class _SettingsItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
