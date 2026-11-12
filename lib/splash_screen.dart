import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'main.dart';

/// Representation of a floating electrical energy micro-particle
class _ElectricParticle {
  final double initialX;
  final double initialY;
  final double radius;
  final double speed;
  final double baseOpacity;
  final double pulseSpeed;

  _ElectricParticle({
    required this.initialX,
    required this.initialY,
    required this.radius,
    required this.speed,
    required this.baseOpacity,
    required this.pulseSpeed,
  });
}

/// CustomPainter rendering electrical energy particles and a flowing light wave
class _ElectricEnergyPainter extends CustomPainter {
  final double progress;
  final List<_ElectricParticle> particles;

  _ElectricEnergyPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Draw Subtle Electrical Light Wave across horizontal center
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF38BDF8).withValues(alpha: 0.0),
          const Color(0xFF38BDF8).withValues(alpha: 0.18),
          const Color(0xFF2563EB).withValues(alpha: 0.25),
          const Color(0xFF38BDF8).withValues(alpha: 0.18),
          const Color(0xFF38BDF8).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final wavePath = Path();
    final double centerY = h * 0.48;
    wavePath.moveTo(0, centerY);

    for (double x = 0; x <= w; x += 10) {
      final double normalizedX = x / w;
      final double wave1 =
          math.sin((normalizedX * 4 * math.pi) + (progress * 2 * math.pi)) * 12;
      final double wave2 =
          math.cos((normalizedX * 2 * math.pi) - (progress * math.pi)) * 6;
      wavePath.lineTo(x, centerY + wave1 + wave2);
    }
    canvas.drawPath(wavePath, wavePaint);

    // 2. Draw Electrical Micro-Particles
    for (final p in particles) {
      final double currentY = ((p.initialY - (progress * p.speed)) % 1.0) * h;
      final double currentX =
          (p.initialX * w) + (math.sin(progress * p.pulseSpeed * math.pi) * 8);

      final double pulse =
          (math.sin(progress * p.pulseSpeed * 2 * math.pi) + 1) / 2;
      final double alpha = (p.baseOpacity * (0.5 + (0.5 * pulse))).clamp(
        0.0,
        1.0,
      );

      // Glow halo
      final glowPaint = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: alpha * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(currentX, currentY), p.radius * 2.0, glowPaint);

      // Core particle
      final corePaint = Paint()..color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(currentX, currentY), p.radius, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ElectricEnergyPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Custom Shader Gradient Transform for Light Sweep across the Logo
class _GradientSweepTransform extends GradientTransform {
  final double sweepPercent;

  const _GradientSweepTransform(this.sweepPercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final double translateX = (bounds.width * 2 * sweepPercent) - bounds.width;
    return Matrix4.translationValues(translateX, 0.0, 0.0);
  }
}

/// Premium, Cinematic Introduction Splash Screen for Shree Shakti Electric
class SplashScreen extends StatefulWidget {
  final Duration? overrideDuration;
  final VoidCallback? onInitialized;

  const SplashScreen({super.key, this.overrideDuration, this.onInitialized});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Staggered scene animations
  late final Animation<double> _backgroundFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoGlow;
  late final Animation<double> _logoSweep;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _loadingProgress;
  late final Animation<double> _contentExitFade;
  late final Animation<double> _contentExitScale;

  late final List<_ElectricParticle> _particles;
  String _statusMessage = "Preparing your workspace...";
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // 1. Initialize Deterministic Particles
    final rnd = math.Random(42);
    _particles = List.generate(28, (index) {
      return _ElectricParticle(
        initialX: rnd.nextDouble(),
        initialY: rnd.nextDouble(),
        radius: 1.0 + (rnd.nextDouble() * 1.8),
        speed: 0.15 + (rnd.nextDouble() * 0.35),
        baseOpacity: 0.3 + (rnd.nextDouble() * 0.6),
        pulseSpeed: 1.5 + (rnd.nextDouble() * 2.5),
      );
    });

