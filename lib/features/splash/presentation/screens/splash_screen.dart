import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Wait for auth check to complete
    final authState = ref.read(authProvider);
    if (authState.isLoading) {
      await Future.delayed(const Duration(seconds: 2));
    }
    if (!mounted) return;

    final finalState = ref.read(authProvider);
    if (!mounted) return;
    if (finalState.isAuthenticated) {
      context.go('/');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Lottie.asset(
                  'assets/lottie/splash_logo.json',
                  fit: BoxFit.contain,
                  repeat: false,
                  animate: true,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    LucideIcons.messageSquare,
                    size: 80,
                    color: AppColors.lilac,
                  ),
                ),
              ),
            ),

            // App title with elegant typography
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Text(
                'Campus Connect',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.grey[800],
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // Tagline with refined styling
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Text(
                'Membuat pengalaman belajar bersama...',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            // Version indicator (optional, now with enhanced styling)
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'v1.0.0',
                  style: GoogleFonts.outfit(
                    color: Colors.grey[500],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
