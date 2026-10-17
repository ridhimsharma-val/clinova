import 'package:flutter/material.dart';
import '../../../../core/theme/clinova_colors.dart';
import '../../../../shared/widgets/demo_banner.dart';
import '../../../../shared/widgets/neumorphic_card.dart';
import '../../../../shared/widgets/neumorphic_icon_container.dart';

class PatientMedicalHistoryView extends StatelessWidget {
  const PatientMedicalHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
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
                  icon: Icons.history_edu_outlined,
                  iconColor: ClinovaColors.primaryAccent,
                  isInset: true,
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Medical History",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: ClinovaColors.primaryText,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Clinical background, conditions, medications, and allergies",
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

            _buildSection(
              title: "Current Medications",
              icon: Icons.medication_outlined,
              items: [
                {"name": "Vitamin D3", "details": "1000 IU Daily • Dietary Supplement"},
                {"name": "Cetirizine", "details": "10 mg As needed • Seasonal allergies"},
              ],
            ),
            const SizedBox(height: 16),

            _buildSection(
              title: "Known Allergies",
              icon: Icons.warning_amber_rounded,
              items: [
                {"name": "Penicillin", "details": "Moderate reaction (rash/hives) • Documented 2021"},
                {"name": "Tree Pollen", "details": "Mild seasonal allergic rhinitis"},
              ],
            ),
            const SizedBox(height: 16),

            _buildSection(
              title: "Past Medical Conditions",
              icon: Icons.healing_outlined,
              items: [
                {"name": "Mild Asthma", "details": "Childhood onset • Well controlled"},
                {"name": "Right Knee Sprain", "details": "Sports related (2024) • Fully recovered"},
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Map<String, String>> items,
  }) {
    return NeumorphicCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeumorphicIconContainer(
                size: 38,
                iconSize: 18,
                borderRadius: 12,
                icon: icon,
                iconColor: ClinovaColors.primaryAccent,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: ClinovaColors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: ClinovaColors.borderLight),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (ctx, i) => const Divider(height: 12, color: ClinovaColors.borderLight),
            itemBuilder: (ctx, i) {
              final it = items[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it["name"]!,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: ClinovaColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            it["details"]!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: ClinovaColors.secondaryText,
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
        ],
      ),
    );
  }
}
