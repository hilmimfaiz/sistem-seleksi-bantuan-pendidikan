import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      await ref.read(authProvider.notifier).checkAuth();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        if (next.isAdmin) {
          Navigator.of(context).pushReplacementNamed('/admin/dashboard');
        } else {
          Navigator.of(context).pushReplacementNamed('/mahasiswa/dashboard');
        }
      } else if (next.status == AuthStatus.unauthenticated) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.primary,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
              ? [AppColors.darkSurface, AppColors.darkBackground]
              : [AppColors.primaryLight, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Modern App Icon
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    duration: 800.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 32),

              // App Name
              Text(
                'FinanEdu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ).animate(delay: 300.ms).fadeIn(duration: 600.ms).slideY(
                    begin: 0.1,
                    end: 0,
                    duration: 600.ms,
                    curve: Curves.easeOutQuint,
                  ),

              const SizedBox(height: 8),

              // Tagline
              Text(
                'Sistem Seleksi Bantuan Pendidikan',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ).animate(delay: 500.ms).fadeIn(duration: 500.ms),

              const SizedBox(height: 64),

              // Elegant Loading Indicator
              SizedBox(
                width: 40,
                height: 40,
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ).animate(delay: 800.ms).fadeIn(duration: 400.ms),

            ],
          ),
        ),
      ),
    );
  }
}
