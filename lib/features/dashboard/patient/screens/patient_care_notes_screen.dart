import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/clinova_colors.dart';
import '../../../../core/routing/app_routes.dart';
import '../models/patient_care_note_model.dart';
import '../services/patient_care_notes_repository.dart';

/// Clinova Patient Care Notes Screen
///
/// A dedicated, elegant clinical view of the patient's care notes and observations:
/// - Displays saved clinical care notes, timestamps, authors, and categories.
/// - When no notes exist, presents a calm empty state: "No care notes yet."
/// - Strictly avoids fabricating fictitious doctor notes, diagnoses, or treatment plans.
/// - Top-left back button navigates back to the Patient Dashboard.
class PatientCareNotesScreen extends StatefulWidget {
  const PatientCareNotesScreen({super.key});

  @override
  State<PatientCareNotesScreen> createState() => _PatientCareNotesScreenState();
}

class _PatientCareNotesScreenState extends State<PatientCareNotesScreen> {
  @override
  void initState() {
    super.initState();
    PatientCareNotesRepository.instance.fetchNotesFromSupabase();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    return StreamBuilder<List<PatientCareNote>>(
      stream: PatientCareNotesRepository.instance.notesStream,
      initialData: PatientCareNotesRepository.instance.notes,
      builder: (context, snapshot) {
        final notes = snapshot.data ?? PatientCareNotesRepository.instance.notes;

        return Scaffold(
          backgroundColor: ClinovaColors.background,
          appBar: AppBar(
            backgroundColor: ClinovaColors.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E5D46)),
              tooltip: "Back to Dashboard",
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacementNamed(AppRoutes.patientDashboard);
                }
              },
            ),
            title: const Text(
              "Patient Care Notes",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF19372B),
                letterSpacing: -0.2,
              ),
            ),
          ),
          body: SafeArea(
            child: RefreshIndicator(
              color: const Color(0xFF28654F),
              onRefresh: () => PatientCareNotesRepository.instance.fetchNotesFromSupabase(),
              child: Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : 18,
                    vertical: isDesktop ? 24 : 16,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Summary Card
                        _buildHeaderCard(context, notes.length, isDesktop),
                        const SizedBox(height: 20),

                        // Notes List or Empty State
                        if (notes.isEmpty)
                          _buildEmptyStateCard(isDesktop)
                        else
                          _buildNotesList(notes, isDesktop),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Header Summary Card with Botanical Decoration ---
  Widget _buildHeaderCard(BuildContext context, int noteCount, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCECE1), width: 1.0),
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
            // Botanical leaf watermark in top right corner
            Positioned(
              right: -25,
              top: -20,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.12,
                  child: Image.asset(
                    ClinovaConstants.leavesAsset,
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isDesktop ? 24 : 20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
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
                    child: const Icon(
                      Icons.notes_rounded,
                      color: Color(0xFF1E5D46),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Care Notes & Observations",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF19372B),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          "Important observations and follow-ups",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF5A756B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEEE2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFC4E2CF),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            noteCount == 0
                                ? "No active notes"
                                : "$noteCount ${noteCount == 1 ? 'saved note' : 'saved notes'}",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );
  }

  // --- Empty State Card ---
  Widget _buildEmptyStateCard(bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCECE1), width: 1.0),
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
            // Botanical leaf watermark in bottom right corner
            Positioned(
              right: -25,
              bottom: -20,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.10,
                  child: Image.asset(
                    ClinovaConstants.leavesAsset,
                    height: 130,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 36 : 24,
                vertical: isDesktop ? 48 : 36,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F2EC),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD0E3D7), width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.white,
                          offset: Offset(-2, -2),
                          blurRadius: 4,
                        ),
                        BoxShadow(
                          color: Color(0xFFBED4C6),
                          offset: Offset(2, 3),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: Color(0xFF28654F),
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "No care notes yet.",
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF19372B),
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: const Text(
                      "Clinical observations, follow-up instructions, and treatment notes recorded for your care will appear here.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5A756B),
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
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

  // --- Populated Notes List ---
  Widget _buildNotesList(List<PatientCareNote> notes, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < notes.length; i++) ...[
          _buildNoteCard(notes[i], isDesktop),
          if (i < notes.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }

  // --- Single Care Note Card ---
  Widget _buildNoteCard(PatientCareNote note, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCECE1), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-2, -2),
            blurRadius: 5,
          ),
          BoxShadow(
            color: Color(0xFFC5DACD),
            offset: Offset(3, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Subtle botanical leaf watermark behind card
            Positioned(
              right: -15,
              bottom: -15,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.08,
                  child: Image.asset(
                    ClinovaConstants.leavesAsset,
                    height: 110,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isDesktop ? 20 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta Row: Author, Category, Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (note.category != null && note.category!.trim().isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2EFE7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFCCE0D4), width: 0.8),
                              ),
                              child: Text(
                                note.category!.trim(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E5D46),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (note.author != null && note.author!.trim().isNotEmpty)
                            Text(
                              note.author!.trim(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF19372B),
                              ),
                            ),
                        ],
                      ),
                      if (note.formattedDate.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: Color(0xFF6B8B7B),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              note.formattedDate,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B8B7B),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Note Text / Structured Sections
                  _buildNoteBody(note.text),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteBody(String text) {
    if (!text.contains("Prescription / Medications:")) {
      return Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF233A32),
          height: 1.5,
        ),
      );
    }

    final lines = text.split('\n');
    final prescriptionLines = <String>[];
    final otherLines = <String>[];
    bool inPrescription = false;

    for (final line in lines) {
      if (line.trim().startsWith("Prescription / Medications:")) {
        inPrescription = true;
        continue;
      } else if (inPrescription &&
          (line.trim().startsWith("Clinical Assessment:") ||
           line.trim().startsWith("Doctor's Observations:") ||
           line.trim().startsWith("Advice & Recommendations:") ||
           line.trim().startsWith("Follow-up Instructions:") ||
           line.trim().startsWith("Recommended Follow-up:"))) {
        inPrescription = false;
        otherLines.add(line);
      } else if (inPrescription) {
        prescriptionLines.add(line);
      } else {
        otherLines.add(line);
      }
    }

    final prescriptionStr = prescriptionLines.join('\n').trim();
    final otherStr = otherLines.join('\n').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (prescriptionStr.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFB7DFCA), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF28654F).withValues(alpha: 0.06),
                  offset: const Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF28654F),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        "Rx",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Prescription & Medications",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF19372B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  prescriptionStr,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E5D46),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          if (otherStr.isNotEmpty) const SizedBox(height: 12),
        ],
        if (otherStr.isNotEmpty)
          Text(
            otherStr,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF233A32),
              height: 1.5,
            ),
          ),
      ],
    );
  }
}
