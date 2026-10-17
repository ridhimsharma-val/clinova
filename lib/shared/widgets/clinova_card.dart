import 'package:flutter/material.dart';
import 'neumorphic_card.dart';

/// Adapter widget ensuring ClinovaCard delegates to soft-neumorphic card
class ClinovaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool isSelected;
  final Border? border;

  const ClinovaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.isSelected = false,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicCard(
      padding: padding,
      onTap: onTap,
      isSelected: isSelected,
      customBorder: border,
      child: child,
    );
  }
}
