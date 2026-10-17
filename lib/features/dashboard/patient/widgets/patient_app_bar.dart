import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/clinova_colors.dart';

/// Prominent, full-width app bar across the top of the Patient Dashboard.
///
/// Layout (Exact three elements):
/// - Left: A hamburger menu icon button that opens and closes the desktop navigation drawer
/// - Center: Standalone Clinova heart-and-ECG logo symbol (exact horizontal viewport center)
/// - Right: Notification bell icon button with a small unread-count badge
class PatientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuPressed;
  final VoidCallback onNotificationsPressed;
  final bool hasUnreadNotifications;
  final bool isDesktop;
  final Key? menuKey;
  final Key? notificationsKey;

  const PatientAppBar({
    super.key,
    required this.onMenuPressed,
    required this.onNotificationsPressed,
    this.hasUnreadNotifications = true,
    this.isDesktop = false,
    this.menuKey,
    this.notificationsKey,
  });

  @override
  Size get preferredSize => Size.fromHeight(isDesktop ? 80.0 : 66.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        color: ClinovaColors.background,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC0D5CA).withValues(alpha: 0.20),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center: Standalone Clinova heart-and-ECG logo symbol
            // Positioned at the exact horizontal center of the viewport
            Center(
              child: Image.asset(
                ClinovaConstants.symbolAsset,
                height: isDesktop ? 48.0 : 40.0,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                semanticLabel: 'Clinova Heart Symbol',
              ),
            ),

            // Left: Hamburger menu icon button that opens/closes drawer
            Positioned(
              left: isDesktop ? 32.0 : 16.0,
              child: Tooltip(
                message: 'Menu',
                child: InkWell(
                  key: menuKey ?? const Key('patient_menu_button'),
                  onTap: onMenuPressed,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ClinovaColors.surfaceNeumorphic,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ClinovaColors.borderLight,
                        width: 1.0,
                      ),
                      boxShadow: ClinovaColors.raisedShadow(blur: 5, offset: const Offset(2, 2)),
                    ),
                    child: const Icon(
                      Icons.menu,
                      color: ClinovaColors.primaryText,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),

            // Right: Notification bell icon button with small unread badge
            Positioned(
              right: isDesktop ? 32.0 : 16.0,
              child: Tooltip(
                message: 'Notifications',
                child: InkWell(
                  key: notificationsKey ?? const Key('patient_notifications_button'),
                  onTap: onNotificationsPressed,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ClinovaColors.surfaceNeumorphic,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ClinovaColors.borderLight,
                        width: 1.0,
                      ),
                      boxShadow: ClinovaColors.raisedShadow(blur: 5, offset: const Offset(2, 2)),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          color: ClinovaColors.primaryText,
                          size: 22,
                        ),
                        if (hasUnreadNotifications)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: ClinovaColors.primaryAccent,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                              alignment: Alignment.center,
                              child: const Text(
                                "2",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
