import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../shared/constants.dart';
import '../../core/providers/stealth_provider.dart';

class StealthDialog extends ConsumerStatefulWidget {
  const StealthDialog({super.key});

  @override
  ConsumerState<StealthDialog> createState() => _StealthDialogState();
}

class _StealthDialogState extends ConsumerState<StealthDialog> {
  final List<LogicalKeyboardKey> _inputBuffer = [];
  int _wrongAttempts = 0;

  void _onKey(KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      _inputBuffer.add(event.logicalKey);

      if (_inputBuffer.length > AppConstants.secretCodeLength) {
        _inputBuffer.removeAt(0);
      }

      if (_inputBuffer.length == AppConstants.secretCodeLength) {
        _checkCode();
      }
    }
  }

  void _checkCode() {
    final code = _inputBuffer
        .map((k) => AppConstants.defaultSecretCode.indexOf(k))
        .toList();

    ref.read(stealthProvider.notifier).verifyCode(code);

    if (ref.read(stealthProvider) == StealthMode.unlocked) {
      if (mounted) Navigator.of(context).pop();
    } else {
      setState(() {
        _wrongAttempts++;
        _inputBuffer.clear();
      });

      if (_wrongAttempts >= 3) {
        if (mounted) Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _onKey,
      child: AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          '输入解锁暗号',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                AppConstants.secretCodeLength,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _inputBuffer.length
                        ? const Color(0xFFFF6B35)
                        : const Color(0xFF333333),
                  ),
                ),
              ),
            ),
            if (_wrongAttempts > 0) ...[
              SizedBox(height: 16.h),
              Text(
                '错误 $_wrongAttempts/3',
                style: TextStyle(color: Colors.redAccent, fontSize: 14.sp),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
