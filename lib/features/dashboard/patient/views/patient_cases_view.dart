import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/clinova_colors.dart';
import '../../../../shared/widgets/demo_banner.dart';
import '../../../../shared/widgets/neumorphic_button.dart';
import '../../../../shared/widgets/neumorphic_card.dart';
import '../../../../shared/widgets/neumorphic_icon_container.dart';
import '../services/demo_case_repository.dart';

/// My Cases full view displaying recorded patient case histories and intake records.
class PatientCasesView extends StatefulWidget {
  const PatientCasesView({super.key});

  @override
  State<PatientCasesView> createState() => _PatientCasesViewState();
}

class _PatientCasesViewState extends State<PatientCasesView> {
  String _selectedFilter = "All";
  StreamSubscription? _casesSub;

  @override
  void initState() {
    super.initState();
    _casesSub = DemoCaseRepository.instance.casesStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _casesSub?.cancel();
    super.dispose();
  }

  final List<Map<String, dynamic>> _allCases = [
    {
      "id": "CASE-101",
      "title": "Persistent Cough & Low Fever",
      "date": "Oct 8, 2026",
      "status": "Ready",
      "doctor": "Pending review",
      "category": "Respiratory",
      "notes": "4 days duration, evening dry cough. Vitals within normal limits.",
    },
    {
      "id": "CASE-102",
      "title": "Right Knee Strain after Exercise",
      "date": "Sep 25, 2026",
      "status": "Reviewed",
      "doctor": "Dr. Marcus Vance",
      "category": "Musculoskeletal",
      "notes": "Post-jogging discomfort. Doctor recommended ice compression.",
    },
    {
      "id": "CASE-103",
      "title": "Annual Wellness Intake",
      "date": "Sep 12, 2026",
      "status": "Archived",
      "doctor": "Dr. Elena Ramos",
      "category": "General Health",
      "notes": "Routine annual health assessment and baseline vitals.",
    },
  ];

  List<Map<String, dynamic>> get _combinedCases {
    final list = <Map<String, dynamic>>[];
    for (final c in DemoCaseRepository.instance.cases) {
      if (c.id != 'case-01' && c.id != 'case-02' && c.id != 'case-03') {
        list.add({
          "id": c.reference,
          "title": c.title,
          "date": c.date,
          "status": c.status.toLowerCase().contains('reviewed') ? 'Reviewed' : 'Ready',
          "doctor": c.doctor ?? "Pending review",
          "category": c.category ?? "General Health",
          "notes": c.notes ?? c.fullCase?.symptomDetails ?? "Intake recorded via questionnaire.",
          "case": c,
        });
      }
    }
    list.addAll(_allCases);
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final sourceCases = _combinedCases;
    final filtered = _selectedFilter == "All"
        ? sourceCases
        : sourceCases.where((c) => c["status"] == _selectedFilter).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DemoBanner(compact: true, margin: EdgeInsets.only(bottom: 16)),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "My Health Cases",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ClinovaColors.primaryText,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: NeumorphicButton(
                    text: "+ New Case",
                    height: 40,
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.patientCaseIntake);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ["All", "Ready", "Reviewed", "Archived"].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: ClinovaColors.primaryAccent.withValues(alpha: 0.15),
                      backgroundColor: ClinovaColors.surfaceNeumorphic,
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? ClinovaColors.primaryAccent : ClinovaColors.secondaryText,
                      ),
                      side: BorderSide(
                        color: isSelected ? ClinovaColors.primaryAccent : ClinovaColors.borderLight,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (val) {
                        if (val) setState(() => _selectedFilter = filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            if (filtered.isEmpty)
              NeumorphicCard(
                padding: const EdgeInsets.all(32),
                borderRadius: 18,
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.inbox_outlined, size: 40, color: ClinovaColors.secondaryText),
                      const SizedBox(height: 10),
                      Text("No cases found in '$_selectedFilter' status",
                          style: const TextStyle(fontWeight: FontWeight.w600, color: ClinovaColors.primaryText)),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final c = filtered[i];
                  return NeumorphicCard(
                    padding: const EdgeInsets.all(18),
                    borderRadius: 18,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.patientCaseDetail,
                        arguments: c,
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            NeumorphicIconContainer(
                              size: 42,
                              iconSize: 20,
                              borderRadius: 12,
                              icon: Icons.folder_outlined,
                              iconColor: ClinovaColors.primaryAccent,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c["title"] as String,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      color: ClinovaColors.primaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "${c['id']} • ${c['category']} • ${c['date']}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: ClinovaColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: ClinovaColors.primaryAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                c["status"] as String,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: ClinovaColors.primaryAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: ClinovaColors.borderLight),
                        const SizedBox(height: 10),
                        Text(
                          c["notes"] as String,
                          style: const TextStyle(fontSize: 12.5, color: ClinovaColors.secondaryText, height: 1.35),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
