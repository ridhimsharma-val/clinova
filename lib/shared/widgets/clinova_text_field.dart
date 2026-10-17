import 'package:flutter/material.dart';
import 'neumorphic_input.dart';

/// Adapter widget ensuring ClinovaTextField delegates to NeumorphicInput
class ClinovaTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool readOnly;
  final String? helperText;

  const ClinovaTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicInput(
      controller: controller,
      label: label,
      hint: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      readOnly: readOnly,
      helperText: helperText,
    );
  }
}
