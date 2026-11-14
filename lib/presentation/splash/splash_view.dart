import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_seeder.dart';
import '../../core/di/injection_container.dart';
import '../adaptive_scaffold.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  String _statusText = 'Initializing Vitalis Clinical Portal...';

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Defensive startup rule: defer all heavy SQLite seeding and precaching to addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _executeClinicalBootSequence();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _executeClinicalBootSequence() async {
    try {
      // Step 1: Precache branded assets safely post-frame
      if (mounted) {
        await precacheImage(
          const AssetImage('assets/icons/app_icon.png'),
          context,
        ).catchError((_) {});
      }

      // Step 2: Initialize Database and Seed Data
      if (mounted) {
        setState(() {
          _statusText =
              'Initializing encrypted SQLite clinical health record...';
        });
      }
      final db = await AppDatabase.instance;
      await DatabaseSeeder.seedDatabase(db);

      await Future.delayed(const Duration(milliseconds: 400));

      // Step 3: Platform Channels and DI
      if (mounted) {
        setState(() {
          _statusText =
              'Mounting native BLE medical sensor platform channels...';
        });
      }
      await initDependencyInjection();

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _statusText = 'Vitalis Clinical Portal Ready.';
        });
      }

      await Future.delayed(const Duration(milliseconds: 350));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, _, _) => const AdaptiveScaffold(),
            transitionsBuilder: (_, animation, _, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    } catch (e) {
      debugPrint('Error during boot sequence: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdaptiveScaffold()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: colorScheme.surfaceContainerHighest,
                      border: Border.all(
                        color: colorScheme.primary.withAlpha(80),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withAlpha(35),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      errorBuilder: (_, _, _) => Icon(
                        Icons.health_and_safety_rounded,
                        size: 64,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Text(
                'VITALIS',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4.0,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'CLINICAL TELEMETRY & DIAGNOSTICS ECOSYSTEM',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 180,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
