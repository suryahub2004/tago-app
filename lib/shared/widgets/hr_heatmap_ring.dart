import 'package:flutter/material.dart';

/// A circular ring drawn around a child widget. Color reflects HR zone.
class HrHeatmapRing extends StatelessWidget {
  const HrHeatmapRing({
    super.key,
    required this.child,
    this.heartRate,           // null = unknown / offline
    this.size = 56.0,
    this.strokeWidth = 3.0,
  });

  final Widget child;
  final int? heartRate;
  final double size;
  final double strokeWidth;

  static Color ringColor(int? hr) {
    if (hr == null) return Colors.grey.shade700;
    if (hr <= 80) return const Color(0xFF4CAF50);
    if (hr <= 100) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + strokeWidth * 2,
      height: size + strokeWidth * 2,
      child: CustomPaint(
        painter: _RingPainter(
          color: ringColor(heartRate),
          strokeWidth: strokeWidth,
          animated: heartRate != null && heartRate! > 100,
        ),
        child: Padding(
          padding: EdgeInsets.all(strokeWidth + 2),
          child: ClipOval(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.color, required this.strokeWidth, required this.animated});
  final Color color;
  final double strokeWidth;
  final bool animated;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    if (animated) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    }
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.color != color;
}
