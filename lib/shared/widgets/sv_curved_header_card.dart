import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SvCurvedHeaderCard extends StatelessWidget {
  const SvCurvedHeaderCard({
    required this.child,
    required this.labelText,
    super.key,
    this.height,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  final Widget child;
  final String labelText;
  final double? height;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final cardContent = Padding(
      padding: padding,
      child: child,
    );

    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.only(top: 16), // space for the tab header popping out
      child: CustomPaint(
        painter: _CurvedCardPainter(
          labelText: labelText,
          borderColor: AppColors.primary,
          isDark: isDark,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            splashColor: AppColors.primary.withValues(alpha: 0.05),
            highlightColor: AppColors.primary.withValues(alpha: 0.02),
            child: Padding(
              padding: const EdgeInsets.only(top: 24), // push child below the tab curve
              child: cardContent,
            ),
          ),
        ),
      ),
    );
  }
}

class _CurvedCardPainter extends CustomPainter {
  _CurvedCardPainter({
    required this.labelText,
    required this.borderColor,
    required this.isDark,
  });

  final String labelText;
  final Color borderColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    const double th = 20; // tab height
    const double tw = 120; // tab width
    const double radius = 24; // card corner radius
    const double rTab = 10; // tab corner radius

    final w = size.width;
    final h = size.height;

    final cardPath = _buildCardPath(w, h, th, tw, radius, rTab);

    // Draw card drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawPath(cardPath, shadowPaint);

    // Draw card fill
    final fillPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;
    canvas.drawPath(cardPath, fillPaint);

    // Draw outer border (light gray)
    final borderPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(cardPath, borderPaint);

    // Draw label text in the tab
    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText.toUpperCase(),
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final textX = (w - textPainter.width) / 2;
    // Align text nicely inside the tab header
    final textY = (th - textPainter.height) / 2 - 1;
    textPainter.paint(canvas, Offset(textX, textY));
  }

  Path _buildCardPath(double w, double h, double th, double tw, double radius, double rTab) {
    final path = Path();

    // Starting point: left side at the top edge of the card body (below the tab)
    path.moveTo(0, th + radius);

    // Left edge
    path.lineTo(0, h - radius);
    path.quadraticBezierTo(0, h, radius, h);

    // Bottom edge
    path.lineTo(w - radius, h);
    path.quadraticBezierTo(w, h, w, h - radius);

    // Right edge
    path.lineTo(w, th + radius);
    path.quadraticBezierTo(w, th, w - radius, th);

    // Right top card edge before tab transition
    final tabStart = (w - tw) / 2;
    final tabEnd = (w + tw) / 2;

    path.lineTo(tabEnd + rTab, th);

    // Transition up to tab right side
    path.quadraticBezierTo(tabEnd, th, tabEnd, th - rTab);
    path.lineTo(tabEnd, rTab);
    path.quadraticBezierTo(tabEnd, 0, tabEnd - rTab, 0);

    // Top edge of tab
    path.lineTo(tabStart + rTab, 0);
    path.quadraticBezierTo(tabStart, 0, tabStart, rTab);

    // Transition down to left card edge
    path.lineTo(tabStart, th - rTab);
    path.quadraticBezierTo(tabStart, th, tabStart - rTab, th);

    // Left top card edge
    path.lineTo(radius, th);
    path.quadraticBezierTo(0, th, 0, th + radius);

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _CurvedCardPainter oldDelegate) =>
      oldDelegate.labelText != labelText ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.isDark != isDark;
}
