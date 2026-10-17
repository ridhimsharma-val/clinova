import 'package:flutter/material.dart';
import 'neumorphic_button.dart';

/// Adapter widget ensuring ClinovaButton delegates to NeumorphicButton
class ClinovaButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;

  const ClinovaButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isSecondary: isOutlined,
      icon: icon,
    );
  }
}
