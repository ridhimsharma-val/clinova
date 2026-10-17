import 'package:flutter/material.dart';
import '../../../../core/theme/clinova_colors.dart';
import '../../../../shared/widgets/clinova_logo.dart';
import '../models/doctor_nav_destination.dart';
import '../models/doctor_profile_model.dart';
import '../services/doctor_profile_repository.dart';

/// Navigation Drawer for the Doctor Dashboard.
///
/// Features (Matches PatientSideDrawer design system):
/// - Exact 300px width with surfaceNeumorphic background and right border.
/// - Top branding row with Clinova horizontal logo and text-based Close button.
/// - Doctor credentials & initials identity display.
/// - Text-only navigation destinations: Doctor Dashboard, Case Queue, Doctor Profile, Notifications.
/// - Soft-neumorphic active state with "Active" pill indicator.
/// - Bottom separated text-only Sign Out action.
class DoctorSideDrawer extends StatelessWidget {
  final DoctorNavDestination currentDestination;
  final ValueChanged<DoctorNavDestination> onSelectDestination;
  final VoidCallback onLogout;
  final VoidCallback? onClose;
  final String doctorName;
  final String doctorSpecialty;
  final String doctorLicense;

  const DoctorSideDrawer({
    super.key,
    required this.currentDestination,
    required this.onSelectDestination,
    required this.onLogout,
    this.onClose,
    this.doctorName = "Dr. Marcus Vance",
    this.doctorSpecialty = "General Internal Medicine",
    this.doctorLicense = "CLIN-8821-MD",
  });

  String _getInitials(String name) {
    final clean = name.replaceAll('Dr.', '').trim();
    final parts = clean.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return "DR";
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return "${parts.first[0]}${parts.last[0]}".toUpperCase();
  }

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
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 12),
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

            // Doctor identity header
            StreamBuilder<DoctorProfileModel>(
              stream: DoctorProfileRepository.instance.profileStream,
              initialData: DoctorProfileRepository.instance.profile,
              builder: (context, snapshot) {
                final prof = snapshot.data;
                final currentName = (prof != null && prof.fullName.trim().isNotEmpty) ? prof.fullName : doctorName;
                final photo = prof?.photoBytes;
                final inits = _getInitials(currentName);

                return Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: ClinovaColors.accentLight.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ClinovaColors.primaryAccent.withValues(alpha: 0.25),
                            width: 1.0,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.center,
                        child: photo != null
                            ? Image.memory(
                                photo,
                                width: 42,
                                height: 42,
                                fit: BoxFit.cover,
                              )
                            : Text(
                                inits,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: ClinovaColors.primaryAccent,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: ClinovaColors.primaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "Physician Portal",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: ClinovaColors.primaryAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const Divider(height: 1, color: ClinovaColors.borderLight),
            const SizedBox(height: 12),

            // Text-only Navigation destinations
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  _buildNavItem(
                    destination: DoctorNavDestination.dashboard,
                    label: "Doctor Dashboard",
                  ),
                  _buildNavItem(
                    destination: DoctorNavDestination.caseQueue,
                    label: "Case Queue",
                  ),
                  _buildNavItem(
                    destination: DoctorNavDestination.profile,
                    label: "Doctor Profile",
                  ),
                  _buildNavItem(
                    destination: DoctorNavDestination.notifications,
                    label: "Notifications",
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
    required DoctorNavDestination destination,
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
