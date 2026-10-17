import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/auth/auth_config.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/clinova_colors.dart';
import '../dashboard/patient/services/patient_profile_repository.dart';

/// Clinova choreographed splash screen animation based on the brand storyboard:
/// - Phase 1 (0–400 ms): Heart appears alone, fades in, scales 0.75 -> 1.0
/// - Phase 2 (400–1300 ms): Two distinct heartbeat pulses (1.0 -> 1.10 -> 1.0 twice) with subtle green glow
/// - Phase 3 (1100–1700 ms): Clinova wordmark & tagline fades in & slides up ~20px directly beneath the heart
/// - Phase 4 (1500–2200 ms): Botanical leaves fade in & slide up ~25px, framing the logo composition
/// - Phase 5 (2200–3200 ms): Full logo composition held still for ~1000 ms, then smoothly navigates to Welcome
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _mainController;

  // Ambient background fade
  late Animation<double> _bgFade;

  // Phase 1: Heart entrance (0–400 ms)
  late Animation<double> _heartEntranceFade;
  late Animation<double> _heartEntranceScale;

  // Phase 2: Heartbeat pulses & subtle green glow (400–1300 ms)
  late Animation<double> _heartPulseScale;
  late Animation<double> _heartGlow;

  // Phase 3: Clinova Wordmark reveal (1100–1700 ms)
  late Animation<double> _wordmarkFade;
  late Animation<Offset> _wordmarkSlide;

  // Phase 4: Botanical leaves reveal (1500–2200 ms)
  late Animation<double> _leavesFade;
  late Animation<Offset> _leavesSlide;
  late Animation<double> _leavesScale;

  // Phase 5: Hold & subtle preparation indicator (2200–3200 ms)
  late Animation<double> _holdFade;

  Timer? _navTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Total duration: 3200 ms
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // Background fade: 0 to 300 ms (0.0 to ~0.094)
    _bgFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.00, 0.094, curve: Curves.easeIn),
      ),
    );

    // =========================================================================
    // PHASE 1: HEART APPEARS (0–400 ms -> 0.000 to 0.125)
    // Fades in while scaling smoothly from 0.75 to 1.0
    // =========================================================================
    _heartEntranceFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.00, 0.125, curve: Curves.easeIn),
      ),
    );

    _heartEntranceScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.00, 0.125, curve: Curves.easeOutCubic),
      ),
    );

    // =========================================================================
    // PHASE 2: HEARTBEATS (400–1300 ms -> 0.125 to 0.406)
    // Two distinct heartbeat pulses: 1.0 -> 1.10 -> 1.0 -> (pause) -> 1.0 -> 1.10 -> 1.0
    // Subtle green glow during each pulse
    // =========================================================================
    _heartPulseScale = TweenSequence<double>([
      // 0 to 400 ms: constant 1.0 before heartbeat begins
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 400,
      ),
      // Pulse 1 up: 400 to 580 ms (1.0 -> 1.10)
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.10)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 180,
      ),
      // Pulse 1 settle: 580 to 780 ms (1.10 -> 1.0)
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.10, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 200,
      ),
      // Pause between beats: 780 to 900 ms
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 120,
      ),
      // Pulse 2 up: 900 to 1080 ms (1.0 -> 1.10)
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.10)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 180,
      ),
      // Pulse 2 settle: 1080 to 1300 ms (1.10 -> 1.0)
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.10, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 220,
      ),
      // Resting full size onward: 1300 to 3200 ms
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 1900,
      ),
    ]).animate(_mainController);

    // Glow intensity matches the two pulses
    _heartGlow = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 400),
      // Pulse 1 glow
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 180,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 200,
      ),
      // Brief pause
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 120),
      // Pulse 2 glow
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 180,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 220,
      ),
      // Remaining hold duration
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 1900),
    ]).animate(_mainController);

    // =========================================================================
    // PHASE 3: CLINOVA WORDMARK REVEAL (1100–1700 ms -> 0.344 to 0.531)
    // Fades in and slides upward ~20px directly beneath the heart
    // =========================================================================
    _wordmarkFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.344, 0.490, curve: Curves.easeIn),
      ),
    );

    _wordmarkSlide = Tween<Offset>(
      begin: const Offset(0, 0.25), // ~20px translation relative to wordmark height
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.344, 0.531, curve: Curves.easeOutCubic),
      ),
    );

    // =========================================================================
    // PHASE 4: BOTANICAL LEAVES REVEAL (1500–2200 ms -> 0.469 to 0.688)
    // Fades in and slides upward ~25px, framing the composition
    // =========================================================================
    _leavesFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.469, 0.640, curve: Curves.easeIn),
      ),
    );

    _leavesSlide = Tween<Offset>(
      begin: const Offset(0, 0.22), // ~25px translation relative to leaves height
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.469, 0.688, curve: Curves.easeOutCubic),
      ),
    );

    _leavesScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.469, 0.688, curve: Curves.easeOutCubic),
      ),
    );

    // =========================================================================
    // PHASE 5: HOLD & PREPARATION (2200–3200 ms -> 0.688 to 1.000)
    // Full logo holds still and calm; subtle indicator reveals
    // =========================================================================
    _holdFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.720, 0.880, curve: Curves.easeIn),
      ),
    );

    // Start playback
    _mainController.forward();

    // Navigate when timeline completes
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToWelcome();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Accessibility: Reduced motion support
    if (MediaQuery.of(context).disableAnimations && !_navigated) {
      _mainController.value = 1.0;
      _navTimer?.cancel();
      _navTimer = Timer(const Duration(milliseconds: 600), _navigateToWelcome);
    }
  }

  void _navigateToWelcome() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    final session = AuthConfig.authService.currentSession;
    if (session != null) {
      if (session.isDoctor) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.doctorDashboard);
        return;
      } else if (session.isPatient) {
        await PatientProfileRepository.instance.loadForUser(session);
        if (!mounted) return;
        if (PatientProfileRepository.instance.isPatientProfileComplete) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.patientDashboard);
        } else {
          Navigator.of(context).pushReplacementNamed(AppRoutes.patientOnboarding);
        }
        return;
      }
    }

    Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 600;

    // Responsive dimensions
    // Mobile: ~300-340px width, desktop: ~380-420px width
    final double maxContainerWidth = isDesktop
        ? 400.0
        : (screenSize.width * 0.82).clamp(280.0, 340.0);

    // Heart is sized ~180-240px on mobile
    final double heartWidth = (maxContainerWidth * 0.68).clamp(180.0, 240.0);
    final double heartHeight = heartWidth * (682 / 1024);

    // Wordmark & Tagline: proportional to container
    final double wordmarkWidth = maxContainerWidth * 0.80;
    final double wordmarkHeight = wordmarkWidth * (341 / 1024);

    // Leaves: framing the lower composition
    final double leavesWidth = maxContainerWidth * 1.05;
    final double leavesHeight = leavesWidth * (341 / 1024);

    return Scaffold(
      backgroundColor: ClinovaColors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _navigateToWelcome, // Allow skip-on-tap
        child: AnimatedBuilder(
          animation: _mainController,
          builder: (context, _) {
            final double glow = _heartGlow.value;
            final double currentHeartScale =
                _heartEntranceScale.value * _heartPulseScale.value;

            return Opacity(
              opacity: _bgFade.value,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Soft ambient radial gradients from the Clinova palette
                  Positioned(
                    top: -screenSize.width * 0.25,
                    right: -screenSize.width * 0.20,
                    child: Container(
                      width: screenSize.width * 0.8,
                      height: screenSize.width * 0.8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            ClinovaColors.secondaryBackground.withValues(alpha: 0.45),
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
                      width: screenSize.width * 0.85,
                      height: screenSize.width * 0.85,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            ClinovaColors.primaryBackground.withValues(alpha: 0.55),
                            ClinovaColors.background.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Assembled Logo in the exact brand proportions
                  Center(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Unified logo stack: Leaves behind / framing + Heart + Wordmark
                            SizedBox(
                              width: leavesWidth,
                              height: heartHeight + wordmarkHeight + 8,
                              child: Stack(
                                alignment: Alignment.topCenter,
                                clipBehavior: Clip.none,
                                children: [
                                  // =====================================================
                                  // PHASE 4: BOTANICAL LEAVES (1500–2200 ms)
                                  // Flanks the lower logo composition
                                  // =====================================================
                                  Positioned(
                                    bottom: -2,
                                    child: SlideTransition(
                                      position: _leavesSlide,
                                      child: Transform.scale(
                                        scale: _leavesScale.value,
                                        child: Opacity(
                                          opacity: _leavesFade.value,
                                          child: Image.asset(
                                            'assets/images/leaves.png',
                                            width: leavesWidth,
                                            height: leavesHeight,
                                            fit: BoxFit.contain,
                                            filterQuality: FilterQuality.high,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // =====================================================
                                  // PHASES 1 & 2: HEART (0–1300 ms)
                                  // Entrance fade + scale, followed by double heartbeat & glow
                                  // =====================================================
                                  Positioned(
                                    top: 0,
                                    child: SizedBox(
                                      width: heartWidth,
                                      height: heartHeight,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        clipBehavior: Clip.none,
                                        children: [
                                          // Concentric heartbeat ripple ring
                                          if (glow > 0.05)
                                            Container(
                                              width: heartWidth * (0.85 + 0.20 * glow),
                                              height: heartHeight * (0.85 + 0.20 * glow),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: ClinovaColors.secondaryAccent
                                                      .withValues(alpha: 0.28 * glow),
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),

                                          // Subtle heartbeat shadow glow
                                          if (glow > 0.01)
                                            Container(
                                              width: heartWidth * 0.75,
                                              height: heartHeight * 0.70,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: ClinovaColors.secondaryAccent
                                                        .withValues(alpha: 0.32 * glow),
                                                    blurRadius: 28 * glow,
                                                    spreadRadius: 6 * glow,
                                                  ),
                                                ],
                                              ),
                                            ),

                                          // Heart Image
                                          Transform.scale(
                                            scale: currentHeartScale,
                                            child: Opacity(
                                              opacity: _heartEntranceFade.value,
                                              child: Image.asset(
                                                'assets/images/heart.png',
                                                width: heartWidth,
                                                height: heartHeight,
                                                fit: BoxFit.contain,
                                                filterQuality: FilterQuality.high,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // =====================================================
                                  // PHASE 3: CLINOVA WORDMARK & TAGLINE (1100–1700 ms)
                                  // Fade + slide up directly beneath the heart
                                  // =====================================================
                                  Positioned(
                                    top: heartHeight - 6,
                                    child: SlideTransition(
                                      position: _wordmarkSlide,
                                      child: Opacity(
                                        opacity: _wordmarkFade.value,
                                        child: Image.asset(
                                          'assets/images/clinova_wordmark.png',
                                          width: wordmarkWidth,
                                          height: wordmarkHeight,
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.high,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // =========================================================
                            // PHASE 5: HOLD & CALM PREPARATION INDICATOR (2200–3200 ms)
                            // =========================================================
                            Opacity(
                              opacity: _holdFade.value,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: ClinovaColors.primaryAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Preparing your care experience',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: ClinovaColors.secondaryText,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: ClinovaColors.primaryAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
