import 'package:flutter/material.dart';
import '../../core/theme/clinova_colors.dart';
import '../../shared/widgets/clinova_logo.dart';
import '../../shared/widgets/neumorphic_button.dart';
import '../../shared/widgets/neumorphic_card.dart';
import '../../shared/widgets/neumorphic_icon_container.dart';
import '../../shared/widgets/neumorphic_input.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String role;

  const ForgotPasswordScreen({
    super.key,
    required this.role,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleReset() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
      });
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
                  vertical: 16.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: _emailSent ? _buildSuccessView() : _buildRequestForm(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRequestForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: ClinovaColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ClinovaColors.borderLight.withValues(alpha: 0.6),
                  ),
                  boxShadow: ClinovaColors.raisedShadow(
                    blur: 8,
                    offset: const Offset(2.5, 2.5),
                    intensity: 0.6,
                  ),
                ),
                child: Text(
                  "${widget.role} Password Recovery",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ClinovaColors.primaryAccent,
                  ),
                ),
              ),
              const Spacer(),
              const ClinovaLogo.header(size: 46),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "Reset Password",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 26,
                  letterSpacing: -0.4,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            "Enter the registered email associated with your Clinova ${widget.role.toLowerCase()} account. We'll send instructions to reset your password.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 26),
          NeumorphicInput(
            controller: _emailController,
            label: "Registered Email Address",
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
          const SizedBox(height: 24),
          NeumorphicButton(
            text: "Send Reset Link",
            isLoading: _isLoading,
            onPressed: _handleReset,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        NeumorphicCard(
          borderRadius: 36,
          padding: const EdgeInsets.all(22),
          child: const Icon(
            Icons.mark_email_read_outlined,
            size: 44,
            color: ClinovaColors.primaryAccent,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Check Your Inbox",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 26,
                letterSpacing: -0.4,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "We have dispatched password reset instructions to ${_emailController.text.trim()}.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.45,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 28),
        NeumorphicButton(
          text: "Back to Login",
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
