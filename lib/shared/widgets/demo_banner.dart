import 'package:flutter/material.dart';
import '../../core/auth/auth_config.dart';
import '../../core/theme/clinova_colors.dart';

/// Compact soft-neumorphic notice banner indicating simulated Demo Mode (Zero icons).
class DemoBanner extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  final bool compact;

  const DemoBanner({
    super.key,
    this.margin,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!AuthConfig.useDemoAuth) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: margin,
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: compact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: ClinovaColors.surfaceNeumorphic,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ClinovaColors.primaryAccent.withValues(alpha: 0.22),
          width: 0.8,
        ),
        boxShadow: ClinovaColors.raisedShadow(
          blur: 6,
          offset: const Offset(2, 2.5),
          intensity: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ClinovaColors.primaryAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              "DEMO",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: ClinovaColors.primaryAccent,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Demo Mode — authentication is simulated. Real account security will be enabled with backend integration.",
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: ClinovaColors.primaryAccent,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
