import 'package:flutter/material.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/clinova_colors.dart';
import '../services/demo_case_repository.dart';

/// Screen displayed immediately following simulated case submission.
class CaseSubmittedConfirmationScreen extends StatelessWidget {
  final PatientCaseSummary summary;

  const CaseSubmittedConfirmationScreen({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: ClinovaColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 20,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Container(
                padding: EdgeInsets.all(isDesktop ? 36 : 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFDCECE2),
                    width: 1.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.white,
                      offset: Offset(-3, -3),
                      blurRadius: 8,
                    ),
                    BoxShadow(
                      color: Color(0xFFBED4C6),
                      offset: Offset(4, 6),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success Check Badge
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE2F3EA),
                        border: Border.all(
                          color: const Color(0xFFBCE0CE),
                          width: 2.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.white,
                            offset: Offset(-2, -2),
                            blurRadius: 4,
                          ),
                          BoxShadow(
                            color: Color(0xFFBED4C6),
                            offset: Offset(2, 4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_rounded,
                          size: 42,
                          color: Color(0xFF1E5D46),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    const Text(
                      "Case Submitted",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF18382B),
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Demo banner pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEFE3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBCE0CE), width: 0.8),
                      ),
                      child: const Text(
                        "DEMO SIMULATION",
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E5D46),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Subtitle
                    const Text(
                      "Your case details have been securely recorded and queued for clinical review.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5A756B),
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Reference card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F8F4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD4E7DC)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Case Reference",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF6A8679),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                summary.reference,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1B4E3B),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 18, color: Color(0xFFDDECE2)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Initial Status",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF6A8679),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: summary.statusBgColor,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: summary.statusBorderColor, width: 0.8),
                                ),
                                child: Text(
                                  summary.status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: summary.statusTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Submission Date",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF6A8679),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                summary.date,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF233A32),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Safety note
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FBF9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2EFE7)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF32866C)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Notice: Clinova collects patient-reported history for clinician review. This is not an automated medical diagnosis. In case of emergency or severe pain, please call local emergency services immediately.",
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF537365),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _showSummaryDialog(context);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1E5D46),
                              side: const BorderSide(color: Color(0xFFBCE0CE), width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text(
                              "View case summary",
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                AppRoutes.patientDashboard,
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF28654F),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text(
                              "Back to dashboard",
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSummaryDialog(BuildContext context) {
    final intake = summary.fullCase;
    if (intake == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF7FAF7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4E5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Submitted Case Summary",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A382C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Reference: ${summary.reference}",
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF5F7C6E)),
              ),
              const Divider(height: 24, color: Color(0xFFDCEBE2)),
              _summaryItem("Chief Concern", intake.chiefConcern),
              _summaryItem("Onset & Duration", "${intake.onsetChoice ?? 'Not provided'}${intake.onsetDetails?.isNotEmpty == true ? ' (${intake.onsetDetails})' : ''}"),
              _summaryItem("Symptoms & Severity", "${intake.symptomsDescription}${intake.severity != null ? ' [Severity: ${intake.severity}]' : ''}"),
              _summaryItem("Pattern & Frequency", "${intake.patternChoice ?? 'Not provided'}${intake.patternDetails?.isNotEmpty == true ? ' (${intake.patternDetails})' : ''}"),
              _summaryItem("Aggravating Factors", intake.aggravatingFactors ?? "Not provided"),
              _summaryItem("Relieving Factors", intake.relievingFactors ?? "Not provided"),
              _summaryItem("Associated Symptoms", intake.associatedSymptoms.isEmpty ? "None reported" : intake.associatedSymptoms.join(", ")),
              _summaryItem("Medical Conditions", "${intake.hasConditions ?? 'Not provided'}${intake.conditionsDetails?.isNotEmpty == true ? ' - ${intake.conditionsDetails}' : ''}"),
              _summaryItem("Medications", intake.medications.isEmpty ? (intake.takesMedications ?? "Not provided") : intake.medications.map((m) => "${m.name} (${m.dose ?? 'dose unknown'}, ${m.frequency ?? 'freq unknown'})").join("; ")),
              _summaryItem("Allergies", "${intake.hasAllergies ?? 'Not provided'}${intake.allergiesDetails?.isNotEmpty == true ? ' - ${intake.allergiesDetails}' : ''}"),
              _summaryItem("Medical History", intake.medicalHistoryDetails ?? "Not provided"),
              _summaryItem("Additional Concerns", intake.additionalConcerns ?? "Not provided"),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF436B58),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.isEmpty ? "Not provided" : value,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF1A382C),
            ),
          ),
        ],
      ),
    );
  }
}
