import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/providers/stealth_provider.dart';
import '../../core/providers/node_provider.dart';
import '../../shared/constants.dart';
import '../widgets/stripe_background.dart';
import '../widgets/recently_played_card.dart';
import '../widgets/favorite_card.dart';
import '../widgets/resource_card.dart';
import '../widgets/stealth_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _row1Controller = ScrollController();
  final ScrollController _row2Controller = ScrollController();
  final ScrollController _row3Controller = ScrollController();
  final List<LogicalKeyboardKey> _keyBuffer = [];
  DateTime? _lastKeyPressTime;

  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  final List<Map<String, dynamic>> _recentItems = [];

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _flashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );
    _flashController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _flashController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _row1Controller.dispose();
    _row2Controller.dispose();
    _row3Controller.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stealthMode = ref.watch(stealthProvider);
    final nodes = ref.watch(nodeProvider);
    final favorites = ref.watch(favoriteProvider);

    final isUnlocked = stealthMode == StealthMode.unlocked;
    final isGlowing = stealthMode == StealthMode.glowing;

    if (isUnlocked && _flashController.isDismissed) {
      _flashController.forward();
    }

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
            // 1. Stripe pattern background
            const StripeBackground(),

            // 2. Purple flash overlay on stealth unlock
            AnimatedBuilder(
              animation: _flashAnimation,
              builder: (context, child) {
                return Container(
                  color: const Color(0xFFBB86FC).withOpacity(
                    _flashAnimation.value * 0.3,
                  ),
                );
              },
            ),

            // 3. Main content: three rows, fixed one screen
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 96.w,
                  right: 96.w,
                  top: 54.h,
                  bottom: 54.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Recently Played (手风琴大图行)
                    RepaintBoundary(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('最近播放'),
                          SizedBox(height: 16.h),
                          SizedBox(
                            height: 400.h,
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
                                    clipBehavior: Clip.none,
                                    itemCount: _recentItems.length + 1,
                                    itemBuilder: (_, index) {
                                      if (index == _recentItems.length) {
                                        return Padding(
                                          padding: EdgeInsets.only(right: 24.w),
                                          child: RecentlyPlayedCard(
                                            title: '播放历史',
                                            isHistoryButton: true,
                                          ),
                                        );
                                      }
                                      final item = _recentItems[index];
                                      return Padding(
                                        padding: EdgeInsets.only(right: 24.w),
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

                    SizedBox(height: 32.h),

                    // Row 2: Favorites (快捷网格行)
                    RepaintBoundary(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('快捷路径'),
                          SizedBox(height: 16.h),
                          SizedBox(
                            height: 160.h,
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
                                    clipBehavior: Clip.none,
                                    itemCount: favorites.length,
                                    itemBuilder: (_, index) {
                                      final fav = favorites[index];
                                      return Padding(
                                        padding: EdgeInsets.only(right: 20.w),
                                        child: SizedBox(
                                          width: 160.w,
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

                    SizedBox(height: 32.h),

                    // Row 3: Resources (模块化条纹块)
                    RepaintBoundary(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildSectionTitle('资源中心'),
                              if (!isUnlocked)
                                Padding(
                                  padding: EdgeInsets.only(left: 8.w),
                                  child: Icon(Icons.lock_outline, color: Colors.grey, size: 18.sp),
                                ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          SizedBox(
                            height: 160.h,
                            child: ListView.builder(
                              controller: _row3Controller,
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              itemCount: visibleNodes.length + 1,
                              itemBuilder: (_, index) {
                                if (index == visibleNodes.length) {
                                  return Padding(
                                    padding: EdgeInsets.only(right: 20.w),
                                    child: Focus(
                                      onFocusChange: (_) {},
                                      onKeyEvent: (node, event) {
                                        if (event is KeyDownEvent) {
                                          if (event.logicalKey == LogicalKeyboardKey.select ||
                                              event.logicalKey == LogicalKeyboardKey.enter) {
                                            _showAddResourceDialog(context);
                                            return KeyEventResult.handled;
                                          }
                                          if (event.logicalKey == LogicalKeyboardKey.contextMenu ||
                                              event.logicalKey == LogicalKeyboardKey.keyM) {
                                            if (isUnlocked) _showChangeCodeDialog(context);
                                            return KeyEventResult.handled;
                                          }
                                        }
                                        return KeyEventResult.ignored;
                                      },
                                      child: Container(
                                        width: 160.w,
                                        height: 160.h,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E1E1E),
                                          borderRadius: BorderRadius.circular(12.r),
                                          border: Border.all(color: Colors.white10),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.add_rounded,
                                            size: 64.sp,
                                            color: const Color(0xFFFF6B35),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                final node = visibleNodes[index];
                                return Padding(
                                  padding: EdgeInsets.only(right: 20.w),
                                  child: SizedBox(
                                    width: 160.w,
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

            // 4. Top-right settings icon
            Positioned(
              top: 54.h,
              right: 96.w,
              child: Focus(
                onFocusChange: (focused) {
                  if (focused && isGlowing) {
                    _showStealthInputDialog(context);
                  }
                },
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.select ||
                        event.logicalKey == LogicalKeyboardKey.enter) {
                      if (!isGlowing) {
                        Scaffold.of(context).openEndDrawer();
                      }
                      return KeyEventResult.handled;
                    }
                    if (event.logicalKey == LogicalKeyboardKey.select ||
                        event.logicalKey == LogicalKeyboardKey.enter) {
                      // Long press detection handled by timer
                    }
                  }
                  return KeyEventResult.ignored;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isGlowing
                        ? const Color(0xFFBB86FC).withOpacity(0.6)
                        : Colors.transparent,
                    boxShadow: isGlowing
                        ? [
                            BoxShadow(
                              color: const Color(0xFFBB86FC).withOpacity(0.8),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.settings,
                      color: isGlowing ? Colors.white : Colors.grey[400],
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white,
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
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
