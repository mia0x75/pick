import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
import '../widgets/recently_played_context_menu.dart';
import '../widgets/favorites_context_menu.dart';

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

  // 定义初始焦点节点
  final FocusNode _firstItemFocusNode = FocusNode();

  bool _showSecretOverlay = false;
  bool _showContextMenu = false;
  String _contextMenuType = ''; // 'recently', 'favorites', 'resources'
  StorageNode? _contextMenuNode;
  int _contextMenuIndex = -1;

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
    _firstItemFocusNode.dispose();
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

    // 暗号遮罩逻辑 (保持不变)
    if (_showSecretOverlay) { /* ... 原有代码 ... */ }

    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          _handleKeyPress(event.logicalKey);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        // 侧边栏
        endDrawer: SettingsDrawer(onClose: () => Navigator.of(context).pop()),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. 背景层
            Image.asset('assets/images/splash_background.png', fit: BoxFit.cover),
            Container(color: const Color(0xFF000000).withOpacity(0.7)),

            // 2. 隐私闪烁 (保持不变)
            AnimatedBuilder(
              animation: _flashAnimation,
              builder: (context, child) => Container(
                color: const Color(0xFFBB86FC).withOpacity(_flashAnimation.value * 0.3),
              ),
            ),

            // 3. 核心内容布局 (修复点：移除 SafeArea，引入内容权重分配)
            Padding(
              padding: EdgeInsets.fromLTRB(96.w, 54.h, 96.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部标题栏：融合设置图标，解决导航问题
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildSectionTitle('最近播放'),
                      _buildSettingsIcon(isGlowing),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Row 1: 最近播放 (固定高度)
                  SizedBox(
                    height: 400.h,
                    child: _buildRecentList(), // 封装后的列表逻辑
                  ),

                  const Spacer(flex: 2), // 弹性间距：解决底部溢出

                  // Row 2: 快捷路径
                  _buildSectionTitle('快捷路径'),
                  SizedBox(height: 16.h),
                  SizedBox(
                    height: 160.h,
                    child: _buildFavoritesList(favorites),
                  ),

                  const Spacer(flex: 2), // 弹性间距：解决底部溢出

                  // Row 3: 资源中心
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
                    child: _buildResourcesList(visibleNodes, isUnlocked),
                  ),
                ],
              ),
            ),

            // 4. 右键菜单遮罩 (保持不变)
            if (_showContextMenu)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _showContextMenu = false),
                  child: _buildContextMenu(),
                ),
              ),
          ],
        ),
      ),
    );
  }

