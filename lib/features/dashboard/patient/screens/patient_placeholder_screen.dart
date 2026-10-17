import 'package:flutter/material.dart';
import '../../../../core/theme/clinova_colors.dart';
import '../../../../shared/widgets/clinova_logo.dart';
import '../../../../shared/widgets/neumorphic_card.dart';

/// Clean soft-neumorphic placeholder screen for Patient Profile, General Information,
/// Anamnesis, and Case Details (Zero generic icons).
class PatientPlaceholderScreen extends StatelessWidget {
  final String title;
  final String message;
  final String categoryTag;

  const PatientPlaceholderScreen({
    super.key,
    required this.title,
    this.message = "Details will be available here",
    this.categoryTag = "Patient Portal Module",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClinovaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              color: ClinovaColors.background,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ClinovaColors.surfaceNeumorphic,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: ClinovaColors.borderLight, width: 0.8),
                        boxShadow: ClinovaColors.raisedShadow(blur: 4, offset: const Offset(1, 1)),
                      ),
                      child: const Text(
                        "Back",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: ClinovaColors.primaryText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const ClinovaLogo.header(size: 42),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ClinovaColors.primaryText,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: ClinovaColors.borderLight),

            // Content Area (Zero generic icons)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 580),
                    child: NeumorphicCard(
                      padding: const EdgeInsets.all(36),
                      borderRadius: 24,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: ClinovaColors.primaryAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              categoryTag,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ClinovaColors.primaryAccent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: ClinovaColors.primaryText,
                              letterSpacing: -0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            message,
                            style: const TextStyle(
                              fontSize: 15,
                              color: ClinovaColors.secondaryText,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ClinovaColors.primaryAccent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              "Back to Dashboard",
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
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
}
