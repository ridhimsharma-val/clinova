import 'package:flutter/material.dart';

/// Navigation destinations available in the Doctor Dashboard shell.
enum DoctorNavDestination {
  dashboard(
    label: "Doctor Dashboard",
    shortLabel: "Dashboard",
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
  ),
  caseQueue(
    label: "Case Queue",
    shortLabel: "Queue",
    icon: Icons.inbox_outlined,
    selectedIcon: Icons.inbox_rounded,
  ),
  profile(
    label: "Doctor Profile",
    shortLabel: "Profile",
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
  ),
  notifications(
    label: "Notifications",
    shortLabel: "Notifs",
    icon: Icons.notifications_none_rounded,
    selectedIcon: Icons.notifications_rounded,
  );

  final String label;
  final String shortLabel;
  final IconData icon;
  final IconData selectedIcon;

  const DoctorNavDestination({
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.selectedIcon,
  });
}