Widget _buildRecentList() {
    if (_recentItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, size: 48.sp, color: Colors.grey),
            SizedBox(height: 8.h),
            Text('暂无播放记录', style: TextStyle(color: Colors.grey, fontSize: 16.sp)),
          ],
        ),
      );
    }
    return ListView.builder(
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
              onMenu: () => _showRecentlyPlayedMenu(isHistory: true),
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
            onMenu: () => _showRecentlyPlayedMenu(index: index),
          ),
        );
      },
    );
  }

  Widget _buildFavoritesList(List<FavoriteNode> favorites) {
    if (favorites.isEmpty) {
      return Center(
        child: Text('暂无收藏', style: TextStyle(color: Colors.grey, fontSize: 16.sp)),
      );
    }
    return ListView.builder(
      controller: _row2Controller,
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      itemCount: favorites.length,
      itemBuilder: (_, index) {
        final fav = favorites[index];
        return Padding(
          padding: EdgeInsets.only(right: 20.w),
          child: FavoriteCard(
            name: fav.name,
            posterUrl: fav.posterUrl,
            onMenu: () => _showFavoritesMenu(index: index),
          ),
        );
      },
    );
  }

  Widget _buildResourcesList(List<StorageNode> visibleNodes, bool isUnlocked) {
    return ListView.builder(
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
          child: ResourceCard(
            node: node,
            onMenu: () => _showResourceMenu(node),
          ),
        );
      },
    );
  }

  Widget _buildContextMenu() {
    switch (_contextMenuType) {
      case 'recently':
        return RecentlyPlayedContextMenu(
          isHistoryButton: _contextMenuIndex < 0,
          onResume: () {
            // TODO: Resume playback from history
          },
          onRestart: () {
            // TODO: Restart from 00:00:00
          },
          onLocate: () {
            // TODO: Jump to source resource in Row 3
          },
          onRemove: () {
            if (_contextMenuIndex >= 0) {
              setState(() => _recentItems.removeAt(_contextMenuIndex));
            }
          },
          onClearAll: () => _confirmClearHistory(),
          onClose: () => setState(() => _showContextMenu = false),
        );
      case 'favorites':
        return FavoritesContextMenu(
          onRename: () => _showAddResourceDialog(context),
          onReorder: () {},
          onChangeCover: () {},
          onUnpin: () {
            // TODO: Remove from favorites
          },
          onClose: () => setState(() => _showContextMenu = false),
        );
      case 'resources':
        if (_contextMenuNode == null) return const SizedBox.shrink();
        return ResourceContextMenu(
          node: _contextMenuNode!,
          isUnlocked: ref.read(stealthProvider) == StealthMode.unlocked,
          onTogglePrivate: (isPrivate) {
            ref.read(nodeProvider.notifier).togglePrivate(
              _contextMenuNode!.id,
              isPrivate,
            );
          },
          onEditConfig: () => _showAddResourceDialog(context),
          onTestConnection: () => _showToast('测试连接功能开发中'),
          onDelete: () => _confirmDeleteResource(_contextMenuNode!),
          onClose: () => setState(() => _showContextMenu = false),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showRecentlyPlayedMenu({int? index, bool isHistory = false}) {
    setState(() {
      _contextMenuType = 'recently';
      _contextMenuIndex = index ?? -1;
      _contextMenuNode = null;
      _showContextMenu = true;
    });
  }

  void _showFavoritesMenu({int? index}) {
    setState(() {
      _contextMenuType = 'favorites';
      _contextMenuIndex = index ?? -1;
      _contextMenuNode = null;
      _showContextMenu = true;
    });
  }

  void _showResourceMenu(StorageNode node) {
    setState(() {
      _contextMenuType = 'resources';
      _contextMenuNode = node;
      _contextMenuIndex = -1;
      _showContextMenu = true;
    });
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('确认清空', style: TextStyle(color: Colors.white)),
        content: const Text(
          '清空所有播放历史记录？此操作不可撤销。',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _recentItems.clear());
              Hive.box(AppConstants.historyBox).clear();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
            ),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteResource(StorageNode node) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('确认删除', style: TextStyle(color: Colors.white)),
        content: Text(
          '彻底删除"${node.name}"？\n此操作将清除所有配置、账号密码及关联收藏，不可撤销。',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(nodeProvider.notifier).removeNode(node.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
            ),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1E1E1E),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
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

  void _showAddResourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('添加资源 (手机联动)', style: TextStyle(color: Colors.white, fontSize: 24.sp)),
        content: SizedBox(
          width: 600.w,
          child: Row(
            children: [
              // 电视端显示只读状态，不使用 TextField 避免吞焦点
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildReadOnlyInput('别名', '请在手机端输入...'),
                    SizedBox(height: 16.h),
                    _buildReadOnlyInput('协议类型', '等待手机端选择...'),
                    SizedBox(height: 16.h),
                    _buildReadOnlyInput('地址', '等待同步...'),
                  ],
                ),
              ),
              SizedBox(width: 32.w),
              // 二维码区域
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: QrImageView(
                      data: 'ws://tv-ip:8765/config',
                      version: QrVersions.auto,
                      size: 140.w,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  const Text('手机扫码配置', style: TextStyle(color: Color(0xFFBB86FC), fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          // 使用自定义的可聚焦按钮
          _buildDialogAction('取消', () => Navigator.pop(context), isPrimary: false),
          _buildDialogAction('保存', () => Navigator.pop(context), isPrimary: true),
        ],
      ),
    );
  }

  // 辅助组件：只读样式框
  Widget _buildReadOnlyInput(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(color: Colors.black26, border: Border.all(color: Colors.white10)),
          child: Text(value, style: TextStyle(color: Colors.white38)),
        )
      ],
    );
  }

  // 辅助组件：电视焦点按钮
  Widget _buildDialogAction(String text, VoidCallback onTap, {required bool isPrimary}) {
    return StatefulBuilder(builder: (context, setState) {
      bool isFocused = false;
      return Focus(
        onFocusChange: (f) => setState(() => isFocused = f),
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) {
            onTap();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isFocused ? (isPrimary ? const Color(0xFFFF6B35) : Colors.white24) : Colors.transparent,
            border: Border.all(color: isFocused ? Colors.white : Colors.white10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(text, style: TextStyle(color: isFocused ? Colors.white : (isPrimary ? const Color(0xFFFF6B35) : Colors.grey))),
        ),
      );
    });
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
