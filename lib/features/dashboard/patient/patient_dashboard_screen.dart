import 'package:flutter/material.dart';
import '../../../core/auth/auth_config.dart';
import '../../../core/auth/auth_models.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/clinova_colors.dart';
import 'models/patient_nav_destination.dart';
import 'views/patient_ai_assistant_view.dart';
import 'views/patient_cases_view.dart';
import 'views/patient_home_view.dart';
import 'views/patient_medical_history_view.dart';
import 'views/patient_profile_view.dart';
import 'views/patient_reports_view.dart';
import 'widgets/patient_app_bar.dart';
import 'widgets/patient_bottom_nav_bar.dart';
import 'widgets/patient_notifications_sheet.dart';
import 'widgets/patient_side_drawer.dart';

/// Patient Dashboard Shell implementing the responsive navigation and layout.
///
/// Refined Behavior:
/// - Desktop (width >= 850px): Hidden-by-default overlay drawer controlled by the app bar menu button.
///   No permanent sidebar squeezing the page. No bottom navigation bar.
/// - Mobile (width < 850px): Hidden-by-default overlay drawer via menu button,
///   compact 4-destination bottom navigation bar.
/// - Prominent, full-width app bar across the top.
/// - Main content begins directly with 3 summary cards, "Start a New Case", and recent cases / quick history.
class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  UserSession? _session;
  PatientNavDestination _currentDestination = PatientNavDestination.home;
  bool _hasUnreadNotifications = true;

  @override
  void initState() {
    super.initState();
    _verifySession();
  }

  void _verifySession() {
    final current = AuthConfig.authService.currentSession;
    if (current == null || current.role != UserRole.patient) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.welcome,
          (route) => false,
        );
      });
      return;
    }
    setState(() {
      _session = current;
    });
  }

  Future<void> _handleLogout() async {
    // If drawer is open, close it first
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClinovaColors.surfaceNeumorphic,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Sign Out",
          style: TextStyle(
            color: ClinovaColors.primaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          "Are you sure you want to end your current demo session?",
          style: TextStyle(color: ClinovaColors.secondaryText, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: ClinovaColors.secondaryText),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ClinovaColors.primaryAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Sign Out"),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await AuthConfig.authService.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.welcome,
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ClinovaColors.primaryAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text("Signed out of demo session."),
        ),
      );
    }
  }

  void _onSelectDestination(PatientNavDestination destination) {
    setState(() {
      _currentDestination = destination;
    });
    // Close overlay drawer if open
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _openNotifications() {
    PatientNotificationsSheet.show(
      context,
      onClearUnread: () {
        setState(() {
          _hasUnreadNotifications = false;
        });
      },
    );
  }

  Widget _buildCurrentView() {
    switch (_currentDestination) {
      case PatientNavDestination.home:
        return PatientHomeView(
          onNavigate: _onSelectDestination,
        );
      case PatientNavDestination.myCases:
        return const PatientCasesView();
      case PatientNavDestination.aiAssistant:
        return const PatientAiAssistantView();
      case PatientNavDestination.medicalHistory:
        return const PatientMedicalHistoryView();
      case PatientNavDestination.reports:
        return const PatientReportsView();
      case PatientNavDestination.profile:
        return PatientProfileView(
          session: _session!,
          onLogout: _handleLogout,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return const Scaffold(
        backgroundColor: ClinovaColors.background,
        body: SizedBox.shrink(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 850;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: ClinovaColors.background,
          // Drawer is closed by default on desktop and mobile.
          // Slides in as an overlay from the left when menu button is clicked.
          drawer: Drawer(
            backgroundColor: ClinovaColors.surfaceNeumorphic,
            elevation: 16,
            child: PatientSideDrawer(
              currentDestination: _currentDestination,
              onSelectDestination: _onSelectDestination,
              onLogout: _handleLogout,
              onClose: () {
                if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
          appBar: PatientAppBar(
            isDesktop: isDesktop,
            hasUnreadNotifications: _hasUnreadNotifications,
            onMenuPressed: () {
              if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                Navigator.of(context).pop();
              } else {
                _scaffoldKey.currentState?.openDrawer();
              }
            },
            onNotificationsPressed: _openNotifications,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32.0 : 18.0,
              vertical: isDesktop ? 12.0 : 16.0,
            ),
            child: _buildCurrentView(),
          ),
          bottomNavigationBar: isDesktop
              ? null
              : PatientBottomNavBar(
                  currentDestination: _currentDestination,
                  onSelectDestination: _onSelectDestination,
                ),
        );
      },
    );
  }
}
