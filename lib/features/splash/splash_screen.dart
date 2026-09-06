import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  final String? pendingProductId;
  final String? pendingRefCode;

  const SplashScreen({super.key, this.pendingProductId, this.pendingRefCode});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _taglineFade;
  late final Animation<double> _progress;
  late final Animation<double> _spinner;
  Timer? _navTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.65, curve: Curves.easeOut),
      ),
    );

    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _spinner = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().requestLocation();
    });
    // An outer cap so a hung session restore can never leave the splash frozen
    // forever; _navigate is single-flight so only the first completion wins.
    _navTimer = Timer(const Duration(seconds: 6), _navigate);
    _navigate();
  }

  Future<void> _navigate() async {
    if (_navigated || !mounted) return;
    // Hold the splash for its brand moment, AND until the cached session is
    // restored, so the home screen never opens in a false logged-out state.
    // The cap keeps a slow token refresh from stalling the app.
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 1600)),
      context.read<AuthProvider>().initialized.timeout(
            const Duration(seconds: 5),
            onTimeout: () {},
          ),
    ]);
    if (_navigated || !mounted) return;
    _navigated = true;
    _navTimer?.cancel();
    if (widget.pendingProductId != null) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.productDetail,
        arguments: {
          'product_id': widget.pendingProductId,
          'ref': widget.pendingRefCode,
        },
      );
    } else {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryDark,
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, child) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Decorative floating circles
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ring
                      Transform.rotate(
                        angle: _spinner.value,
                        child: SizedBox(
                          width: 200,
                          height: 200,
                          child: CustomPaint(
                            painter: _RingPainter(
                              progress: _progress.value,
                              color: AppColors.brandGold,
                            ),
                          ),
                        ),
                      ),
                      // Middle ring
                      Transform.rotate(
                        angle: -_spinner.value * 0.7,
                        child: SizedBox(
                          width: 170,
                          height: 170,
                          child: CustomPaint(
                            painter: _RingPainter(
                              progress: _progress.value * 0.8,
                              color: AppColors.brandGold.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      ),
                      // Logo
                      Opacity(
                        opacity: _logoFade.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandGold
                                      .withValues(alpha: 0.35),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: Image.asset(
                                'assets/logo.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Tagline
                Opacity(
                  opacity: _taglineFade.value,
                  child: const Column(
                    children: [
                      Text(
                        'DRISTI FASHIONS',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandGold,
                          letterSpacing: 4,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Fashion That Reflects Your Personality',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.primaryLight,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // Loading bar
                Opacity(
                  opacity: _taglineFade.value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 80),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: _progress.value,
                              backgroundColor: AppColors.brandGoldLight.withValues(alpha: 0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.brandGold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Loading...',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.inversePrimary,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
