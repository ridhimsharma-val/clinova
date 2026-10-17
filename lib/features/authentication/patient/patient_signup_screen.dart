import 'package:flutter/material.dart';
import '../../../core/auth/auth_config.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/clinova_colors.dart';
import '../../../features/dashboard/patient/services/patient_profile_repository.dart';
import '../../../shared/widgets/clinova_logo.dart';
import '../../../shared/widgets/demo_banner.dart';
import '../../../shared/widgets/neumorphic_button.dart';
import '../../../shared/widgets/neumorphic_icon_container.dart';
import '../../../shared/widgets/neumorphic_input.dart';

class PatientSignupScreen extends StatefulWidget {
  const PatientSignupScreen({super.key});

  @override
  State<PatientSignupScreen> createState() => _PatientSignupScreenState();
}

class _PatientSignupScreenState extends State<PatientSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreePrivacy = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_agreePrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ClinovaColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text("Please accept the privacy notice to proceed."),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthConfig.authService.registerPatient(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      await PatientProfileRepository.instance.loadForUser(result.session);
      if (!mounted) return;

      final bool isComplete = PatientProfileRepository.instance.isPatientProfileComplete;
      final targetRoute = isComplete ? AppRoutes.patientDashboard : AppRoutes.patientOnboarding;

      Navigator.of(context).pushReplacementNamed(targetRoute);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ClinovaColors.primaryAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isComplete
                      ? "Patient account created successfully! Welcome to Clinova."
                      : "Account created! Please complete your patient profile setup to continue.",
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ClinovaColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            result.errorMessage ?? "Registration failed.",
            style: const TextStyle(fontSize: 13),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClinovaColors.background,
      appBar: AppBar(
        toolbarHeight: 44,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 4.0, bottom: 4.0),
          child: NeumorphicIconContainer(
            size: 36,
            iconSize: 16,
            borderRadius: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
              color: ClinovaColors.primaryText,
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isDesktop = constraints.maxWidth >= 720;
            final double horizontalPadding = isDesktop ? 32.0 : 20.0;
            final double verticalPadding = isDesktop ? 8.0 : 16.0;

            final fullNameField = NeumorphicInput(
              controller: _nameController,
              label: "Full name",
              hint: "Enter your full name",
              prefixIcon: Icons.badge_outlined,
              isDense: isDesktop,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter your full name";
                }
                if (value.trim().length < 2) {
                  return "Name is too short";
                }
                return null;
              },
            );

            final emailField = NeumorphicInput(
              controller: _emailController,
              label: "Email address",
              hint: "name@example.com",
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              isDense: isDesktop,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter your email address";
                }
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return "Please enter a valid email address";
                }
                return null;
              },
            );

            final passwordField = NeumorphicInput(
              controller: _passwordController,
              label: "Password",
              hint: "At least 6 characters",
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              isDense: isDesktop,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: ClinovaColors.secondaryText,
                  size: 19,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter a password";
                }
                if (value.length < 6) {
                  return "Password must be at least 6 characters";
                }
                return null;
              },
            );

            final confirmPasswordField = NeumorphicInput(
              controller: _confirmPasswordController,
              label: "Confirm password",
              hint: "Re-enter your password",
              prefixIcon: Icons.lock_reset_rounded,
              obscureText: _obscureConfirmPassword,
              isDense: isDesktop,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: ClinovaColors.secondaryText,
                  size: 19,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please confirm your password";
                }
                if (value != _passwordController.text) {
                  return "Passwords do not match";
                }
                return null;
              },
            );

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isDesktop ? 820 : 480),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Patient Role Tag & Logo
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: ClinovaColors.surfaceNeumorphic,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    width: 0.8,
                                  ),
                                  boxShadow: ClinovaColors.raisedShadow(
                                    blur: 6,
                                    offset: const Offset(2, 2.5),
                                    intensity: 0.6,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_add_alt_1_rounded,
                                      size: 14,
                                      color: ClinovaColors.primaryAccent,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "Patient registration",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: ClinovaColors.primaryAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              ClinovaLogo(size: isDesktop ? 56 : 64),
                            ],
                          ),

                          SizedBox(height: isDesktop ? 10 : 18),

                          Text(
                            "Create your patient account",
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontSize: isDesktop ? 22 : 24,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Organize your health concerns and prepare structured case summaries to share with your doctor.",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                          ),

                          SizedBox(height: isDesktop ? 8 : 12),

                          DemoBanner(
                            compact: true,
                            margin: EdgeInsets.only(bottom: isDesktop ? 6 : 10),
                          ),

                          SizedBox(height: isDesktop ? 6 : 10),

                          // Fields: Two-column grid on desktop, single-column on mobile
                          if (isDesktop) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: fullNameField),
                                const SizedBox(width: 16),
                                Expanded(child: emailField),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: passwordField),
                                const SizedBox(width: 16),
                                Expanded(child: confirmPasswordField),
                              ],
                            ),
                          ] else ...[
                            fullNameField,
                            const SizedBox(height: 14),
                            emailField,
                            const SizedBox(height: 14),
                            passwordField,
                            const SizedBox(height: 14),
                            confirmPasswordField,
                          ],

                          SizedBox(height: isDesktop ? 16 : 20),

                          // Privacy Notice Checkbox
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: _agreePrivacy,
                                  activeColor: ClinovaColors.primaryAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      _agreePrivacy = val ?? false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  "I agree to the privacy notice and understand that Clinova is designed to help organize health summaries.",
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: ClinovaColors.secondaryText,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: isDesktop ? 12 : 18),

                          // Submit Button
                          NeumorphicButton(
                            text: "Create your patient account",
                            height: isDesktop ? 46 : 52,
                            isLoading: _isLoading,
                            onPressed: _handleSignUp,
                          ),

                          SizedBox(height: isDesktop ? 10 : 16),

                          // Return to Sign In
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Already have an account? ",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: ClinovaColors.secondaryText,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: const Text(
                                  "Sign in",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: ClinovaColors.primaryAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
