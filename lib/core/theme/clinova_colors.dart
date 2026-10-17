import 'package:flutter/material.dart';

/// Clinova Design System Colors & Soft-Neumorphic Definitions
class ClinovaColors {
  ClinovaColors._();

  // ---------------------------------------------------------------------------
  // Strict Clinova Color Palette
  // ---------------------------------------------------------------------------
  static const Color background = Color(0xFFF6FAF6); // Off-white canvas
  static const Color primaryBackground = Color(0xFFE7F0E9); // Very light mint
  static const Color secondaryBackground = Color(0xFFDCEBE2); // Sage surface
  static const Color surfaceWhite = Color(0xFFFFFFFF); // Clean white
  static const Color surfaceNeumorphic = Color(0xFFF7FAF7); // Soft neumorphic surface
  static const Color inputRecessedFill = Color(0xFFEEF5F0); // Recessed cavity fill
  static const Color inputRecessedFillFocused = Color(0xFFE8F2EC); // Focused recessed cavity fill

  // Accents & Brand Primary
  static const Color primaryAccent = Color(0xFF28654F); // Forest green
  static const Color secondaryAccent = Color(0xFF32866C); // Teal
  static const Color accentLight = Color(0xFF459A7E);
  static const Color accentPale = Color(0xFFBCE1D0);

  // Typography & Content
  static const Color primaryText = Color(0xFF233A32); // Dark charcoal-green
  static const Color secondaryText = Color(0xFF5A756B); // Muted slate-green
  static const Color tertiaryText = Color(0xFF8DA39A); // Subtle hint
  static const Color borderLight = Color(0xFFD8E7DF); // Soft organic border tone

  // Status & Utility
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color info = Color(0xFF1976D2);
  static const Color infoLight = Color(0xFFE3F2FD);

  // ---------------------------------------------------------------------------
  // Soft-Neumorphic Shadow Systems
  // ---------------------------------------------------------------------------

  /// Standard Raised Soft-Neumorphic Shadows
  /// Upper-left diffuse pure white highlight paired with a gentle sage shadow.
  static List<BoxShadow> raisedShadow({
    double blur = 18.0,
    Offset offset = const Offset(6, 7),
    double intensity = 1.0,
  }) =>
      [
        // Upper-left soft highlight
        BoxShadow(
          color: Colors.white.withValues(alpha: (0.95 * intensity).clamp(0.0, 1.0)),
          offset: Offset(-offset.dx, -offset.dy),
          blurRadius: blur,
          spreadRadius: 0,
        ),
        // Lower-right organic sage shadow
        BoxShadow(
          color: const Color(0xFFC0D5CA).withValues(alpha: (0.65 * intensity).clamp(0.0, 1.0)),
          offset: offset,
          blurRadius: blur,
          spreadRadius: 0,
        ),
      ];

  /// Prominent / Elevated Raised Soft-Neumorphic Shadows
  /// Used for prominent cards, role selectors, and floating action cards.
  static List<BoxShadow> elevatedRaisedShadow({
    double blur = 22.0,
    Offset offset = const Offset(7, 9),
  }) =>
      [
        // Bright diffuse upper-left highlight
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.98),
          offset: Offset(-offset.dx, -offset.dy),
          blurRadius: blur * 0.9,
          spreadRadius: 1,
        ),
        // Gentle sage/charcoal depth shadow
        BoxShadow(
          color: const Color(0xFFB5CDC2).withValues(alpha: 0.68),
          offset: offset,
          blurRadius: blur,
          spreadRadius: 0,
        ),
      ];

  /// Recessed Inset Simulation for Inputs and Filters
  static List<BoxShadow> recessedShadow = [
    // Top-left inner sage shadow simulation
    BoxShadow(
      color: const Color(0xFF233A32).withValues(alpha: 0.055),
      offset: const Offset(2, 2.5),
      blurRadius: 5,
      spreadRadius: 0,
    ),
    // Bottom-right inner white reflection highlight
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.92),
      offset: const Offset(-2, -2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  /// Focused Recessed Inset Shadow with soft primary accent halo
  static List<BoxShadow> focusedRecessedShadow = [
    BoxShadow(
      color: primaryAccent.withValues(alpha: 0.08),
      offset: const Offset(2, 2.5),
      blurRadius: 6,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.95),
      offset: const Offset(-2, -2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  /// Pressed Inset Simulation for Active/Pressed Buttons
  static List<BoxShadow> pressedShadow = [
    BoxShadow(
      color: const Color(0xFF233A32).withValues(alpha: 0.08),
      offset: const Offset(2, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.8),
      offset: const Offset(-2, -2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  /// Primary Forest Green Button Soft Depth Glow
  static List<BoxShadow> greenButtonShadow = [
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.65),
      offset: const Offset(-2, -2.5),
      blurRadius: 6,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: primaryAccent.withValues(alpha: 0.38),
      offset: const Offset(0, 7),
      blurRadius: 18,
      spreadRadius: -1,
    ),
  ];

  /// Depressed / Pressed Green Button Shadow
  static List<BoxShadow> greenButtonPressedShadow = [
    BoxShadow(
      color: const Color(0xFF1B4434).withValues(alpha: 0.35),
      offset: const Offset(1, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  // Preserved backwards compatibility mappings
  static List<BoxShadow> get softShadow => raisedShadow(blur: 16, offset: const Offset(5, 6));
  static List<BoxShadow> get cardShadow => elevatedRaisedShadow();
  static List<BoxShadow> get buttonShadow => greenButtonShadow;
}
