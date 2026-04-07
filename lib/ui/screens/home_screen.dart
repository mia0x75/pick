import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/providers/stealth_provider.dart';
import '../../core/providers/node_provider.dart';
import '../../shared/constants.dart';
import '../widgets/focusable_card.dart';
import '../widgets/recently_played_card.dart';
import '../widgets/favorite_card.dart';
import '../widgets/resource_card.dart';
import '../widgets/stealth_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _row1Controller = ScrollController();
  final ScrollController _row2Controller = ScrollController();
  final ScrollController _row3Controller = ScrollController();
  final List<LogicalKeyboardKey> _keyBuffer = [];
  DateTime? _lastKeyPressTime;

  final List<Map<String, dynamic>> _recentItems = [];

  @override
  void dispose() {
    _row1Controller.dispose();
    _row2Controller.dispose();
    _row3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stealthMode = ref.watch(stealthProvider);
    final nodes = ref.watch(nodeProvider);
    final favorites = ref.watch(favoriteProvider);
    final isUnlocked = stealthMode == StealthMode.unlocked;
    final isGlowing = stealthMode == StealthMode.glowing;

    final visibleNodes = nodes.where((n) => isUnlocked || !n.isPrivate).toList();

    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          _handleKeyPress(event.logicalKey);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        endDrawer: _buildSettingsDrawer(),
        body: Stack(
          children: [
            // Background image
            Image.asset(
              'assets/images/splash_background.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            Container(color: Colors.black.withValues(alpha: 0.6)),
            // Main content
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: AppConstants.tvEdgePadding.w,
                  right: AppConstants.tvEdgePadding.w,
                  top: AppConstants.tvTopPadding.h,
                  bottom: 48.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Recently Played (Accordion)
                    RepaintBoundary(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '最近播放',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppConstants.rowSpacing.h),
                          SizedBox(
                            height: AppConstants.row1Height.h,
                            child: _recentItems.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.play_circle_outline, size: 48.sp, color: Colors.grey),
                                        SizedBox(height: 8.h),
                                        Text('暂无播放记录', style: TextStyle(color: Colors.grey, fontSize: 16.sp)),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    controller: _row1Controller,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _recentItems.length + 1,
                                    itemBuilder: (_, index) {
                                      if (index == _recentItems.length) {
                                        return Padding(
                                          padding: EdgeInsets.only(right: 16.w),
                                          child: RecentlyPlayedCard(
                                            title: '播放历史',
                                            isHistoryButton: true,
                                          ),
                                        );
                                      }
                                      final item = _recentItems[index];
                                      return Padding(
                                        padding: EdgeInsets.only(right: 16.w),
                                        child: RecentlyPlayedCard(
                                          title: item['title'],
                                          posterUrl: item['poster'],
                                          previewUrl: item['preview'],
                                          progress: item['progress'],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppConstants.rowSpacing.h),

                    // Row 2: Favorites
                    RepaintBoundary(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '快捷路径',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppConstants.rowSpacing.h),
                          SizedBox(
                            height: AppConstants.row23CardHeight.h,
                            child: favorites.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.bookmark_border, size: 48.sp, color: Colors.grey),
                                        SizedBox(height: 8.h),
                                        Text('暂无收藏', style: TextStyle(color: Colors.grey, fontSize: 16.sp)),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    controller: _row2Controller,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: favorites.length,
                                    itemBuilder: (_, index) {
                                      final fav = favorites[index];
                                      return Padding(
                                        padding: EdgeInsets.only(right: 16.w),
                                        child: SizedBox(
                                          width: AppConstants.row23CardWidth.w,
                                          child: FavoriteCard(
                                            name: fav.name,
                                            posterUrl: fav.posterUrl,
                                            icon: Icons.movie,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppConstants.rowSpacing.h),

                    // Row 3: Resources
                    RepaintBoundary(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '资源中心',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!isUnlocked)
                                Padding(
                                  padding: EdgeInsets.only(left: 8.w),
                                  child: Icon(
                                    Icons.lock_outline,
                                    color: Colors.grey,
                                    size: 18.sp,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: AppConstants.rowSpacing.h),
                          SizedBox(
                            height: AppConstants.row23CardHeight.h,
                            child: ListView.builder(
                              controller: _row3Controller,
                              scrollDirection: Axis.horizontal,
                              itemCount: visibleNodes.length + 1,
                              itemBuilder: (_, index) {
                                if (index == visibleNodes.length) {
                                  return Padding(
                                    padding: EdgeInsets.only(right: 16.w),
                                    child: FocusableCard(
                                      onSelect: () => _showAddResourceDialog(context),
                                      onMenu: isUnlocked
                                          ? () => _showChangeCodeDialog(context)
                                          : null,
                                      child: SizedBox(
                                        width: AppConstants.row23CardWidth.w,
                                        child: Center(
                                          child: Icon(
                                            Icons.add,
                                            color: const Color(0xFFFF6B35),
                                            size: 48.sp,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                final node = visibleNodes[index];
                                return Padding(
                                  padding: EdgeInsets.only(right: 16.w),
                                  child: SizedBox(
                                    width: AppConstants.row23CardWidth.w,
                                    child: ResourceCard(node: node),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Top-right settings icon
            Positioned(
              top: AppConstants.tvTopPadding.h,
              right: AppConstants.tvEdgePadding.w,
              child: FocusableCard(
                width: 48.w,
                height: 48.h,
                onSelect: () {
                  if (isGlowing) {
                    _showStealthInputDialog(context);
                  } else {
                    Scaffold.of(context).openEndDrawer();
                  }
                },
                onLongSelect: () {
                  ref.read(stealthProvider.notifier).startUnlockSequence();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isGlowing
                        ? const Color(0xFF9C27B0).withValues(alpha: 0.6)
                        : Colors.transparent,
                    boxShadow: isGlowing
                        ? [
                            BoxShadow(
                              color: const Color(0xFF9C27B0).withValues(alpha: 0.8),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.settings,
                      color: isGlowing ? Colors.white : Colors.grey,
                      size: 24.sp,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleKeyPress(LogicalKeyboardKey key) {
    if (ref.read(stealthProvider) != StealthMode.glowing) return;

    final now = DateTime.now();
    if (_lastKeyPressTime != null &&
        now.difference(_lastKeyPressTime!) > AppConstants.secretCodeTimeout) {
      _keyBuffer.clear();
    }
    _lastKeyPressTime = now;

    _keyBuffer.add(key);
    if (_keyBuffer.length > AppConstants.secretCodeLength) {
      _keyBuffer.removeAt(0);
    }

    if (_keyBuffer.length == AppConstants.secretCodeLength) {
      final code = _keyBuffer
          .map((k) => AppConstants.defaultSecretCode.indexOf(k))
          .toList();
      ref.read(stealthProvider.notifier).verifyCode(code);
      _keyBuffer.clear();
    }
  }

  void _showStealthInputDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const StealthDialog(),
    );
  }

  void _showAddResourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('添加资源', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 600.w,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: '别名',
                        labelStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 16.h),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: '协议类型',
                        labelStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(),
                      ),
                      dropdownColor: const Color(0xFF1A1A1A),
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'webdav', child: Text('WebDAV')),
                        DropdownMenuItem(value: 'smb', child: Text('SMB')),
                        DropdownMenuItem(value: 'ftp', child: Text('FTP')),
                      ],
                      onChanged: (_) {},
                    ),
                    SizedBox(height: 16.h),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: '地址',
                        labelStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 32.w),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QrImageView(
                    data: 'ws://tv-ip:8765/config',
                    version: QrVersions.auto,
                    size: 150.w,
                    backgroundColor: Colors.white,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '扫码编辑',
                    style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showChangeCodeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('修改暗号', style: TextStyle(color: Colors.white)),
        content: const Text(
          '使用方向键录制 4-8 位新暗号，需二次确认。',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('开始录制'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF141414),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '设置',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 32.h),
              _buildSettingItem(Icons.wifi, 'WebSocket 同步', 'ws://0.0.0.0:${AppConstants.wsPort}'),
              _buildSettingItem(Icons.devices, '设备 ID', 'tv-living-room'),
              _buildSettingItem(Icons.sync, '云端同步', '已启用'),
              const Spacer(),
              Text(
                AppConstants.appName,
                style: TextStyle(color: Colors.grey, fontSize: 14.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF6B35), size: 24.sp),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.white, fontSize: 16.sp)),
              Text(value, style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
            ],
          ),
        ],
      ),
    );
  }
}
