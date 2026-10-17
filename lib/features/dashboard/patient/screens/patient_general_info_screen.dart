import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/clinova_colors.dart';
import '../models/patient_profile_model.dart';
import '../services/patient_profile_repository.dart';

/// Clinova General Information Screen
///
/// A dedicated, compact, strictly read-only view of the patient's saved profile data:
/// - Personal Information (Full name, photo/avatar, DOB, calculated age, gender, blood group)
/// - Contact Information (Mobile, email, address)
/// - Physical Information (Height, weight)
/// - Emergency Contact (Name, relationship, phone)
///
/// Strictly viewing only — no text fields, dropdowns, edit or save actions.
/// Back arrow in the AppBar navigates directly back to the Patient Dashboard.
class PatientGeneralInfoScreen extends StatelessWidget {
  const PatientGeneralInfoScreen({super.key});

  String _formatDate(DateTime? date) {
    if (date == null) return "Not provided";
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}";
  }

  String _displayValue(String? value, {String fallback = "Not provided"}) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value.trim();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    return StreamBuilder<PatientProfileModel>(
      stream: PatientProfileRepository.instance.profileStream,
      initialData: PatientProfileRepository.instance.profile,
      builder: (context, snapshot) {
        final profile = snapshot.data ?? PatientProfileRepository.instance.profile;
        final ageStr = profile.age != null ? "${profile.age} years" : "Not calculated";

        return Scaffold(
          backgroundColor: ClinovaColors.background,
          appBar: AppBar(
            backgroundColor: ClinovaColors.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E5D46)),
              tooltip: "Back to Dashboard",
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              "General Information",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF19372B),
                letterSpacing: -0.2,
              ),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 18,
                  vertical: isDesktop ? 24 : 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card with Avatar, Name, Email, and Age/Gender Summary
                      _buildHeaderCard(context, profile, isDesktop),
                      const SizedBox(height: 16),

                      // Personal Information Card
                      _buildInfoSectionCard(
                        title: "Personal Information",
                        icon: Icons.person_outline_rounded,
                        isDesktop: isDesktop,
                        fields: [
                          _InfoField(label: "Full Name", value: _displayValue(profile.fullName)),
                          _InfoField(label: "Date of Birth", value: _formatDate(profile.dateOfBirth)),
                          _InfoField(label: "Age", value: ageStr),
                          _InfoField(label: "Gender", value: _displayValue(profile.gender)),
                          _InfoField(label: "Blood Group", value: _displayValue(profile.bloodGroup)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Contact Information Card
                      _buildInfoSectionCard(
                        title: "Contact Information",
                        icon: Icons.contact_mail_outlined,
                        isDesktop: isDesktop,
                        fields: [
                          _InfoField(label: "Mobile Number", value: _displayValue(profile.mobileNumber)),
                          _InfoField(label: "Email Address", value: _displayValue(profile.email)),
                          _InfoField(label: "Home Address", value: _displayValue(profile.homeAddress), fullWidth: true),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Physical Information Card
                      _buildInfoSectionCard(
                        title: "Physical Information",
                        icon: Icons.monitor_weight_outlined,
                        isDesktop: isDesktop,
                        fields: [
                          _InfoField(
                            label: "Height",
                            value: profile.heightCm != null && profile.heightCm!.isNotEmpty
                                ? "${profile.heightCm} cm"
                                : "Not provided",
                          ),
                          _InfoField(
                            label: "Weight",
                            value: profile.weightKg != null && profile.weightKg!.isNotEmpty
                                ? "${profile.weightKg} kg"
                                : "Not provided",
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Emergency Contact Card
                      _buildInfoSectionCard(
                        title: "Emergency Contact",
                        icon: Icons.emergency_outlined,
                        isDesktop: isDesktop,
                        fields: [
                          _InfoField(
                            label: "Contact Person",
                            value: _displayValue(profile.emergencyContactName),
                          ),
                          _InfoField(
                            label: "Relationship",
                            value: _displayValue(profile.emergencyContactRelationship),
                          ),
                          _InfoField(
                            label: "Phone Number",
                            value: _displayValue(profile.emergencyContactPhone),
                            fullWidth: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Profile Summary Header Card ---
  Widget _buildHeaderCard(BuildContext context, PatientProfileModel profile, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCECE1), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            offset: Offset(0, 4),
            blurRadius: 14,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Botanical leaf decoration along bottom-right and side edge (matching Patient Profile)
            Positioned(
              right: -25,
              bottom: -20,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.075,
                  child: Image.asset(
                    ClinovaConstants.leavesAsset,
                    height: 135,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isDesktop ? 22 : 16),
              child: Row(
                children: [
                  // Profile Photo or fallback avatar
                  Container(
                    width: isDesktop ? 68 : 56,
                    height: isDesktop ? 68 : 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE8F2EC),
                      border: Border.all(color: const Color(0xFFC8DEC0), width: 1.8),
                    ),
                    child: ClipOval(
                      child: profile.photoBytes != null
                          ? Image.memory(
                              profile.photoBytes!,
                              fit: BoxFit.cover,
                            )
                          : const Icon(
                              Icons.person_rounded,
                              size: 34,
                              color: Color(0xFF28654F),
                            ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayValue(profile.fullName),
                          style: TextStyle(
                            fontSize: isDesktop ? 20 : 17,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF19372B),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _displayValue(profile.email),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF637D71),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF4EE),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFCEE4D6), width: 0.8),
                              ),
                              child: Text(
                                "Blood Group: ${_displayValue(profile.bloodGroup)}",
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E5D46),
                                ),
                              ),
                            ),
                            if (profile.age != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F7F4),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFD8E7DD), width: 0.8),
                                ),
                                child: Text(
                                  "${profile.age} yrs",
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF385749),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Section Card with Botanical Leaves Decoration ---
  Widget _buildInfoSectionCard({
    required String title,
    required IconData icon,
    required bool isDesktop,
    required List<_InfoField> fields,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCECE1), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            offset: Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Subtle translucent botanical leaf decoration along bottom-right edge (matching Patient Profile)
            Positioned(
              right: -25,
              bottom: -20,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.075,
                  child: Image.asset(
                    ClinovaConstants.leavesAsset,
                    height: 135,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 22 : 16,
                vertical: isDesktop ? 18 : 15,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Title Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9F4EE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 16, color: const Color(0xFF28654F)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF19372B),
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(height: 1.0, color: const Color(0xFFEEF5F0)),
                  const SizedBox(height: 14),

                  // Fields: 2-column on desktop, single column on mobile
                  if (isDesktop)
                    _buildTwoColumnLayout(fields)
                  else
                    _buildSingleColumnLayout(fields),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoColumnLayout(List<_InfoField> fields) {
    final rows = <Widget>[];
    int i = 0;

    while (i < fields.length) {
      final current = fields[i];
      if (current.fullWidth || i == fields.length - 1) {
        rows.add(_buildFieldTile(current.label, current.value));
        if (i < fields.length - 1) rows.add(const SizedBox(height: 12));
        i++;
      } else {
        final next = fields[i + 1];
        if (next.fullWidth) {
          rows.add(_buildFieldTile(current.label, current.value));
          rows.add(const SizedBox(height: 12));
          i++;
        } else {
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildFieldTile(current.label, current.value)),
                const SizedBox(width: 20),
                Expanded(child: _buildFieldTile(next.label, next.value)),
              ],
            ),
          );
          if (i + 2 < fields.length) rows.add(const SizedBox(height: 12));
          i += 2;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  Widget _buildSingleColumnLayout(List<_InfoField> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fields.map((f) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildFieldTile(f.label, f.value),
        );
      }).toList(),
    );
  }

  Widget _buildFieldTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF738E82),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 3.5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF19372B),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _InfoField {
  final String label;
  final String value;
  final bool fullWidth;

  const _InfoField({
    required this.label,
    required this.value,
    this.fullWidth = false,
  });
}
