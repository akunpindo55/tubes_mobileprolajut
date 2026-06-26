import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/clay_widgets.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref
          .read(authProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);
      if (success && mounted) {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.peachToLilac),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Logo/Header Area
                    ClayContainer(
                      color: AppColors.cardSurface,
                      borderRadius: 28,
                      width: 90,
                      height: 90,
                      child: const Center(
                        child: Icon(
                          LucideIcons.graduationCap,
                          size: 42,
                          color: AppColors.softPeach,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Campus Connect',
                      style: GoogleFonts.outfit(
                        color: AppColors.textDark,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Komunikasi Kampus Gaya Baru',
                      style: GoogleFonts.outfit(
                        color: AppColors.textMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Login Main Card
                    ClayContainer(
                      color: AppColors.cardSurface,
                      borderRadius: 24,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Masuk Akun',
                            style: GoogleFonts.outfit(
                              color: AppColors.textDark,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (authState.errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFF87171),
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                authState.errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFF991B1B),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          ClayTextField(
                            controller: _emailController,
                            label: 'Email Mahasiswa',
                            placeholder: 'npm@student.univ.ac.id',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: LucideIcons.mail,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Email tidak boleh kosong';
                              }
                              if (!val.contains('@')) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          ClayTextField(
                            controller: _passwordController,
                            label: 'Kata Sandi',
                            placeholder: '••••••••',
                            obscureText: true,
                            prefixIcon: LucideIcons.lock,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Kata sandi tidak boleh kosong';
                              }
                              if (val.length < 6) {
                                return 'Kata sandi minimal 6 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),
                          authState.isLoading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(
                                      color: AppColors.babyBlue,
                                      strokeWidth: 4,
                                    ),
                                  ),
                                )
                              : ClayButton(
                                  color: AppColors.babyBlue,
                                  onTap: _submit,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Masuk Sekarang',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        LucideIcons.arrowRight,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Link to register
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: AppColors.textDark,
                          ),
                          children: const [
                            TextSpan(text: 'Belum punya akun? '),
                            TextSpan(
                              text: 'Daftar disini',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                                decoration: TextDecoration.underline,
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
        ),
      ),
    );
  }
}
