import 'package:flutter/material.dart';
import '../../core/theme/clinova_colors.dart';

/// Soft-Neumorphic Button with interactive pressed animation
class NeumorphicButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;
  final double height;
  final double borderRadius;

  const NeumorphicButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
    this.height = 54.0,
    this.borderRadius = 16.0,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;

    Color backgroundColor;
    Color textColor;
    List<BoxShadow> shadows;

    if (widget.isSecondary) {
      backgroundColor = _isPressed
          ? ClinovaColors.inputRecessedFill
          : ClinovaColors.surfaceNeumorphic;
      textColor = ClinovaColors.primaryAccent;
      shadows = _isPressed
          ? ClinovaColors.pressedShadow
          : ClinovaColors.raisedShadow(blur: 12, offset: const Offset(4, 4));
    } else {
      backgroundColor = isEnabled
          ? (_isPressed
              ? const Color(0xFF205240)
              : ClinovaColors.primaryAccent)
          : ClinovaColors.primaryAccent.withValues(alpha: 0.6);
      textColor = Colors.white;
      shadows = _isPressed
          ? ClinovaColors.greenButtonPressedShadow
          : isEnabled
              ? ClinovaColors.greenButtonShadow
              : [];
    }

    return GestureDetector(
      onTap: isEnabled ? widget.onPressed : null,
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _isPressed = false);
            }
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          height: widget.height,
          transform: Matrix4.translationValues(
            0,
            _isPressed ? 1.5 : 0,
            0,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: shadows,
            border: widget.isSecondary
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 1.0,
                  )
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isSecondary ? ClinovaColors.primaryAccent : Colors.white,
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: textColor, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    ),
  );
}
}
