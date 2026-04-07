import 'package:flutter/material.dart';

class GlowLoadingAnimation extends StatefulWidget {
  final double size;

  const GlowLoadingAnimation({super.key, this.size = 48.0});

  @override
  State<GlowLoadingAnimation> createState() => _GlowLoadingAnimationState();
}

class _GlowLoadingAnimationState extends State<GlowLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Container(
              width: widget.size * 1.8,
              height: widget.size * 1.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(_opacityAnimation.value * 0.5),
                    blurRadius: 24 * _scaleAnimation.value,
                    spreadRadius: 4 * _scaleAnimation.value,
                  ),
                ],
              ),
            ),
            // Middle glow ring
            Container(
              width: widget.size * 1.3,
              height: widget.size * 1.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(_opacityAnimation.value * 0.7),
                    blurRadius: 16 * _scaleAnimation.value,
                    spreadRadius: 2 * _scaleAnimation.value,
                  ),
                ],
              ),
            ),
            // Center dot
            Container(
              width: widget.size * _scaleAnimation.value,
              height: widget.size * _scaleAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF6B35),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.8),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
