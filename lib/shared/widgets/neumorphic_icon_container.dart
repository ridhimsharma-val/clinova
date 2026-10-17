import 'package:flutter/material.dart';
import '../../core/theme/clinova_colors.dart';

/// Soft-Neumorphic Icon Container
/// Can be raised (gently floating with highlight & shadow) or inset (recessed).
class NeumorphicIconContainer extends StatelessWidget {
  final Widget? child;
  final IconData? icon;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final Color? backgroundColor;
  final double borderRadius;
  final bool isInset;
  final bool isSelected;

  const NeumorphicIconContainer({
    super.key,
    this.child,
    this.icon,
    this.size = 54.0,
    this.iconSize = 26.0,
    this.iconColor,
    this.backgroundColor,
    this.borderRadius = 16.0,
    this.isInset = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ??
        (isSelected
            ? ClinovaColors.primaryAccent
            : isInset
                ? ClinovaColors.inputRecessedFill
                : ClinovaColors.surfaceNeumorphic);

    final effectiveIconColor = iconColor ??
        (isSelected
            ? Colors.white
            : ClinovaColors.primaryAccent);

    List<BoxShadow> shadows;
    if (isSelected) {
      shadows = [
        BoxShadow(
          color: ClinovaColors.primaryAccent.withValues(alpha: 0.35),
          offset: const Offset(3, 5),
          blurRadius: 12,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.6),
          offset: const Offset(-2, -2),
          blurRadius: 6,
        ),
      ];
    } else if (isInset) {
      // Recessed / inset effect
      shadows = ClinovaColors.recessedShadow;
    } else {
      // Soft raised
      shadows = ClinovaColors.raisedShadow(
        blur: 10,
        offset: const Offset(3.5, 4.0),
        intensity: 0.85,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows,
        border: isSelected
            ? null
            : (isInset
                ? Border.all(
                    color: ClinovaColors.secondaryBackground.withValues(alpha: 0.45),
                    width: 0.8,
                  )
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 0.8,
                  )),
      ),
      child: Center(
        child: child ??
            (icon != null
                ? Icon(
                    icon,
                    size: iconSize,
                    color: effectiveIconColor,
                  )
                : const SizedBox.shrink()),
      ),
    );
  }
}
