import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/providers/stealth_provider.dart';
import '../../core/providers/node_provider.dart';
import '../../core/models/storage_node.dart' show StorageNode, StorageType, NodeCategory, FavoriteNode;
import '../../shared/constants.dart';
import '../widgets/recently_played_card.dart';
import '../widgets/favorite_card.dart';
import '../widgets/resource_card.dart';
import '../widgets/settings_drawer.dart';
import '../widgets/resource_context_menu.dart';
import '../widgets/recently_played_context_menu.dart';
import '../widgets/favorites_context_menu.dart';
import '../widgets/secret_code_overlay.dart';

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

  List<Map<String, dynamic>> _recentItems = [];

  final FocusNode _keyboardFocusNode = FocusNode();

  final List<FocusNode> _row1FocusNodes = [];
  final List<FocusNode> _row2FocusNodes = [];
  final List<FocusNode> _row3FocusNodes = [];

  int _currentFocusRow = -1;
  int _currentFocusIndex = 0;
  final FocusNode _settingsFocusNode = FocusNode();

  bool _showBackHint = false;
  DateTime? _lastBackPressTime;
  static const _backPressInterval = Duration(seconds: 2);

  static const bool _isDebug = kDebugMode;

  // 本地 debug 数据（不依赖 Hive）
  final List<FavoriteNode> _debugFavorites = [
    FavoriteNode(
      id: 'debug_fav_1',
      name: '电影收藏',
      sourceNodeId: 'debug_node_1',
      path: '/movies',
      posterUrl: 'https://picsum.photos/200/300',
      sortOrder: 0,
    ),
    FavoriteNode(
      id: 'debug_fav_2',
      name: '音乐收藏',
      sourceNodeId: 'debug_node_2',
      path: '/music',
      posterUrl: 'https://picsum.photos/200/301',
      sortOrder: 1,
    ),
  ];

  final List<StorageNode> _debugNodes = [
    StorageNode(
      id: 'debug_node_1',
      name: 'NAS 电影',
      type: StorageType.smb,
      baseUrl: 'smb://192.168.1.100/share1',
      username: 'guest',
      password: '',
      category: NodeCategory.normal,
      sortOrder: 0,
    ),
    StorageNode(
      id: 'debug_node_2',
      name: 'WebDAV 文档',
      type: StorageType.webdav,
      baseUrl: 'https://192.168.1.101/dav',
      username: 'admin',
      password: '123456',
      category: NodeCategory.normal,
      sortOrder: 1,
    ),
  ];

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

    if (_isDebug) {
      _recentItems = [
        {
          'title': '测试视频 1',
          'poster': 'https://picsum.photos/300/450',
          'preview': null,
          'progress': 0.35,
        },
        {
          'title': '测试视频 2',
          'poster': 'https://picsum.photos/300/451',
          'preview': null,
          'progress': 0.72,
        },
        {
          'title': '测试视频 3',
          'poster': 'https://picsum.photos/300/452',
          'preview': null,
          'progress': 0.0,
        },
      ];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _addDebugFavorites();
        _initFocus();
      });
    }
  }

  void _initFocus() {
    final nodes = ref.read(nodeProvider);
    final favorites = ref.read(favoriteProvider);
    final isUnlocked = ref.read(stealthProvider) == StealthMode.unlocked;
    final visibleNodes = nodes.where((n) => isUnlocked || !n.isPrivate).toList();

    final row1HasContent = _recentItems.isNotEmpty;
    final row2HasContent = favorites.isNotEmpty;
    final row3HasContent = visibleNodes.isNotEmpty;

    if (row1HasContent) {
      _currentFocusRow = 0;
      _currentFocusIndex = 0;
    } else if (row2HasContent) {
      _currentFocusRow = 1;
      _currentFocusIndex = 0;
    } else if (row3HasContent) {
      _currentFocusRow = 2;
      _currentFocusIndex = 0;
    } else {
      _currentFocusRow = 2;
      _currentFocusIndex = 0;
    }
    setState(() {});
  }

  void _addDebugFavorites() {
    if (!mounted) return;
    final favNotifier = ref.read(favoriteProvider.notifier);
    final currentFavs = ref.read(favoriteProvider);
    if (currentFavs.isEmpty) {
      favNotifier.addFavorite(
        FavoriteNode(
          id: 'debug_fav_1',
          name: '测试收藏 1',
          sourceNodeId: 'debug_node_1',
          path: '/movies',
          posterUrl: 'https://picsum.photos/200/300',
          sortOrder: 0,
        ),
      );
      favNotifier.addFavorite(
        FavoriteNode(
          id: 'debug_fav_2',
          name: '测试收藏 2',
          sourceNodeId: 'debug_node_2',
          path: '/music',
          posterUrl: 'https://picsum.photos/200/301',
          sortOrder: 1,
        ),
      );
    }
    _addDebugNodes();
  }

  void _addDebugNodes() {
    if (!mounted) return;
    final nodeNotifier = ref.read(nodeProvider.notifier);
    final currentNodes = ref.read(nodeProvider);
    if (currentNodes.isEmpty) {
      nodeNotifier.addNode(
        StorageNode(
          id: 'debug_node_1',
          name: '测试资源 1',
          type: StorageType.smb,
          baseUrl: 'smb://192.168.1.100/share1',
          username: 'guest',
          password: '',
          category: NodeCategory.normal,
          sortOrder: 0,
        ),
      );
      nodeNotifier.addNode(
        StorageNode(
          id: 'debug_node_2',
          name: '测试资源 2',
          type: StorageType.webdav,
          baseUrl: 'https://192.168.1.101/dav',
          username: 'admin',
          password: '123456',
          category: NodeCategory.normal,
          sortOrder: 1,
        ),
      );
    }
  }

  @override
  void dispose() {
    _row1Controller.dispose();
    _row2Controller.dispose();
    _row3Controller.dispose();
    _flashController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stealthMode = ref.watch(stealthProvider);
    final nodes = ref.watch(nodeProvider);
    final favorites = ref.watch(favoriteProvider);
    final isUnlocked = stealthMode == StealthMode.unlocked;
    final isGlowing = stealthMode == StealthMode.glowing;

    // DEBUG 模式使用本地数据
    final displayFavorites = _isDebug && favorites.isEmpty ? _debugFavorites : favorites;
    final displayNodes = _isDebug && nodes.isEmpty ? _debugNodes : nodes;

    return Focus(
      autofocus: true,
      child: KeyboardListener(
        focusNode: _keyboardFocusNode..requestFocus(),
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
              Image.asset(
                'assets/images/splash_background.png',
                fit: BoxFit.cover,
                cacheWidth: 1280,
              ),
              Container(color: const Color(0xFF000000).withOpacity(0.7)),

              // 2. 隐私闪烁
              AnimatedBuilder(
                animation: _flashAnimation,
                builder: (context, child) => Container(
                  color: const Color(0xFFBB86FC).withOpacity(_flashAnimation.value * 0.3),
                ),
              ),

              // 3. 核心内容布局
              Padding(
                padding: EdgeInsets.fromLTRB(40.w, 20.h, 40.w, 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 顶部 Logo 区域
                    SizedBox(
                      height: 50.h,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '片刻',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 48.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Text(
                                '极简 · 安全 · 互通',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 22.sp,
                                ),
                              ),
                            ],
                          ),
                          _buildSettingsIcon(isGlowing, _currentFocusRow == 3),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Row 1: 最近播放
                    _buildSectionTitle('最近播放'),
                    SizedBox(height: 8.h),
                    SizedBox(
                      height: 230.h,
                      child: _buildRecentList(),
                    ),

                    SizedBox(height: 20.h),

                    // Row 2: 快捷路径
                    _buildSectionTitle('快捷路径'),
                    SizedBox(height: 8.h),
                    SizedBox(
                      height: 150.h,
                      child: _buildFavoritesList(displayFavorites),
                    ),

                    SizedBox(height: 20.h),

                    // Row 3: 资源中心
                    _buildSectionTitle('资源中心'),
                    SizedBox(height: 8.h),
                    SizedBox(
                      height: 150.h,
                      child: _buildResourcesList(displayNodes.where((n) => isUnlocked || !n.isPrivate).toList(), isUnlocked),
                    ),
                  ],
                ),
              ),

              // 4. 右键菜单遮罩
              if (_showContextMenu)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _showContextMenu = false),
                    child: _buildContextMenu(),
                  ),
                ),

              // 5. 暗号遮罩层
              if (_showSecretOverlay)
                const SecretCodeOverlay(),

              // 6. 返回提示
              if (_showBackHint)
                Positioned(
                  bottom: 60.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '再按一次返回键退出',
                        style: TextStyle(color: Colors.white, fontSize: 24.sp),
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

Widget _buildRecentList() {
    if (_recentItems.isEmpty) {
      return Center(
        child: Text(
          '暂无播放记录',
          style: TextStyle(color: Colors.grey, fontSize: 24.sp),
        ),
      );
    }
    return ListView.builder(
      controller: _row1Controller,
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      itemCount: _recentItems.length + 1,
      itemBuilder: (_, index) {
        final isFocused = _currentFocusRow == 0 && _currentFocusIndex == index;
        
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
        child: Text('暂无收藏', style: TextStyle(color: Colors.grey, fontSize: 24.sp)),
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

  Widget _buildSettingsIcon(bool isGlowing, bool hasFocus) {
    DateTime? pressStartTime;

    return StatefulBuilder(
      builder: (context, setState) {
        return Focus(
          focusNode: _settingsFocusNode,
          autofocus: hasFocus,
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
            width: 56.w,
            height: 56.h,
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
                size: 28.sp,
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
      style: TextStyle(
        color: Colors.white70,
        fontSize: 32.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  void _handleKeyPress(LogicalKeyboardKey key) {
    final stealthMode = ref.read(stealthProvider);
    
    if (key == LogicalKeyboardKey.back || key == LogicalKeyboardKey.escape) {
      final now = DateTime.now();
      if (_lastBackPressTime != null && 
          now.difference(_lastBackPressTime!) < _backPressInterval) {
        SystemNavigator.pop();
      } else {
        _lastBackPressTime = now;
        setState(() => _showBackHint = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showBackHint = false);
        });
      }
      return;
    }
    
    if (stealthMode == StealthMode.glowing) {
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
      return;
    }

    _handleNavigation(key);
  }

  void _handleNavigation(LogicalKeyboardKey key) {
    final nodes = ref.read(nodeProvider);
    final favorites = ref.read(favoriteProvider);
    final isUnlocked = ref.read(stealthProvider) == StealthMode.unlocked;
    final visibleNodes = nodes.where((n) => isUnlocked || !n.isPrivate).toList();

    final row1ItemCount = _recentItems.length + 1;
    final row2ItemCount = favorites.length;
    final row3ItemCount = visibleNodes.length + 1;

    int? newRow;
    int? newIndex;

    switch (key) {
      case LogicalKeyboardKey.arrowUp:
        if (_currentFocusRow == 3) {
          if (row2ItemCount > 0) {
            newRow = 1;
            newIndex = 0;
          } else if (row1ItemCount > 0) {
            newRow = 0;
            newIndex = 0;
          } else {
            newRow = 2;
            newIndex = 0;
          }
        } else if (_currentFocusRow == 2) {
          if (row2ItemCount > 0) {
            newRow = 1;
            newIndex = 0;
          } else if (row1ItemCount > 0) {
            newRow = 0;
            newIndex = 0;
          } else {
            newRow = 3;
            newIndex = 0;
          }
        } else if (_currentFocusRow == 1) {
          if (row1ItemCount > 0) {
            newRow = 0;
            newIndex = 0;
          } else if (row3ItemCount > 0) {
            newRow = 2;
            newIndex = 0;
          } else {
            newRow = 3;
            newIndex = 0;
          }
        } else if (_currentFocusRow == 0) {
          newRow = 3;
          newIndex = 0;
        }
        break;
      case LogicalKeyboardKey.arrowDown:
        if (_currentFocusRow == 3 || _currentFocusRow == -1) {
          if (row1ItemCount > 0) {
            newRow = 0;
            newIndex = 0;
          } else if (row2ItemCount > 0) {
            newRow = 1;
            newIndex = 0;
          } else if (row3ItemCount > 0) {
            newRow = 2;
            newIndex = 0;
          }
        } else if (_currentFocusRow == 0) {
          if (row2ItemCount > 0) {
            newRow = 1;
            newIndex = 0;
          } else if (row3ItemCount > 0) {
            newRow = 2;
            newIndex = 0;
          } else {
            newRow = 3;
            newIndex = 0;
          }
        } else if (_currentFocusRow == 1) {
          if (row3ItemCount > 0) {
            newRow = 2;
            newIndex = 0;
          } else {
            newRow = 3;
            newIndex = 0;
          }
        } else if (_currentFocusRow == 2) {
          newRow = 3;
          newIndex = 0;
        }
        break;
      case LogicalKeyboardKey.arrowLeft:
        if (_currentFocusRow == 3) break;
        if (_currentFocusIndex > 0) {
          newRow = _currentFocusRow;
          newIndex = _currentFocusIndex - 1;
        }
        break;
      case LogicalKeyboardKey.arrowRight:
        if (_currentFocusRow == 3) {
          if (row1ItemCount > 0) {
            newRow = 0;
            newIndex = 0;
          } else if (row2ItemCount > 0) {
            newRow = 1;
            newIndex = 0;
          } else if (row3ItemCount > 0) {
            newRow = 2;
            newIndex = 0;
          }
        } else if (_currentFocusRow == 0) {
          if (_currentFocusIndex < row1ItemCount - 1) {
            newRow = 0;
            newIndex = _currentFocusIndex + 1;
          } else if (row2ItemCount > 0) {
            newRow = 1;
            newIndex = 0;
          } else {
            newRow = 3;
            newIndex = 0;
          }
        } else if (_currentFocusRow == 1) {
          if (_currentFocusIndex < row2ItemCount - 1) {
            newRow = 1;
            newIndex = _currentFocusIndex + 1;
          } else if (row3ItemCount > 0) {
            newRow = 2;
            newIndex = 0;
          } else if (row1ItemCount > 0) {
            newRow = 0;
            newIndex = 0;
          } else {
            newRow = 3;
            newIndex = 0;
          }
        } else if (_currentFocusRow == 2) {
          if (_currentFocusIndex < row3ItemCount - 1) {
            newRow = 2;
            newIndex = _currentFocusIndex + 1;
          } else if (row1ItemCount > 0) {
            newRow = 0;
            newIndex = 0;
          } else if (row2ItemCount > 0) {
            newRow = 1;
            newIndex = 0;
          } else {
            newRow = 3;
            newIndex = 0;
          }
        }
        break;
      default:
        break;
    }

    if (newRow != null) {
      _currentFocusRow = newRow;
      _currentFocusIndex = newIndex ?? 0;
      setState(() {});
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
        ),
      ],
    );
  }

  // 辅助组件：电视焦点按钮
Widget _buildDialogAction(String text, VoidCallback onTap, {required bool isPrimary}) {
  return StatefulBuilder(builder: (context, setState) {
    // 1. 显式声明变量，确保分析器知道它是一个可变量
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
        // 方案：使用变量预存储样式，避免在 Widget 树内部进行复杂的逻辑分支判断
        decoration: _getButtonStyle(isFocused, isPrimary),
        child: Center(
          child: Text(
            text,
            style: _getButtonTextStyle(isFocused, isPrimary),
          ),
        ),
      ),
    );
  },
  );
}

// 2. 将逻辑抽离成独立的私有方法，彻底解决 Dead Code 误报
BoxDecoration? _getButtonStyle(bool isFocused, bool isPrimary) {
  if (!isFocused) return null;

  return BoxDecoration(
    borderRadius: BorderRadius.circular(8.r),
    color: isPrimary ? const Color(0xFFFF6B35) : Colors.white24,
    border: Border.all(color: Colors.white, width: 2.w),
  );
}

TextStyle _getButtonTextStyle(bool isFocused, bool isPrimary) {
  if (isFocused) {
    return TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 18.sp,
      color: Colors.white, // 显式写出来以防万一
    );
  }

  return TextStyle(
    color: isPrimary ? const Color(0xFFFF6B35) : Colors.grey,
    fontSize: 18.sp,
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
