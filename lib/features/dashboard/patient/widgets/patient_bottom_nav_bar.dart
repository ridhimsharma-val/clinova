import 'package:flutter/material.dart';
import '../../../../core/theme/clinova_colors.dart';
import '../models/patient_nav_destination.dart';

/// Compact soft-neumorphic mobile bottom navigation bar with text-only labels:
/// Home, My Cases, AI Assistant, Profile (Zero icons).
class PatientBottomNavBar extends StatelessWidget {
  final PatientNavDestination currentDestination;
  final ValueChanged<PatientNavDestination> onSelectDestination;

  const PatientBottomNavBar({
    super.key,
    required this.currentDestination,
    required this.onSelectDestination,
  });

  static const List<PatientNavDestination> destinations = [
    PatientNavDestination.home,
    PatientNavDestination.myCases,
    PatientNavDestination.aiAssistant,
    PatientNavDestination.profile,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClinovaColors.surfaceNeumorphic,
        border: const Border(
          top: BorderSide(
            color: ClinovaColors.borderLight,
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC0D5CA).withValues(alpha: 0.3),
            offset: const Offset(0, -3),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: destinations.map((dest) {
                final isSelected = currentDestination == dest;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: InkWell(
                      onTap: () => onSelectDestination(dest),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ClinovaColors.primaryAccent.withValues(alpha: 0.14)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(
                                  color: ClinovaColors.primaryAccent.withValues(alpha: 0.35),
                                  width: 1.0,
                                )
                              : null,
                          boxShadow: isSelected
                              ? ClinovaColors.raisedShadow(blur: 4, offset: const Offset(1, 1), intensity: 0.25)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            dest.displayShortLabel,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? ClinovaColors.primaryAccent
                                  : ClinovaColors.secondaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
