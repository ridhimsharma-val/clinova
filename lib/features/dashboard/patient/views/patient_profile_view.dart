import 'package:flutter/material.dart';
import '../../../../core/auth/auth_config.dart';
import '../../../../core/auth/auth_models.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/clinova_colors.dart';
import '../models/patient_profile_model.dart';
import '../services/patient_profile_repository.dart';
import '../../../../shared/widgets/demo_banner.dart';
import '../../../../shared/widgets/neumorphic_button.dart';
import '../../../../shared/widgets/neumorphic_card.dart';
import '../../../../shared/widgets/neumorphic_icon_container.dart';

class PatientProfileView extends StatelessWidget {
  final UserSession session;
  final VoidCallback onLogout;

  const PatientProfileView({
    super.key,
    required this.session,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DemoBanner(compact: true, margin: EdgeInsets.only(bottom: 16)),

            NeumorphicCard(
              padding: const EdgeInsets.all(22),
              borderRadius: 20,
              child: Column(
                children: [
                  StreamBuilder<PatientProfileModel>(
                    stream: PatientProfileRepository.instance.profileStream,
                    initialData: PatientProfileRepository.instance.profile,
                    builder: (context, snapshot) {
                      final isSaved = PatientProfileRepository.instance.hasSavedProfile;
                      final prof = snapshot.data ?? PatientProfileRepository.instance.profile;
                      final displayName = isSaved && prof.fullName.isNotEmpty ? prof.fullName : session.name;
                      final displayEmail = isSaved && prof.email.isNotEmpty ? prof.email : session.email;

                      return Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: ClinovaColors.accentLight.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: isSaved && prof.photoBytes != null
                                  ? Image.memory(
                                      prof.photoBytes!,
                                      fit: BoxFit.cover,
                                      width: 56,
                                      height: 56,
                                    )
                                  : const Icon(
                                      Icons.person_rounded,
                                      size: 30,
                                      color: ClinovaColors.primaryAccent,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: ClinovaColors.primaryText,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  displayEmail,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: ClinovaColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: ClinovaColors.primaryAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              (isSaved || !AuthConfig.useDemoAuth) ? "ACTIVE PATIENT" : "DEMO PATIENT",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: ClinovaColors.primaryAccent,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1, color: ClinovaColors.borderLight),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 16, color: ClinovaColors.secondaryAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AuthConfig.useDemoAuth
                              ? "Frontend Demo Session — your clinical privacy will be protected under end-to-end HIPAA-aligned security upon backend integration."
                              : "Authenticated Session — clinical records encrypted and protected under HIPAA-aligned security.",
                          style: const TextStyle(
                            fontSize: 12,
                            color: ClinovaColors.secondaryText,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            NeumorphicCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              borderRadius: 18,
              child: InkWell(
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.patientProfileDetails),
                borderRadius: BorderRadius.circular(14),
                child: const Row(
                  children: [
                    Icon(Icons.badge_rounded, color: ClinovaColors.primaryAccent, size: 26),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Patient Profile & Medical Details",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: ClinovaColors.primaryText,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "View and edit personal info, contacts, vitals, and medical history",
                            style: TextStyle(
                              fontSize: 12,
                              color: ClinovaColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: ClinovaColors.secondaryAccent),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Profile info cards
            NeumorphicCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Account & Preferences",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ClinovaColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: ClinovaColors.borderLight),
                  const SizedBox(height: 10),
                  _buildProfileRow(
                    icon: Icons.badge_outlined,
                    label: "Patient ID",
                    value: AuthConfig.useDemoAuth
                        ? "CLIN-PAT-DEMO-01"
                        : (session.id.length >= 8 ? session.id.substring(0, 8).toUpperCase() : "CLIN-PAT-01"),
                  ),
                  _buildProfileRow(
                    icon: Icons.notifications_none_outlined,
                    label: "Clinical Notifications",
                    value: "Enabled (Active)",
                  ),
                  _buildProfileRow(
                    icon: Icons.lock_outline_rounded,
                    label: "Authentication Security",
                    value: AuthConfig.useDemoAuth
                        ? "Simulated Demo Mode"
                        : "Supabase Cloud Database (Live)",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Center(
              child: SizedBox(
                width: 240,
                child: NeumorphicButton(
                  text: AuthConfig.useDemoAuth ? "Sign out of Demo" : "Sign Out",
                  height: 46,
                  onPressed: onLogout,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          NeumorphicIconContainer(
            size: 34,
            iconSize: 16,
            borderRadius: 10,
            icon: icon,
            iconColor: ClinovaColors.primaryAccent,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: ClinovaColors.secondaryText,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ClinovaColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}