    // 2. Setup Animation Timeline (total duration ~2400ms or override)
    final Duration duration =
        widget.overrideDuration ?? const Duration(milliseconds: 2400);
    _controller = AnimationController(vsync: this, duration: duration);

    // Scene 1: Background Reveal (0.0 -> 0.3)
    _backgroundFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    );

    // Scene 2: Logo Scale, Fade, Glow and Light Sweep (0.1 -> 0.6)
    _logoScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.45, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.4, curve: Curves.easeIn),
    );
    _logoGlow = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.6, curve: Curves.easeInOut),
    );
    _logoSweep = Tween<double>(begin: -0.5, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.7, curve: Curves.easeInOutSine),
      ),
    );

    // Scene 3: Brand Text Staggered Reveal (0.35 -> 0.75)
    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.65, curve: Curves.easeIn),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
          ),
        );

    _taglineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.75, curve: Curves.easeIn),
    );
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.5, 0.75, curve: Curves.easeOutCubic),
          ),
        );

    // Scene 4: Loading Progress Fill (0.45 -> 0.88)
    _loadingProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.88, curve: Curves.easeInOut),
      ),
    );

    // Scene 5: Cinema Dissolve Exit (0.9 -> 1.0)
    _contentExitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.9, 1.0, curve: Curves.easeIn),
      ),
    );
    _contentExitScale = Tween<double>(begin: 1.0, end: 1.035).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.9, 1.0, curve: Curves.easeOut),
      ),
    );

    // Dynamic status text update as progress advances
    _controller.addListener(() {
      final double v = _controller.value;
      String nextStatus = _statusMessage;
      if (v < 0.45) {
        nextStatus = "Preparing your workspace...";
      } else if (v < 0.8) {
        nextStatus = "Verifying session credentials...";
      } else {
        nextStatus = "Ready";
      }
      if (nextStatus != _statusMessage && mounted) {
        setState(() {
          _statusMessage = nextStatus;
        });
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToAuthGate();
      }
    });

    // 3. Kick off real initialization concurrently with cinematic animation
    _startAppInitialization();
  }

  /// Concurrently initializes SQLite and SharedPreferences during animation
  Future<void> _startAppInitialization() async {
    final DateTime startTime = DateTime.now();

    // Start background animation
    _controller.forward();

    try {
      // 1. Pre-warm SharedPreferences
      final prefsFuture = SharedPreferences.getInstance();

      // 2. Pre-warm SQLite Database Instance
      final dbFuture = DatabaseHelper.instance.database;

      await Future.wait([prefsFuture, dbFuture]);
    } catch (_) {
      // Ignore background warm-up errors; AuthGate handles full verification
    }

    widget.onInitialized?.call();

    // Ensure minimum cinematic viewing time unless overridden in tests
    if (widget.overrideDuration == null) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      if (elapsed < 2000) {
        await Future.delayed(Duration(milliseconds: 2000 - elapsed));
      }
    }

    if (mounted && !_controller.isCompleted) {
      _controller.animateTo(1.0, duration: const Duration(milliseconds: 400));
    }
  }

  /// Seamlessly navigates to the centralized AuthGate
  void _navigateToAuthGate() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuthGate(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071A35), // Branded Deep Navy Blue
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 600;
          final double emblemSize = isDesktop ? 96.0 : 76.0;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: [
                  // 1. Radial Energy Background
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0.0, -0.15),
                          radius: 1.1,
                          colors: [
                            Color(0xFF0F2B5C),
                            Color(0xFF0A1F42),
                            Color(0xFF071A35),
                          ],
                          stops: [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // 2. Electrical Energy Particles & Wave CustomPainter
                  Positioned.fill(
                    child: FadeTransition(
                      opacity: _backgroundFade,
                      child: CustomPaint(
                        painter: _ElectricEnergyPainter(
                          progress: _controller.value,
                          particles: _particles,
                        ),
                      ),
                    ),
                  ),

                  // 3. Central Brand Composition with Dissolve Exit
                  Center(
                    child: FadeTransition(
                      opacity: _contentExitFade,
                      child: ScaleTransition(
                        scale: _contentExitScale,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28.0,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Scene 2: Electric Energy Emblem
                                _buildEmblem(emblemSize),
                                SizedBox(height: isDesktop ? 26 : 20),

                                // Scene 3: Brand Title
                                _buildBrandTitle(isDesktop),
                                const SizedBox(height: 8),

                                // Scene 3: Tagline
                                _buildTagline(isDesktop),
                                SizedBox(height: isDesktop ? 36 : 28),

                                // Scene 4: Sleek Loading Progress Indicator
                                _buildLoadingIndicator(isDesktop),
                                const SizedBox(height: 12),

                                // Scene 4: Dynamic Status Message
                                _buildStatusText(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Subtle Software Build Label at bottom
                  Positioned(
                    bottom: 18,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: FadeTransition(
                        opacity: _titleFade,
                        child: Text(
                          "SHREE SHAKTI ELECTRIC • ENTERPRISE SUITE v1.0",
                          style: TextStyle(
                            fontSize: 8.5,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(
                              0xFF38BDF8,
                            ).withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Scene 2: Electric energy logo emblem with animated glow & light sweep
  Widget _buildEmblem(double size) {
    return FadeTransition(
      opacity: _logoFade,
      child: ScaleTransition(
        scale: _logoScale,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF0F2B5C), Color(0xFF0A1F42)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.65),
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF38BDF8,
                ).withValues(alpha: 0.35 * _logoGlow.value),
                blurRadius: 28 * _logoGlow.value,
                spreadRadius: 4 * _logoGlow.value,
              ),
              BoxShadow(
                color: const Color(
                  0xFF2563EB,
                ).withValues(alpha: 0.3 * _logoGlow.value),
                blurRadius: 45 * _logoGlow.value,
                spreadRadius: 8 * _logoGlow.value,
              ),
            ],
          ),
          child: Center(
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: const [Colors.white, Color(0xFF38BDF8), Colors.white],
                  stops: const [0.0, 0.5, 1.0],
                  transform: _GradientSweepTransform(_logoSweep.value),
                ).createShader(bounds);
              },
              child: Icon(
                Icons.electric_bolt_rounded,
                size: size * 0.54,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Scene 3: Staggered animated title
  Widget _buildBrandTitle(bool isDesktop) {
    return FadeTransition(
      opacity: _titleFade,
      child: SlideTransition(
        position: _titleSlide,
        child: Text(
          "SHREE SHAKTI ELECTRIC",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: isDesktop ? 26 : 22,
            fontWeight: FontWeight.w900,
            letterSpacing: isDesktop ? 2.5 : 1.8,
            shadows: [
              Shadow(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.45),
                blurRadius: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Scene 3: Staggered animated tagline
  Widget _buildTagline(bool isDesktop) {
    return FadeTransition(
      opacity: _taglineFade,
      child: SlideTransition(
        position: _taglineSlide,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
              width: 1.0,
            ),
          ),
          child: Text(
            "SMART BILLING. SIMPLE BUSINESS.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF38BDF8),
              fontSize: isDesktop ? 10.0 : 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: isDesktop ? 2.8 : 2.0,
            ),
          ),
        ),
      ),
    );
  }

  /// Scene 4: Flowing electric-blue loading track
  Widget _buildLoadingIndicator(bool isDesktop) {
    final double trackWidth = isDesktop ? 240.0 : 190.0;

    return FadeTransition(
      opacity: _titleFade,
      child: Container(
        width: trackWidth,
        height: 3.2,
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A).withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: _loadingProgress.value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.65),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Scene 4: Dynamic status message
  Widget _buildStatusText() {
    return FadeTransition(
      opacity: _titleFade,
      child: Text(
        _statusMessage,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF94A3B8), // Slate 400
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
