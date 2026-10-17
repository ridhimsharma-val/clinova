import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Centralized Clinova brand logo widget using the official artwork.
///
/// Standard sizing conventions:
/// - [ClinovaLogo.horizontal]: Official emblem image + "Clinova" text wordmark in a horizontal row.
/// - [ClinovaLogo.header]: 44–48 logical pixels for app bars and navigation headers.
/// - [ClinovaLogo.medium]: 64–72 logical pixels for forms and dialogs.
/// - [ClinovaLogo.welcome]: 104–116 logical pixels for welcome and empty-state screens.
/// - [ClinovaLogo.symbol]: Clean transparent emblem for compact navigation.
class ClinovaLogo extends StatelessWidget {
  final double size;
  final bool symbolOnly;
  final bool horizontal;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const ClinovaLogo({
    super.key,
    this.size = 48.0,
    this.symbolOnly = false,
    this.horizontal = false,
    this.onTap,
    this.semanticLabel = 'Clinova Logo',
  });

  /// Factory for horizontal app bar header with heart emblem and wordmark
  const ClinovaLogo.horizontal({
    super.key,
    this.size = 48.0,
    this.onTap,
    this.semanticLabel = 'Clinova Brand Logo',
  })  : symbolOnly = false,
        horizontal = true;

  /// Factory for standard compact header placement (44–50px)
  const ClinovaLogo.header({
    super.key,
    this.size = 46.0,
    this.symbolOnly = false,
    this.horizontal = false,
    this.onTap,
    this.semanticLabel = 'Clinova Logo',
  });

  /// Factory for medium card / form branding (68px)
  const ClinovaLogo.medium({
    super.key,
    this.size = 68.0,
    this.symbolOnly = false,
    this.horizontal = false,
    this.onTap,
    this.semanticLabel = 'Clinova Logo',
  });

  /// Factory for large welcome screen branding (112px)
  const ClinovaLogo.welcome({
    super.key,
    this.size = 112.0,
    this.symbolOnly = false,
    this.horizontal = false,
    this.onTap,
    this.semanticLabel = 'Clinova Brand Logo',
  });

  /// Factory for compact symbol-only icon (heart emblem)
  const ClinovaLogo.symbol({
    super.key,
    this.size = 40.0,
    this.onTap,
    this.semanticLabel = 'Clinova Heart Symbol',
  })  : symbolOnly = true,
        horizontal = false;

  @override
  Widget build(BuildContext context) {
    if (horizontal) {
      final logoWidget = ClipRect(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              ClinovaConstants.symbolAsset,
              height: size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              semanticLabel: semanticLabel,
              errorBuilder: (context, error, stackTrace) => SizedBox(
                width: size,
                height: size,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Clinova',
                style: TextStyle(
                  fontSize: (size * 0.52).clamp(18.0, 26.0),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E3A2F),
                  letterSpacing: -0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

      if (onTap != null) {
        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: logoWidget,
        );
      }
      return logoWidget;
    }

    final assetPath = symbolOnly
        ? ClinovaConstants.symbolAsset
        : ClinovaConstants.logoTransparentAsset;

    final imageWidget = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: semanticLabel,
      errorBuilder: (context, error, stackTrace) => SizedBox(
        width: size,
        height: size,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
