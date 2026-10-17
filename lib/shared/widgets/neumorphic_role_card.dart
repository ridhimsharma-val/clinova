import 'package:flutter/material.dart';
import '../../core/theme/clinova_colors.dart';

/// Soft-neumorphic Role Selection Card strictly matching the Clinova visual reference.
class NeumorphicRoleCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final bool isDoctor;
  final VoidCallback onTap;

  const NeumorphicRoleCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    this.isDoctor = false,
    required this.onTap,
  });

  @override
  State<NeumorphicRoleCard> createState() => _NeumorphicRoleCardState();
}

class _NeumorphicRoleCardState extends State<NeumorphicRoleCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isHighlighted = widget.isSelected || _isHovered;

    // Distinct styling per role matching the reference artwork:
    // Patient card uses primary forest green accents.
    // Doctor card uses light mint background with forest green accents.
    final Color iconBoxBg = widget.isDoctor
        ? (widget.isSelected
            ? ClinovaColors.secondaryBackground
            : ClinovaColors.primaryBackground)
        : ClinovaColors.primaryAccent;

    final Color iconColor = widget.isDoctor
        ? ClinovaColors.primaryAccent
        : Colors.white;

    final Color arrowBg = widget.isDoctor
        ? (widget.isSelected
            ? ClinovaColors.secondaryBackground
            : ClinovaColors.primaryBackground)
        : ClinovaColors.primaryAccent;

    final Color arrowColor = widget.isDoctor
        ? ClinovaColors.primaryAccent
        : Colors.white;

    // Neumorphic shadow paired system
    final List<BoxShadow> shadows = _isPressed
        ? ClinovaColors.pressedShadow
        : isHighlighted
            ? [
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-6, -6),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: const Color(0xFFB5CDC2).withValues(alpha: 0.75),
                  offset: const Offset(7, 9),
                  blurRadius: 22,
                  spreadRadius: 0,
                ),
              ]
            : ClinovaColors.raisedShadow(
                blur: 18,
                offset: const Offset(6, 7),
              );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: ClinovaColors.surfaceWhite,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: widget.isSelected
                  ? ClinovaColors.primaryAccent.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.9),
              width: widget.isSelected ? 1.5 : 1.0,
            ),
            boxShadow: shadows,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Left Icon Container (squircle with soft radius)
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: iconBoxBg,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isDoctor
                          ? const Color(0xFF233A32).withValues(alpha: 0.06)
                          : ClinovaColors.primaryAccent.withValues(alpha: 0.30),
                      offset: const Offset(2, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    widget.icon,
                    size: 26,
                    color: iconColor,
                  ),
                ),
              ),

              const SizedBox(width: 18),

              // Middle Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w700,
                        color: ClinovaColors.primaryText,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: ClinovaColors.secondaryText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Right Circular Arrow Action
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: arrowBg,
                  boxShadow: [
                    BoxShadow(
                      color: widget.isDoctor
                          ? const Color(0xFF233A32).withValues(alpha: 0.06)
                          : ClinovaColors.primaryAccent.withValues(alpha: 0.28),
                      offset: const Offset(2, 3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 24,
                    color: arrowColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
