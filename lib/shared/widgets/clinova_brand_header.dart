import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/clinova_colors.dart';
import 'clinova_logo.dart';

/// Reusable branding header displaying the official Clinova logo and optional typography.
class ClinovaBrandHeader extends StatelessWidget {
  final double logoSize;
  final bool showTagline;
  final bool isCenter;
  final bool showAppName;

  const ClinovaBrandHeader({
    super.key,
    this.logoSize = 48.0,
    this.showTagline = true,
    this.isCenter = true,
    this.showAppName = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          isCenter ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              isCenter ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            ClinovaLogo(
              size: logoSize,
            ),
            if (showAppName) ...[
              const SizedBox(width: 12),
              Text(
                ClinovaConstants.appName,
                style: TextStyle(
                  fontSize: logoSize * 0.52,
                  fontWeight: FontWeight.w800,
                  color: ClinovaColors.primaryText,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 8),
          Text(
            ClinovaConstants.appTagline,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: ClinovaColors.secondaryText,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}
