import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/clinova_colors.dart';
import '../../shared/widgets/clinova_logo.dart';
import '../../shared/widgets/neumorphic_role_card.dart';

/// Clinova Welcome / Role-Selection Screen strictly matching the visual reference.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? _selectedRole; // 'patient' or 'doctor'

  void _onRoleSelected(String role) {
    setState(() {
      _selectedRole = role;
    });

    // Responsive feedback delay before navigation
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      if (role == 'patient') {
        Navigator.of(context).pushNamed(AppRoutes.patientLogin);
      } else {
        Navigator.of(context).pushNamed(AppRoutes.doctorLogin);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 600;

    return Scaffold(
      backgroundColor: ClinovaColors.background,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Soft ambient background lighting in the corners
            Positioned(
              top: -screenSize.width * 0.25,
              right: -screenSize.width * 0.20,
              child: Container(
                width: screenSize.width * 0.75,
                height: screenSize.width * 0.75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      ClinovaColors.secondaryBackground.withValues(alpha: 0.35),
                      ClinovaColors.background.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -screenSize.width * 0.30,
              left: -screenSize.width * 0.25,
              child: Container(
                width: screenSize.width * 0.8,
                height: screenSize.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      ClinovaColors.primaryBackground.withValues(alpha: 0.45),
                      ClinovaColors.background.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Main Centered Content
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32.0 : 20.0,
                  vertical: 24.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    // Constrain max width to 660px on tablet/desktop for compact elegance
                    constraints: const BoxConstraints(maxWidth: 660),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Official Clinova Brand Icon (prominently centered)
                        const ClinovaLogo.welcome(
                          size: 108.0,
                        ),

                        const SizedBox(height: 22),

                        // Headline
                        Text(
                          ClinovaConstants.welcomeHeadline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isDesktop ? 28 : 23,
                            fontWeight: FontWeight.w800,
                            color: ClinovaColors.primaryText,
                            letterSpacing: -0.5,
                            height: 1.25,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Supporting Description
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Text(
                            ClinovaConstants.welcomeSubheadline,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                              color: ClinovaColors.secondaryText,
                              height: 1.45,
                            ),
                          ),
                        ),

                        const SizedBox(height: 34),

                        // Role Card 1: Patient
                        NeumorphicRoleCard(
                          title: "I’m a Patient",
                          description: "Access personal cases, medical history, and care insights.",
                          icon: Icons.person_outline_rounded,
                          isSelected: _selectedRole == 'patient',
                          isDoctor: false,
                          onTap: () => _onRoleSelected('patient'),
                        ),

                        const SizedBox(height: 16),

                        // Role Card 2: Doctor
                        NeumorphicRoleCard(
                          title: "I’m a Doctor",
                          description: "Review structured cases, clinical notes, and manage consultations.",
                          icon: Icons.medical_services_outlined,
                          isSelected: _selectedRole == 'doctor',
                          isDoctor: true,
                          onTap: () => _onRoleSelected('doctor'),
                        ),

                        const SizedBox(height: 32),

                        // Privacy Reassurance soft-neumorphic pill badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            color: ClinovaColors.surfaceWhite.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.9),
                              width: 0.8,
                            ),
                            boxShadow: ClinovaColors.raisedShadow(
                              blur: 10,
                              offset: const Offset(3, 4),
                              intensity: 0.7,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock_outline_rounded,
                                size: 15,
                                color: ClinovaColors.secondaryAccent,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  ClinovaConstants.privacyReassurance,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: ClinovaColors.secondaryText,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
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
