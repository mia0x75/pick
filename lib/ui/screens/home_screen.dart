import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/providers/stealth_provider.dart';
import '../../core/providers/node_provider.dart';
import '../../core/models/storage_node.dart';
import '../../shared/constants.dart';
import '../widgets/recently_played_card.dart';
import '../widgets/favorite_card.dart';
import '../widgets/resource_card.dart';
import '../widgets/secret_code_overlay.dart';
import '../widgets/settings_drawer.dart';
import '../widgets/resource_context_menu.dart';
import 'history_page.dart';

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

  bool _showSecretOverlay = false;
  bool _showContextMenu = false;
  StorageNode? _contextMenuNode;

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

    // Secret code overlay
    if (_showSecretOverlay) {
      return SecretCodeOverlay(
        onCodeComplete: (code) {
          ref.read(stealthProvider.notifier).verifyCode(
            code.map((k) => AppConstants.defaultSecretCode.indexOf(k)).toList(),
          );
          setState(() => _showSecretOverlay = false);
        },
        onCancel: () {
          ref.read(stealthProvider.notifier).lock();
          setState(() => _showSecretOverlay = false);
        },
      );
    }

    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          _handleKeyPress(event.logicalKey);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        endDrawer: SettingsDrawer(
          onClose: () => Navigator.of(context).pop(),
        ),
        body: Stack(
          children: [
            // 1. Background image
            Image.asset(
              'assets/images/splash_background.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            Container(color: const Color(0xFF000000).withOpacity(0.7)),

            // 2. Purple flash overlay
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

            // 3. Context menu overlay
            if (_showContextMenu && _contextMenuNode != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _showContextMenu = false),
                  child: ResourceContextMenu(
                    node: _contextMenuNode!,
                    onTogglePrivate: (isPrivate) {
                      ref.read(nodeProvider.notifier).togglePrivate(
                        _contextMenuNode!.id,
                        isPrivate,
                      );
                    },
                    onMove: () {},
                    onEdit: () {},
                    onDelete: () {
                      ref.read(nodeProvider.notifier).removeNode(
                        _contextMenuNode!.id,
                      );
                    },
                    onClose: () => setState(() => _showContextMenu = false),
                  ),
                ),
              ),

            // 4. Main content
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 96.w,
                  right: 96.w,
                  top: 54.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Recently Played
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
                                          child: _buildHistoryButton(),
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

                    // Row 2: Favorites
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
                                            onMenu: () {},
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

                    // Row 3: Resources
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
                                    child: _buildAddResourceButton(isUnlocked),
                                  );
                                }
                                final node = visibleNodes[index];
                                return Padding(
                                  padding: EdgeInsets.only(right: 20.w),
                                  child: SizedBox(
                                    width: 160.w,
                                    child: ResourceCard(
                                      node: node,
                                      onMenu: isUnlocked
                                          ? () => _showResourceMenu(node)
                                          : null,
                                    ),
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

            // 5. Settings icon
            Positioned(
              top: 54.h,
              right: 96.w,
              child: _buildSettingsIcon(isGlowing),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryButton() {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space ||
              event.logicalKey == LogicalKeyboardKey.arrowRight) {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, a, __) => FadeTransition(
                  opacity: a,
                  child: HistoryPage(
                    onBack: () => Navigator.of(context).pop(),
                  ),
                ),
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: RecentlyPlayedCard(
        title: '播放历史',
        isHistoryButton: true,
      ),
    );
  }

  Widget _buildAddResourceButton(bool isUnlocked) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
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
    );
  }

  Widget _buildSettingsIcon(bool isGlowing) {
    DateTime? pressStartTime;

    return StatefulBuilder(
      builder: (context, setState) {
        return Focus(
          onFocusChange: (focused) {
            if (focused) pressStartTime = null;
          },
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.select ||
                  event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space) {
                pressStartTime = DateTime.now();
                return KeyEventResult.handled;
              }
            }
            if (event is KeyUpEvent) {
              if (event.logicalKey == LogicalKeyboardKey.select ||
                  event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space) {
                if (pressStartTime != null) {
                  final duration = DateTime.now().difference(pressStartTime!);
                  if (duration >= const Duration(seconds: 3)) {
                    setState(() => _showSecretOverlay = true);
                    ref.read(stealthProvider.notifier).startUnlockSequence();
                  } else {
                    if (!isGlowing) {
                      Scaffold.of(context).openEndDrawer();
                    }
                  }
                  pressStartTime = null;
                }
                return KeyEventResult.handled;
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
                color: isGlowing ? Colors.white : Colors.grey[400],
                size: 24.sp,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showResourceMenu(StorageNode node) {
    setState(() {
      _contextMenuNode = node;
      _showContextMenu = true;
    });
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
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
                  const Text(
                    '扫码编辑',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
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
}
