import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/auth/auth_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/clinova_colors.dart';
import '../../../../shared/widgets/demo_banner.dart';
import '../models/patient_care_note_model.dart';
import '../models/patient_nav_destination.dart';
import '../models/patient_profile_model.dart';
import '../services/demo_case_repository.dart';
import '../services/patient_care_notes_repository.dart';
import '../services/patient_profile_repository.dart';

class PatientCaseItem {
  final String id;
  final String title;
  final String date;
  final String status;
  final Color statusTextColor;
  final Color statusBgColor;
  final Color statusBorderColor;

  const PatientCaseItem({
    required this.id,
    required this.title,
    required this.date,
    required this.status,
    required this.statusTextColor,
    required this.statusBgColor,
    required this.statusBorderColor,
  });
}

/// Clinova Patient Dashboard Home View:
/// - Top-row: Asymmetric 45%/55% two-column row with stretched cross-axis alignment
///   (Patient Profile matches exact combined height of General Information + Anamnesis)
/// - Hero: Ayurvedic herbal mortar artwork banner with blended gradient and interactive Flutter UI
/// - Lower-row: Recent Cases (2 items) & Quick History (4 tiles) aligned at top and bottom edges
/// - Subtle botanical leaf artwork (8–15% opacity) in lower panels
/// - Compact, comfortable sizing that fits on desktop viewports without unnecessary vertical scrolling
class PatientHomeView extends StatefulWidget {
  final ValueChanged<PatientNavDestination> onNavigate;

  const PatientHomeView({
    super.key,
    required this.onNavigate,
  });

  @override
  State<PatientHomeView> createState() => _PatientHomeViewState();
}

class _PatientHomeViewState extends State<PatientHomeView> {
  late List<PatientCaseSummary> _cases;

  @override
  void initState() {
    super.initState();
    _cases = List.from(DemoCaseRepository.instance.cases);
    DemoCaseRepository.instance.fetchCasesFromSupabase();
    PatientCareNotesRepository.instance.fetchNotesFromSupabase();
    DemoCaseRepository.instance.casesStream.listen((updatedCases) {
      if (mounted) {
        setState(() {
          _cases = List.from(updatedCases);
        });
      }
    });
  }

