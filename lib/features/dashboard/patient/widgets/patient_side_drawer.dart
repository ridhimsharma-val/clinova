import 'package:flutter/material.dart';
import '../../../../core/theme/clinova_colors.dart';
import '../../../../shared/widgets/clinova_logo.dart';
import '../models/patient_nav_destination.dart';

/// Navigation Drawer for the Patient Dashboard.
///
/// Features (Zero generic icons):
/// - Text labels for all navigation items: Home, My Cases, AI Assistant, Medical History, My Reports, Profile, Logout.
/// - Text-based Close button.
/// - Soft-neumorphic selected states without decorative glyphs or icons.
class PatientSideDrawer extends StatelessWidget {
  final PatientNavDestination currentDestination;
  final ValueChanged<PatientNavDestination> onSelectDestination;
  final VoidCallback onLogout;
  final VoidCallback? onClose;

  const PatientSideDrawer({
    super.key,
    required this.currentDestination,
    required this.onSelectDestination,
    required this.onLogout,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300.0,
      decoration: const BoxDecoration(
        color: ClinovaColors.surfaceNeumorphic,
        border: Border(
          right: BorderSide(
            color: ClinovaColors.borderLight,
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top branding & text-based Close control
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: Row(
                children: [
                  const ClinovaLogo.horizontal(size: 34),
                  const Spacer(),
                  if (onClose != null)
                    InkWell(
                      onTap: onClose,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: ClinovaColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ClinovaColors.borderLight, width: 0.8),
                        ),
                        child: const Text(
                          "Close",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ClinovaColors.secondaryText,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const Divider(height: 1, color: ClinovaColors.borderLight),
            const SizedBox(height: 12),

            // Text-only Navigation destinations
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  _buildNavItem(
                    destination: PatientNavDestination.home,
                    label: "Home",
                  ),
                  _buildNavItem(
                    destination: PatientNavDestination.myCases,
                    label: "My Cases",
                  ),
                  _buildNavItem(
                    destination: PatientNavDestination.aiAssistant,
                    label: "AI Health Assistant",
                  ),
                  _buildNavItem(
                    destination: PatientNavDestination.medicalHistory,
                    label: "Medical History",
                  ),
                  _buildNavItem(
                    destination: PatientNavDestination.reports,
                    label: "My Reports",
                  ),
                  _buildNavItem(
                    destination: PatientNavDestination.profile,
                    label: "Profile",
                  ),
                ],
              ),
            ),

            // Bottom section: Text-only Logout separated from primary navigation
            const Divider(height: 1, color: ClinovaColors.borderLight),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              child: InkWell(
                onTap: onLogout,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: ClinovaColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ClinovaColors.borderLight, width: 0.8),
                  ),
                  child: const Text(
                    "Sign Out",
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: ClinovaColors.secondaryText,
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

  Widget _buildNavItem({
    required PatientNavDestination destination,
    required String label,
  }) {
    final isSelected = currentDestination == destination;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: InkWell(
        onTap: () => onSelectDestination(destination),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? ClinovaColors.primaryAccent.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: ClinovaColors.primaryAccent.withValues(alpha: 0.35),
                    width: 1.0,
                  )
                : null,
            boxShadow: isSelected
                ? ClinovaColors.raisedShadow(blur: 6, offset: const Offset(2, 2), intensity: 0.3)
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? ClinovaColors.primaryAccent
                        : ClinovaColors.primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: ClinovaColors.primaryAccent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "Active",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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
