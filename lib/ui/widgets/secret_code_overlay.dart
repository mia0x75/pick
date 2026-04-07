import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../shared/constants.dart';

class SecretCodeOverlay extends StatefulWidget {
  final Function(List<LogicalKeyboardKey>) onCodeComplete;
  final Function() onCancel;

  const SecretCodeOverlay({
    super.key,
    required this.onCodeComplete,
    required this.onCancel,
  });

  @override
  State<SecretCodeOverlay> createState() => _SecretCodeOverlayState();
}

class _SecretCodeOverlayState extends State<SecretCodeOverlay> {
  final List<LogicalKeyboardKey> _inputBuffer = [];
  final List<int> _recentKeys = []; // Stores which key was pressed recently for animation
  final List<Timer> _timers = [];

  IconData _getArrowIcon(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowUp) return Icons.arrow_upward;
    if (key == LogicalKeyboardKey.arrowDown) return Icons.arrow_downward;
    if (key == LogicalKeyboardKey.arrowLeft) return Icons.arrow_back;
    if (key == LogicalKeyboardKey.arrowRight) return Icons.arrow_forward;
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.select) return Icons.check;
    return Icons.circle;
  }

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    // Back to cancel
    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack) {
      widget.onCancel();
      return;
    }

    // Only accept directional keys and enter
    if (event.logicalKey != LogicalKeyboardKey.arrowUp &&
        event.logicalKey != LogicalKeyboardKey.arrowDown &&
        event.logicalKey != LogicalKeyboardKey.arrowLeft &&
        event.logicalKey != LogicalKeyboardKey.arrowRight &&
        event.logicalKey != LogicalKeyboardKey.enter &&
        event.logicalKey != LogicalKeyboardKey.select) {
      return;
    }

    setState(() {
      _inputBuffer.add(event.logicalKey);
      _recentKeys.add(_inputBuffer.length - 1);
    });

    // Anti-peeking: hide arrow after 0.5s
    final index = _inputBuffer.length - 1;
    final timer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _recentKeys.remove(index);
        });
      }
    });
    _timers.add(timer);

    // Check if code is complete
    if (_inputBuffer.length == AppConstants.secretCodeLength) {
      widget.onCodeComplete(List.from(_inputBuffer));
    }
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Backdrop blur
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.8),
                ),
              ),
            ),
            // Center input dots
            Center(
              child: Container(
                height: 120.h,
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    AppConstants.secretCodeLength,
                    (index) => _buildDot(index),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = index < _inputBuffer.length;
    final isRecent = _recentKeys.contains(index);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: isActive ? 32.w : 24.w,
      height: isActive ? 32.h : 24.h,
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? const Color(0xFFBB86FC) : Colors.white24,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFFBB86FC).withValues(alpha: 0.6),
                  blurRadius: 12,
                  spreadRadius: 4,
                ),
              ]
            : [],
      ),
      child: Center(
        child: isRecent && isActive
            ? Icon(
                _getArrowIcon(_inputBuffer[index]),
                color: Colors.white,
                size: 16.sp,
              )
            : (isActive
                ? const Icon(Icons.circle, color: Colors.white, size: 8)
                : null),
      ),
    );
  }
}
