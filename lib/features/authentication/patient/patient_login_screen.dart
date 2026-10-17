import 'package:flutter/material.dart';
import '../../../core/auth/auth_config.dart';
import '../../../core/auth/auth_models.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/clinova_colors.dart';
import '../../../features/dashboard/patient/services/patient_profile_repository.dart';
import '../../../shared/widgets/clinova_logo.dart';
import '../../../shared/widgets/demo_banner.dart';
import '../../../shared/widgets/neumorphic_button.dart';
import '../../../shared/widgets/neumorphic_card.dart';
import '../../../shared/widgets/neumorphic_icon_container.dart';
import '../../../shared/widgets/neumorphic_input.dart';

class PatientLoginScreen extends StatefulWidget {
  const PatientLoginScreen({super.key});

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    final result = await AuthConfig.authService.login(
      email: _emailController.text,
      password: _passwordController.text,
      role: UserRole.patient,
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
                      ? "Signed in as ${result.session?.name ?? 'Patient'}${result.session?.isDemo == true ? ' (Demo Mode)' : ''}"
                      : "Welcome! Please complete your patient profile setup to continue.",
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
            result.errorMessage ?? "Sign in failed.",
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
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: NeumorphicIconContainer(
            size: 40,
            iconSize: 18,
            borderRadius: 12,
            icon: Icons.arrow_back_ios_new_rounded,
            iconColor: ClinovaColors.primaryText,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
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
            final double horizontalPadding = constraints.maxWidth < 600 ? 20.0 : 32.0;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 12.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    // Constrain login form width on desktop/tablet to ~460px
                    constraints: const BoxConstraints(maxWidth: 460),
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
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: ClinovaColors.surfaceNeumorphic,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    width: 0.8,
                                  ),
                                  boxShadow: ClinovaColors.raisedShadow(
                                    blur: 8,
                                    offset: const Offset(2.5, 3),
                                    intensity: 0.65,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_rounded,
                                      size: 15,
                                      color: ClinovaColors.primaryAccent,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "Patient Portal",
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
                              const ClinovaLogo(size: 72),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Heading & Supporting text
                          Text(
                            "Welcome back",
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontSize: 26,
                                  letterSpacing: -0.4,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Your health journey, all in one place.",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                          ),

                          const SizedBox(height: 12),

                          const DemoBanner(compact: true, margin: EdgeInsets.only(bottom: 4)),

                          const SizedBox(height: 8),

                          // Email field
                          NeumorphicInput(
                            controller: _emailController,
                            label: "Email address",
                            hint: "name@example.com",
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
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
                          ),

                          const SizedBox(height: 16),

                          // Password field
                          NeumorphicInput(
                            controller: _passwordController,
                            label: "Password",
                            hint: "Enter your password",
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: ClinovaColors.secondaryText,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter your password";
                              }
                              if (value.length < 6) {
                                return "Password must be at least 6 characters";
                              }
                              return null;
                            },
                          ),

                          // Forgot Password Action
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.forgotPassword,
                                  arguments: {'role': 'Patient'},
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                              ),
                              child: const Text(
                                "Forgot password?",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: ClinovaColors.secondaryAccent,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Sign In Button
                          NeumorphicButton(
                            text: "Sign in to Clinova",
                            isLoading: _isLoading,
                            onPressed: _handleSignIn,
                          ),

                          const SizedBox(height: 22),

                          // Create Account Navigation
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                "New to Clinova? ",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ClinovaColors.secondaryText,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushNamed(AppRoutes.patientSignup);
                                },
                                child: const Text(
                                  "Create your account",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: ClinovaColors.primaryAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // Clinova purpose soft card
                          NeumorphicCard(
                            padding: const EdgeInsets.all(14),
                            borderRadius: 16,
                            child: Row(
                              children: [
                                NeumorphicIconContainer(
                                  size: 38,
                                  iconSize: 19,
                                  borderRadius: 12,
                                  icon: Icons.assignment_outlined,
                                  iconColor: ClinovaColors.secondaryAccent,
                                  isInset: true,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    "Clinova helps you organize your health concerns and prepare structured case summaries for your doctor.",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ClinovaColors.secondaryText,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
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
