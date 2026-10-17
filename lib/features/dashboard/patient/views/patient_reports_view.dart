import 'package:flutter/material.dart';
import '../../../../core/theme/clinova_colors.dart';
import '../../../../shared/widgets/demo_banner.dart';
import '../../../../shared/widgets/neumorphic_card.dart';
import '../../../../shared/widgets/neumorphic_icon_container.dart';

class PatientReportsView extends StatelessWidget {
  const PatientReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = [
      {
        "title": "Clinical Summary — Respiratory Assessment",
        "date": "Oct 8, 2026",
        "type": "Case Intake Summary",
        "status": "Ready for Doctor",
        "summary": "Structured summary of 4-day cough symptoms, fever timeline, and patient vitals."
      },
      {
        "title": "Consultation Report — Dr. Marcus Vance",
        "date": "Sep 26, 2026",
        "type": "Physician Review",
        "status": "Finalized",
        "summary": "Differential review for knee strain; home rehabilitation exercises documented."
      },
      {
        "title": "Annual Health Baseline Summary",
        "date": "Sep 12, 2026",
        "type": "Preventive Overview",
        "status": "Archived",
        "summary": "Baseline wellness report, routine lifestyle checkup notes, and biometric summary."
      },
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DemoBanner(compact: true, margin: EdgeInsets.only(bottom: 16)),

            Row(
              children: [
                NeumorphicIconContainer(
                  size: 44,
                  iconSize: 22,
                  borderRadius: 14,
                  icon: Icons.description_outlined,
                  iconColor: ClinovaColors.primaryAccent,
                  isInset: true,
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "My Reports & Summaries",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: ClinovaColors.primaryText,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Exportable case summaries, triage notes, and doctor consultation documents",
                        style: TextStyle(
                          fontSize: 12.5,
                          color: ClinovaColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reports.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final r = reports[i];
                return NeumorphicCard(
                  padding: const EdgeInsets.all(18),
                  borderRadius: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          NeumorphicIconContainer(
                            size: 40,
                            iconSize: 20,
                            borderRadius: 12,
                            icon: Icons.article_outlined,
                            iconColor: ClinovaColors.primaryAccent,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r["title"]!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: ClinovaColors.primaryText,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  "${r['type']} • ${r['date']}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: ClinovaColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ClinovaColors.primaryAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              r["status"]!,
                              style: const TextStyle(
                                fontSize: 10.5,
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
                        r["summary"]!,
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
