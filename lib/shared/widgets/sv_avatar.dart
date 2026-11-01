import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SvAvatar extends StatelessWidget {
  const SvAvatar({
    required this.name,
    super.key,
    this.imageUrl,
    this.radius = 22,
  });

  final String name;
  final String? imageUrl;
  final double radius;

  static const List<Color> _palette = [
    AppColors.primary,
    AppColors.sleep,
    AppColors.hrv,
    AppColors.spo2,
    AppColors.stress,
    AppColors.activity,
  ];

  Color _gradientColor() {
    final hash = name.isEmpty ? 0 : name.codeUnits.fold(0, (a, b) => a + b);
    return _palette[hash % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty
        ? 'S'
        : name.trim().characters.first.toUpperCase();
    final baseColor = _gradientColor();
    final size = radius * 2;

    if (imageUrl != null) {
      // Network image with red ring overlay via Stack
      return Container(
        width: size + 4,
        height: size + 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: ClipOval(
          child: Image.network(
            imageUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildGradientFallback(initial, baseColor, size);
            },
          ),
        ),
      );
    }

    // Gradient fallback avatar with red ring
    return Container(
      width: size + 4,
      height: size + 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: ClipOval(
        child: _buildGradientFallback(initial, baseColor, size),
      ),
    );
  }

  Widget _buildGradientFallback(
      String initial, Color baseColor, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            baseColor.withValues(alpha: 0.85),
            baseColor,
          ],
          center: Alignment.topLeft,
          radius: 1.4,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
