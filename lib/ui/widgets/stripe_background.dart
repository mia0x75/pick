import 'package:flutter/material.dart';

/// High-density vertical stripe pattern background
/// Green / Purple / White stripes with digital energy feel
class StripeBackground extends StatelessWidget {
  final Color? overlayColor;
  final double opacity;

  const StripeBackground({
    super.key,
    this.overlayColor,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark background
        const Color(0xFF0D0D0D),
        // Stripe pattern
        CustomPaint(
          painter: _StripePainter(),
          child: Container(),
        ),
        // Overlay for dimming
        if (overlayColor != null)
          Container(color: overlayColor!.withOpacity(opacity)),
      ],
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stripeWidth = 4.0;
    final gapWidth = 2.0;
    final totalPattern = stripeWidth * 3 + gapWidth * 3;

    // Stripe colors: green, purple, white, gap
    final colors = [
      const Color(0xFF00E676).withOpacity(0.15), // Green
      const Color(0xFFBB86FC).withOpacity(0.12), // Purple
      const Color(0xFFFFFFFF).withOpacity(0.08), // White
      Colors.transparent,                         // Gap
    ];

    for (double x = 0; x < size.width; x += totalPattern) {
      for (int i = 0; i < colors.length; i++) {
        final paint = Paint()..color = colors[i];
        final rect = Rect.fromLTWH(
          x + i * (stripeWidth + gapWidth / 3),
          0,
          stripeWidth,
          size.height,
        );
        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
