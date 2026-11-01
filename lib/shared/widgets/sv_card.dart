import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class SvCard extends StatefulWidget {
  const SvCard({
    required this.child,
    super.key,
    this.onTap,
    this.leftBorderColor,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.showGlow = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? leftBorderColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final bool showGlow;

  @override
  State<SvCard> createState() => _SvCardState();
}

class _SvCardState extends State<SvCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic, reverseCurve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      HapticFeedback.lightImpact();
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBgColor = widget.backgroundColor ?? AppColors.surface;

    final Border cardBorder = widget.showGlow
        ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.0)
        : Border.all(color: AppColors.border, width: 0.5);

    // Premium iOS soft layered shadow
    final List<BoxShadow> cardShadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.02),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ];

    const borderRadius = BorderRadius.all(Radius.circular(24)); // Softer Apple style curve

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: borderRadius,
        border: cardBorder,
        boxShadow: cardShadows,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.leftBorderColor != null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        widget.leftBorderColor!,
                        widget.leftBorderColor!.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                  child: const SizedBox(width: 4),
                ),
              Expanded(
                child: Padding(padding: widget.padding, child: widget.child),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.onTap == null) return card;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: card,
      ),
    );
  }
}
