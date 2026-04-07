import 'package:flutter/material.dart';

import '../../shared/constants.dart';

class FocusableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSelect;
  final VoidCallback? onLongSelect;
  final VoidCallback? onMenu;
  final double? width;
  final double? height;

  const FocusableCard({
    super.key,
    required this.child,
    this.onSelect,
    this.onLongSelect,
    this.onMenu,
    this.width,
    this.height,
  });

  @override
  State<FocusableCard> createState() => _FocusableCardState();
}

class _FocusableCardState extends State<FocusableCard> {
  bool _isFocused = false;
  DateTime? _keyDownTime;

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        _keyDownTime ??= DateTime.now();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.contextMenu ||
          event.logicalKey == LogicalKeyboardKey.keyM) {
        widget.onMenu?.call();
        return KeyEventResult.handled;
      }
    }
    if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        if (_keyDownTime != null) {
          final duration = DateTime.now().difference(_keyDownTime!);
          _keyDownTime = null;
          if (duration >= AppConstants.settingsIconLongPressDuration) {
            widget.onLongSelect?.call();
          } else {
            widget.onSelect?.call();
          }
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _onFocusChange(bool focused) {
    if (_isFocused != focused) {
      setState(() {
        _isFocused = focused;
      });
      if (focused) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const Duration(milliseconds: 200),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isFocused ? 1.08 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _isFocused ? const Color(0xFF1E1E1E) : const Color(0xFF141414),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : [],
          border: Border.all(
            color: _isFocused ? const Color(0xFFFF6B35) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Focus(
          onKeyEvent: _onKeyEvent,
          onFocusChange: _onFocusChange,
          child: widget.child,
        ),
      ),
    );
  }
}
