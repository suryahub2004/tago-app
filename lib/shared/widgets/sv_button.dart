import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

enum SvButtonVariant { primary, secondary, destructive }

class SvButton extends StatefulWidget {
  const SvButton({
    required this.label,
    this.onPressed,
    super.key,
    this.icon,
    this.isLoading = false,
    this.variant = SvButtonVariant.primary,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final SvButtonVariant variant;
  final bool fullWidth;

  @override
  State<SvButton> createState() => _SvButtonState();
}

class _SvButtonState extends State<SvButton> with SingleTickerProviderStateMixin {
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic, reverseCurve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      HapticFeedback.lightImpact();
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final hasCallback = widget.onPressed != null && !widget.isLoading;

    // ── Label / icon content ────────────────────────────────────────────────
    final Color foregroundColor = widget.variant == SvButtonVariant.secondary
        ? (hasCallback ? AppColors.primary : AppColors.textTertiary)
        : Colors.white;

    final content = widget.isLoading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foregroundColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                IconTheme(
                  data: IconThemeData(
                    color: foregroundColor,
                    size: 18,
                  ),
                  child: widget.icon!,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: -0.1,
                    color: hasCallback ? foregroundColor : foregroundColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          );

    // ── Gradient / decoration ────────────────────────────────────────────────
    Color? flatColor;
    Border? border;
    List<BoxShadow> shadows = [];

    switch (widget.variant) {
      case SvButtonVariant.primary:
        flatColor = hasCallback
            ? AppColors.primary
            : AppColors.primary.withValues(alpha: 0.3);
      case SvButtonVariant.secondary:
        flatColor = AppColors.surface;
        border = Border.all(
          color: hasCallback ? AppColors.border : AppColors.border.withValues(alpha: 0.5),
          width: 1.0,
        );
      case SvButtonVariant.destructive:
        flatColor = hasCallback
            ? AppColors.danger
            : AppColors.danger.withValues(alpha: 0.3);
    }

    final container = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14), // Apple style rounded rect
        color: flatColor,
        border: border,
        boxShadow: shadows,
      ),
      child: Center(child: content),
    );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: hasCallback ? widget.onPressed : null,
        child: SizedBox(
          width: widget.fullWidth ? double.infinity : null,
          child: container,
        ),
      ),
    );
  }
}
