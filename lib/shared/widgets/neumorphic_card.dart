import 'package:flutter/material.dart';
import '../../core/theme/clinova_colors.dart';

/// Soft-Neumorphic Card Component
/// Features diffuse upper-left white highlight and subtle lower-right sage shadow.
class NeumorphicCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? backgroundColor;
  final Border? customBorder;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.borderRadius = 24.0,
    this.onTap,
    this.isSelected = false,
    this.backgroundColor,
    this.customBorder,
  });

  @override
  State<NeumorphicCard> createState() => _NeumorphicCardState();
}

class _NeumorphicCardState extends State<NeumorphicCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = widget.backgroundColor ?? ClinovaColors.surfaceNeumorphic;

    final border = widget.customBorder ??
        Border.all(
          color: widget.isSelected
              ? ClinovaColors.primaryAccent.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.85),
          width: widget.isSelected ? 1.5 : 0.8,
        );

    final shadows = _isPressed
        ? ClinovaColors.pressedShadow
        : (widget.isSelected || _isHovered)
            ? ClinovaColors.elevatedRaisedShadow()
            : ClinovaColors.raisedShadow(
                blur: 16,
                offset: const Offset(5, 6),
                intensity: 0.9,
              );

    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: border,
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (highlighted) {
            if (widget.onTap != null) {
              setState(() => _isPressed = highlighted);
            }
          },
          onHover: (hovered) {
            if (widget.onTap != null) {
              setState(() => _isHovered = hovered);
            }
          },
          borderRadius: BorderRadius.circular(widget.borderRadius),
          splashColor: ClinovaColors.primaryBackground.withValues(alpha: 0.5),
          highlightColor: ClinovaColors.primaryBackground.withValues(alpha: 0.2),
          child: Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
