import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HistoryPage extends StatefulWidget {
  final VoidCallback onBack;

  const HistoryPage({super.key, required this.onBack});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final List<Map<String, dynamic>> _historyItems = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            top: 54.h,
            left: 96.w,
            right: 96.w,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '播放历史',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      _FocusableButton(
                        label: '清空历史',
                        color: const Color(0xFFFF6B35),
                        onTap: _confirmClearHistory,
                      ),
                      SizedBox(width: 24.w),
                      Focus(
                        child: Container(
                          width: 48.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Icon(
                            Icons.search,
                            color: Colors.grey[400],
                            size: 28.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 32.h),
              // Grid
              Expanded(
                child: _historyItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64.sp, color: Colors.grey),
                            SizedBox(height: 16.h),
                            Text(
                              '暂无播放记录',
                              style: TextStyle(color: Colors.grey, fontSize: 18.sp),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 24.h,
                          crossAxisSpacing: 24.w,
                          childAspectRatio: 16 / 9,
                        ),
                        itemCount: _historyItems.length,
                        itemBuilder: (_, index) {
                          final item = _historyItems[index];
                          return _HistoryCard(
                            title: item['title'] ?? '',
                            progress: item['progress'] ?? 0.0,
                            onTap: () {},
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
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
              setState(() => _historyItems.clear());
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
}

class _HistoryCard extends StatefulWidget {
  final String title;
  final double progress;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.title,
    required this.progress,
    required this.onTap,
  });

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _hasFocus = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedScale(
        scale: _hasFocus ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            color: const Color(0xFF1E1E1E),
            border: Border.all(
              color: _hasFocus ? const Color(0xFFBB86FC) : Colors.transparent,
              width: 2.w,
            ),
            boxShadow: _hasFocus
                ? [
                    BoxShadow(
                      color: const Color(0xFFBB86FC).withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: const Color(0xFF2C2C2C)),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  padding: EdgeInsets.all(8.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      LinearProgressIndicator(
                        value: widget.progress,
                        backgroundColor: Colors.white30,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFBB86FC)),
                        minHeight: 3.h,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusableButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FocusableButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_FocusableButton> createState() => _FocusableButtonState();
}

class _FocusableButtonState extends State<_FocusableButton> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _hasFocus = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedScale(
        scale: _hasFocus ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            color: _hasFocus ? widget.color : Colors.transparent,
            border: Border.all(color: widget.color),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: _hasFocus ? Colors.white : widget.color,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
