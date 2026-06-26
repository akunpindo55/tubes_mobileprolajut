import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/clay_widgets.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref
          .read(authProvider.notifier)
          .register(
            _usernameController.text.trim(),
            _nameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi sukses! Silakan masuk.'),
            backgroundColor: AppColors.mint,
          ),
        );
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.blueToMint),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Gabung Komunitas',
                      style: GoogleFonts.outfit(
                        color: AppColors.textDark,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Buat akun mahasiswa baru Anda',
                      style: GoogleFonts.outfit(
                        color: AppColors.textMuted,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Card container
                    ClayContainer(
                      color: AppColors.cardSurface,
                      borderRadius: 24,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                            controller: _usernameController,
                            label: 'Username',
                            placeholder: 'budi_hartono',
                            prefixIcon: LucideIcons.user,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Username tidak boleh kosong';
                              }
                              if (val.length < 3) {
                                return 'Username minimal 3 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          ClayTextField(
                            controller: _nameController,
                            label: 'Nama Lengkap',
                            placeholder: 'Budi Hartono',
                            prefixIcon: LucideIcons.creditCard,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Nama tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          ClayTextField(
                            controller: _emailController,
                            label: 'Email Student',
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
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 24),
                          authState.isLoading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(
                                      color: AppColors.softPeach,
                                      strokeWidth: 4,
                                    ),
                                  ),
                                )
                              : ClayButton(
                                  color: AppColors.softPeach,
                                  onTap: _submit,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Daftar Sekarang',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        LucideIcons.userPlus,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Back to login
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: AppColors.textDark,
                          ),
                          children: const [
                            TextSpan(text: 'Sudah punya akun? '),
                            TextSpan(
                              text: 'Masuk disini',
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