  void _copyPatientId() {
    Clipboard.setData(const ClipboardData(text: "CL-P-20481"));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ClinovaColors.primaryAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: const Text("Patient ID copied: CL-P-20481"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Not added";
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PatientProfileModel>(
      stream: PatientProfileRepository.instance.profileStream,
      initialData: PatientProfileRepository.instance.profile,
      builder: (context, profileSnapshot) {
        final prof = profileSnapshot.data ?? PatientProfileRepository.instance.profile;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 940;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1220),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Compact Demo Mode Status Banner
                    const DemoBanner(compact: true, margin: EdgeInsets.only(bottom: 12)),

                    // 2. Top-Row: Two-Column Summary with Stretched Height Alignment
                    _buildTopSummarySection(isDesktop, prof),

                    SizedBox(height: isDesktop ? 14 : 16),

                    // 3. Central Hero: Start a New Case with Ayurvedic Herbal Artwork
                    _buildStartCaseHero(isDesktop),

                    SizedBox(height: isDesktop ? 14 : 16),

                    // 4. Lower Two-Column Section: Recent Cases & Patient Care Notes with Aligned Heights
                    _buildLowerSection(isDesktop),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // 1. TOP SUMMARY SECTION (Stretched Alignment)
  // ==========================================
  Widget _buildTopSummarySection(bool isDesktop, PatientProfileModel prof) {
    if (isDesktop) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left (~45%): Patient Profile card stretches to match right column
            Expanded(
              flex: 45,
              child: _buildPatientProfileCard(isDesktop: true, prof: prof),
            ),
            const SizedBox(width: 16),
            // Right (~55%): Stacked General Information & Anamnesis cards
            Expanded(
              flex: 55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildGeneralInformationCard(isDesktop: true, prof: prof),
                  const SizedBox(height: 12),
                  _buildAnamnesisCard(isDesktop: true, prof: prof),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Column(
        children: [
          _buildPatientProfileCard(isDesktop: false, prof: prof),
          const SizedBox(height: 14),
          _buildGeneralInformationCard(isDesktop: false, prof: prof),
          const SizedBox(height: 12),
          _buildAnamnesisCard(isDesktop: false, prof: prof),
        ],
      );
    }
  }

  // --- Card A: Patient Profile (Stretched Height) ---
  Widget _buildPatientProfileCard({required bool isDesktop, required PatientProfileModel prof}) {
    final initials = prof.fullName.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();
    final displayInitials = initials.isNotEmpty ? initials : "AS";
    final ageText = prof.age != null ? "${prof.age} years" : "24 years";
    final genderText = prof.gender ?? "Female";
    final hasPhoto = prof.photoBytes != null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6FAF7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFD8E7DE),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-3, -3),
            blurRadius: 7,
          ),
          BoxShadow(
            color: Color(0xFFBED4C6),
            offset: Offset(4, 5),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.patientProfileDetails).then((_) => setState(() {})),
          borderRadius: BorderRadius.circular(22),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Soft botanical leaf watermark in bottom right corner (subtle 10% opacity)
                Positioned(
                  right: -20,
                  bottom: isDesktop ? 10 : 10,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.10,
                      child: Image.asset(
                        ClinovaConstants.leavesAsset,
                        height: 140,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // Card Content with balanced vertical spacing
                Padding(
                  padding: EdgeInsets.all(isDesktop ? 18 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Patient Profile",
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF19372B),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildPillAction(
                            label: "Details",
                            onTap: () => Navigator.of(context).pushNamed(AppRoutes.patientProfileDetails).then((_) => setState(() {})),
                          ),
                        ],
                      ),
                      SizedBox(height: isDesktop ? 14 : 18),

                      // Avatar Disc + Name + Demographics on Left, Portrait Illustration on Right
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left group: Avatar disc + Patient details (dynamic from repository)
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: isDesktop ? 58 : 64,
                                  height: isDesktop ? 58 : 64,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD6EDE0),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFB5DCBF), width: 1.5),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.white,
                                        offset: Offset(-2, -2),
                                        blurRadius: 4,
                                      ),
                                      BoxShadow(
                                        color: Color(0xFFB7CEBF),
                                        offset: Offset(2, 3),
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: hasPhoto
                                        ? Image.memory(
                                            prof.photoBytes!,
                                            fit: BoxFit.cover,
                                            width: isDesktop ? 58 : 64,
                                            height: isDesktop ? 58 : 64,
                                          )
                                        : (prof.fullName.trim().isNotEmpty
                                            ? Text(
                                                displayInitials,
                                                style: TextStyle(
                                                  fontSize: isDesktop ? 21 : 24,
                                                  fontWeight: FontWeight.w800,
                                                  color: const Color(0xFF1E5D46),
                                                  letterSpacing: -0.5,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.person_outline_rounded,
                                                size: 32,
                                                color: Color(0xFF1E5D46),
                                              )),
                                  ),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prof.fullName.trim().isNotEmpty ? prof.fullName : "Active patient",
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF163428),
                                          letterSpacing: -0.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        "$ageText   |   $genderText",
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFF4C6E5E),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDBEEE2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: const Color(0xFFC4E2CF),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: const Text(
                                          "Active patient",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1E5E45),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Right group: Friendly patient portrait illustration in soft-neumorphic frame
                          Container(
                            width: isDesktop ? 96 : 88,
                            height: isDesktop ? 96 : 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEAF4EE),
                              border: Border.all(
                                color: const Color(0xFFD4E7DC),
                                width: 2.0,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.white,
                                  offset: Offset(-2.5, -2.5),
                                  blurRadius: 5,
                                ),
                                BoxShadow(
                                  color: Color(0xFFBED4C6),
                                  offset: Offset(3, 4),
                                  blurRadius: 7,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                ClinovaConstants.patientIllustrationAsset,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Balances vertical space so Patient ID aligns with right-column bottom
                      if (isDesktop) const Spacer() else const SizedBox(height: 16),

                      // Inset Recessed Patient ID Cavity
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F2EC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFD3E4DA),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF233A32).withValues(alpha: 0.05),
                              offset: const Offset(1.5, 2),
                              blurRadius: 4,
                            ),
                            const BoxShadow(
                              color: Colors.white,
                              offset: Offset(-1.5, -1.5),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Text(
                              "Patient ID",
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF5D7F6E),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (AuthConfig.useDemoAuth) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4EADC),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Text(
                                  "DEMO",
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E5D46),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                "CL-P-20481",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF173629),
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            InkWell(
                              onTap: _copyPatientId,
                              borderRadius: BorderRadius.circular(7),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(color: const Color(0xFFD2E3D8), width: 0.8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFC0D5CA).withValues(alpha: 0.40),
                                      offset: const Offset(1, 1.5),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  "Copy",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E5D46),
                                  ),
                                ),
                              ),
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
        ),
      ),
    );
  }

  // --- Card B: General Information (Right Column Top) ---
  Widget _buildGeneralInformationCard({required bool isDesktop, required PatientProfileModel prof}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FCF9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFDFEDE4),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-3, -3),
            blurRadius: 7,
          ),
          BoxShadow(
            color: Color(0xFFBED4C6),
            offset: Offset(4, 5),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.patientGeneralInfo),
          borderRadius: BorderRadius.circular(22),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Soft botanical leaf watermark in right edge (subtle 9% opacity)
                Positioned(
                  right: -25,
                  bottom: -20,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.09,
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
                    horizontal: isDesktop ? 18 : 20,
                    vertical: isDesktop ? 13 : 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "General Information",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF19372B),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildPillAction(
                            label: "Details",
                            onTap: () => Navigator.of(context).pushNamed(AppRoutes.patientGeneralInfo),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildKeyValueRow("Date of birth", _formatDate(prof.dateOfBirth)),
                      const SizedBox(height: 6),
                      _buildKeyValueRow(
                        "Blood group",
                        prof.bloodGroup != null && prof.bloodGroup!.isNotEmpty
                            ? prof.bloodGroup!
                            : "Not added",
                      ),
                      const SizedBox(height: 6),
                      _buildKeyValueRow(
                        "Primary contact",
                        prof.mobileNumber.isNotEmpty
                            ? prof.mobileNumber
                            : (prof.email.isNotEmpty ? prof.email : "Not added"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Card C: Anamnesis (Right Column Bottom) ---
  Widget _buildAnamnesisCard({required bool isDesktop, required PatientProfileModel prof}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6FAF7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFDFEDE4),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-3, -3),
            blurRadius: 7,
          ),
          BoxShadow(
            color: Color(0xFFBED4C6),
            offset: Offset(4, 5),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.patientAnamnesis),
          borderRadius: BorderRadius.circular(22),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Soft botanical leaf watermark in right edge (subtle 9% opacity)
                Positioned(
                  right: -25,
                  bottom: -20,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.09,
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
                    horizontal: isDesktop ? 18 : 20,
                    vertical: isDesktop ? 13 : 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Anamnesis",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF19372B),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildPillAction(
                            label: "Details",
                            onTap: () => Navigator.of(context).pushNamed(AppRoutes.patientAnamnesis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildKeyValueRow(
                        "Known allergies",
                        prof.allergies != null && prof.allergies!.isNotEmpty
                            ? prof.allergies!
                            : "None recorded",
                      ),
                      const SizedBox(height: 6),
                      _buildKeyValueRow(
                        "Medical conditions",
                        prof.conditions != null && prof.conditions!.isNotEmpty
                            ? prof.conditions!
                            : "None recorded",
                      ),
                      const SizedBox(height: 6),
                      _buildKeyValueRow(
                        "Current medications",
                        prof.medications != null && prof.medications!.isNotEmpty
                            ? prof.medications!
                            : "None added",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyValueRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF5D7B6E),
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF173629),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 2. CENTRAL HERO: START A NEW CASE (Ayurvedic Art)
  // ==========================================
  Widget _buildStartCaseHero(bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-3, -3),
            blurRadius: 7,
          ),
          BoxShadow(
            color: Color(0xFFBED4C6),
            offset: Offset(4, 6),
            blurRadius: 14,
          ),
          BoxShadow(
            color: Color(0xFF1E3A2F),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Background Image: Ayurvedic herbal scene placed on the right
            Positioned.fill(
              child: Container(
                color: const Color(0xFF1F4838),
                child: Image.asset(
                  ClinovaConstants.ayurvedicHeroAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF1F4838),
                  ),
                ),
              ),
            ),
            // Smooth forest-green gradient on the left blending into the artwork
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1A4132).withValues(alpha: 0.95),
                      const Color(0xFF1D4636).withValues(alpha: 0.82),
                      const Color(0xFF1D4636).withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.34, 0.52, 0.72],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            // Real Flutter UI on the left
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 30 : 20,
                vertical: isDesktop ? 22 : 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Start a New Case",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.patientCaseIntake);
                    },
                    borderRadius: BorderRadius.circular(26),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7F2), // Pale mint button
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            offset: const Offset(0, 3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            "Start case",
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1B4E3B), // Forest green text
                            ),
                          ),
                          SizedBox(width: 5),
                          Text(
                            ">",
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1B4E3B),
                            ),
                          ),
                        ],
                      ),
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

  // ==========================================
  // 3. LOWER SECTION (Recent Cases + Patient Care Notes)
  // ==========================================
  Widget _buildLowerSection(bool isDesktop) {
    if (isDesktop) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left (~50%): Recent Cases with subtle botanical decoration
            Expanded(
              child: _buildRecentCasesCard(isDesktop: true),
            ),
            const SizedBox(width: 16),
            // Right (~50%): Patient Care Notes with aligned height
            Expanded(
              child: _buildPatientCareNotesCard(isDesktop: true),
            ),
          ],
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRecentCasesCard(isDesktop: false),
          const SizedBox(height: 16),
          _buildPatientCareNotesCard(isDesktop: false),
        ],
      );
    }
  }

  // --- Recent Cases Section (Left Column with Subtle Botanical Artwork) ---
  Widget _buildRecentCasesCard({required bool isDesktop}) {
    final previewCases = _cases.take(2).toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFDCECE1),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-3, -3),
            blurRadius: 7,
          ),
          BoxShadow(
            color: Color(0xFFBED4C6),
            offset: Offset(4, 5),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Subtle translucent leaf cluster in lower corner (opacity 11%, 8–15% range)
            Positioned(
              right: -15,
              bottom: -15,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.11,
                  child: Image.asset(
                    ClinovaConstants.leavesAsset,
                    height: 125,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Foreground Content
            Padding(
              padding: EdgeInsets.all(isDesktop ? 18 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Row
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Recent Cases",
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF19372B),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildPillAction(
                        label: "View all",
                        onTap: () => widget.onNavigate(PatientNavDestination.myCases),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Exactly two retained cases (or empty state if none)
                  if (previewCases.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFDFECE3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE7F0E9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.folder_open_rounded,
                                  size: 15,
                                  color: Color(0xFF28654F),
                                ),
                              ),
                              const SizedBox(width: 9),
                              const Text(
                                "No recent cases yet.",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF233A32),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "When you start and submit a health intake, your cases will be organized here.",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF678576),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...previewCases.map((caseItem) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: const Color(0xFFDFECE3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFC5DACD).withValues(alpha: 0.35),
                                  offset: const Offset(2, 3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                    AppRoutes.patientCaseDetail,
                                    arguments: caseItem,
                                  );
                                },
                                borderRadius: BorderRadius.circular(13),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              caseItem.title,
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF19372B),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 3,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: [
                                                Text(
                                                  caseItem.date,
                                                  style: const TextStyle(
                                                    fontSize: 11.5,
                                                    color: Color(0xFF6B8B7B),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 1.5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: caseItem.statusBgColor,
                                                    borderRadius: BorderRadius.circular(5),
                                                    border: Border.all(
                                                      color: caseItem.statusBorderColor,
                                                      width: 0.8,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    caseItem.status,
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: caseItem.statusTextColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      _buildPillAction(
                                        label: "View",
                                        onTap: () {
                                          Navigator.of(context).pushNamed(
                                            AppRoutes.patientCaseDetail,
                                            arguments: caseItem,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Patient Care Notes Section (Right Column with Botanical Artwork) ---
  Widget _buildPatientCareNotesCard({required bool isDesktop}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFDCECE1),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-3, -3),
            blurRadius: 7,
          ),
          BoxShadow(
            color: Color(0xFFBED4C6),
            offset: Offset(4, 5),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.patientCareNotes).then((_) => setState(() {})),
          borderRadius: BorderRadius.circular(22),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
          children: [
            // Subtle translucent leaf cluster in outer top-right (opacity 10%, matching Clinova style)
            Positioned(
              right: -20,
              top: -15,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.10,
                  child: Image.asset(
                    ClinovaConstants.leavesAsset,
                    height: 125,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isDesktop ? 18 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Row: Title & Subtitle
                  const Text(
                    "Patient Care Notes",
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF19372B),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "Important observations and follow-ups",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B8B7B),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Care Notes stream builder / content
                  StreamBuilder<List<PatientCareNote>>(
                    stream: PatientCareNotesRepository.instance.notesStream,
                    initialData: PatientCareNotesRepository.instance.notes,
                    builder: (context, snapshot) {
                      final notes = snapshot.data ?? PatientCareNotesRepository.instance.notes;

                      if (notes.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFDFECE3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE7F0E9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.notes_rounded,
                                      size: 15,
                                      color: Color(0xFF28654F),
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  const Expanded(
                                    child: Text(
                                      "Your care notes will appear here.",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF233A32),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Clinical observations, care instructions, and follow-up guidance documented for your care will be shown here.",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF678576),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Display up to 2 latest notes
                      final displayedNotes = notes.take(2).toList();
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: displayedNotes.map((note) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: const Color(0xFFDFECE3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFC5DACD).withValues(alpha: 0.35),
                                    offset: const Offset(2, 3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (note.author != null || note.formattedDate.isNotEmpty) ...[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (note.author != null && note.author!.isNotEmpty)
                                          Text(
                                            note.author!,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1E5D46),
                                            ),
                                          )
                                        else
                                          const SizedBox.shrink(),
                                        if (note.formattedDate.isNotEmpty)
                                          Text(
                                            note.formattedDate,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF6B8B7B),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                  ],
                                  Text(
                                    note.text,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF233A32),
                                      height: 1.4,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  // --- Reusable Pill Action Button ("Details >", "View all >", "View >") ---
  Widget _buildPillAction({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD4E5DB), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC0D5CA).withValues(alpha: 0.35),
              offset: const Offset(1, 1),
              blurRadius: 3,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E5D46),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              ">",
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E5D46),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
