import 'package:flutter/material.dart';

/// Navigation destinations available in the Patient Dashboard shell.
enum PatientNavDestination {
  home(
    label: "Home",
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  myCases(
    label: "My Cases",
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder_rounded,
  ),
  aiAssistant(
    label: "AI Health Assistant",
    shortLabel: "AI Assistant",
    icon: Icons.smart_toy_outlined,
    selectedIcon: Icons.smart_toy_rounded,
  ),
  medicalHistory(
    label: "Medical History",
    shortLabel: "History",
    icon: Icons.history_edu_outlined,
    selectedIcon: Icons.history_edu_rounded,
  ),
  reports(
    label: "My Reports",
    shortLabel: "Reports",
    icon: Icons.description_outlined,
    selectedIcon: Icons.description_rounded,
  ),
  profile(
    label: "Profile",
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
  );

  final String label;
  final String? shortLabel;
  final IconData icon;
  final IconData selectedIcon;

  const PatientNavDestination({
    required this.label,
    this.shortLabel,
    required this.icon,
    required this.selectedIcon,
  });

  String get displayShortLabel => shortLabel ?? label;
}
