import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_radius.dart';

/// Primary call-to-action button following the Sintera design system.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
    )..value = 1.0;
    _scale = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _controller.reverse();
  void _onTapUp(_) => _controller.forward();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = _buildContent(theme);

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: widget.onPressed == null ? null : _onTapDown,
        onTapUp: widget.onPressed == null ? null : _onTapUp,
        onTapCancel: () => _controller.forward(),
        onTap: widget.onPressed,
        child: Container(
          width: widget.isFullWidth ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 14.h,
          ),
          decoration: BoxDecoration(
            color: widget.onPressed == null
                ? theme.disabledColor
                : theme.colorScheme.primary,
            borderRadius: AppRadius.button,
            boxShadow: widget.onPressed == null
                ? null
                : [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (widget.isLoading) {
      return SizedBox(
        height: 20.h,
        width: 20.w,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Colors.white,
        ),
      );
    }

    final text = Text(
      widget.label,
      style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
    );

    if (widget.icon == null) return text;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.icon!,
        SizedBox(width: 8.w),
        text,
      ],
    );
  }
}
