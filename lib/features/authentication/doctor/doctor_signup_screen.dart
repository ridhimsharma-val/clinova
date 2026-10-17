import 'package:flutter/material.dart';
import '../../../core/auth/auth_config.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/clinova_colors.dart';
import '../../../shared/widgets/clinova_logo.dart';
import '../../../shared/widgets/demo_banner.dart';
import '../../../shared/widgets/neumorphic_button.dart';
import '../../../shared/widgets/neumorphic_icon_container.dart';
import '../../../shared/widgets/neumorphic_input.dart';

class DoctorSignupScreen extends StatefulWidget {
  const DoctorSignupScreen({super.key});

  @override
  State<DoctorSignupScreen> createState() => _DoctorSignupScreenState();
}

class _DoctorSignupScreenState extends State<DoctorSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _licenseController = TextEditingController();
  final _specialtyController = TextEditingController();
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
    _licenseController.dispose();
    _specialtyController.dispose();
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
          content: const Text("Please accept the HIPAA & clinical data policy."),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthConfig.authService.registerDoctor(
      name: _nameController.text,
      email: _emailController.text,
      specialty: _specialtyController.text,
      license: _licenseController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.doctorDashboard);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ClinovaColors.secondaryAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.session?.isDemo == true
                      ? "Registration simulated in Demo Mode."
                      : "Doctor account created successfully! Welcome to Clinova.",
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

            final nameField = NeumorphicInput(
              controller: _nameController,
              label: "Full name and title",
              hint: "Dr. Jane Smith, MD",
              prefixIcon: Icons.person_pin_rounded,
              isDense: isDesktop,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter your doctor name and title";
                }
                return null;
              },
            );

            final emailField = NeumorphicInput(
              controller: _emailController,
              label: "Professional email",
              hint: "doctor@hospital.org",
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

            final specialtyField = NeumorphicInput(
              controller: _specialtyController,
              label: "Primary specialty",
              hint: "e.g., General Practice, Internal Medicine",
              prefixIcon: Icons.health_and_safety_outlined,
              isDense: isDesktop,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter your medical specialty";
                }
                return null;
              },
            );

            final licenseField = NeumorphicInput(
              controller: _licenseController,
              label: "Medical registration or license number",
              hint: "Enter your license number",
              prefixIcon: Icons.assignment_ind_outlined,
              isDense: isDesktop,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter your license number placeholder";
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
                    constraints: BoxConstraints(maxWidth: isDesktop ? 840 : 480),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Doctor Role Tag & Logo
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
                                      Icons.local_hospital_rounded,
                                      size: 14,
                                      color: ClinovaColors.primaryAccent,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "Doctor registration",
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

                          SizedBox(height: isDesktop ? 8 : 18),

                          Text(
                            "Register as a doctor",
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontSize: isDesktop ? 22 : 24,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "Set up your professional profile to review patient-submitted cases and AI-assisted summaries.",
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

                          // Two-column fields on desktop, single-column on mobile
                          if (isDesktop) ...[
                            // Row 1: Full name and title | Professional email
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: nameField),
                                const SizedBox(width: 16),
                                Expanded(child: emailField),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Row 2: Primary specialty | Medical registration/license number
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: specialtyField),
                                const SizedBox(width: 16),
                                Expanded(child: licenseField),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Row 3: Password | Confirm password
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: passwordField),
                                const SizedBox(width: 16),
                                Expanded(child: confirmPasswordField),
                              ],
                            ),
                          ] else ...[
                            nameField,
                            const SizedBox(height: 14),
                            emailField,
                            const SizedBox(height: 14),
                            specialtyField,
                            const SizedBox(height: 14),
                            licenseField,
                            const SizedBox(height: 14),
                            passwordField,
                            const SizedBox(height: 14),
                            confirmPasswordField,
                          ],

                          SizedBox(height: isDesktop ? 16 : 20),

                          // Privacy Checkbox
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
                                  "I agree to the professional terms of service and clinical privacy guidelines.",
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
                            text: "Register as a doctor",
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
                                "Already registered? ",
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
