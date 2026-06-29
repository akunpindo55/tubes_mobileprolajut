import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/clay_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? username;

  const ProfileScreen({super.key, this.username});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (widget.username != null) {
        ref.read(profileProvider.notifier).loadProfile(widget.username!);
      }
    });
  }

  void _showEditProfileDialog(Map<String, dynamic> profile) {
    final nameController = TextEditingController(text: profile['name'] ?? '');
    final bioController = TextEditingController(text: profile['bio'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit Profil',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              ClayTextField(
                controller: nameController,
                label: 'Nama Lengkap',
                placeholder: 'Masukkan nama Anda',
              ),
              const SizedBox(height: 12),
              ClayTextField(
                controller: bioController,
                label: 'Bio',
                placeholder: 'Ceritakan tentang diri Anda',
              ),
              const SizedBox(height: 20),
              ClayButton(
                color: AppColors.babyBlue,
                onTap: () async {
                  final ok = await ref
                      .read(profileProvider.notifier)
                      .updateProfile({
                        'name': nameController.text.trim(),
                        'bio': bioController.text.trim(),
                      });
                  if (ok && mounted) {
                    ref.read(authProvider.notifier).refreshUser();
                    Navigator.pop(ctx);
                  }
                },
                child: Text(
                  'Simpan',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ganti Password',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              ClayTextField(
                controller: currentPwController,
                label: 'Password Saat Ini',
                placeholder: 'Masukkan password lama',
                obscureText: true,
              ),
              const SizedBox(height: 12),
              ClayTextField(
                controller: newPwController,
                label: 'Password Baru',
                placeholder: 'Masukkan password baru',
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ClayButton(
                color: AppColors.softPeach,
                onTap: () async {
                  if (currentPwController.text.isNotEmpty &&
                      newPwController.text.isNotEmpty) {
                    final ok = await ref
                        .read(profileProvider.notifier)
                        .changePassword(
                          currentPwController.text.trim(),
                          newPwController.text.trim(),
                        );
                    if (ok && mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password berhasil diubah!')),
                      );
                    } else if (mounted) {
                      final error = ref.read(profileProvider).errorMessage ?? 'Gagal mengubah password.';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  'Ganti Password',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final authState = ref.watch(authProvider);
    final profile = profileState.profile;
    final isOwnProfile = widget.username == null ||
        authState.user?['username'] == widget.username;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isOwnProfile ? 'Profil Saya' : 'Profil Pengguna',
          style: GoogleFonts.outfit(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: profileState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.babyBlue),
            )
          : profile == null
          ? Center(
              child: Text(
                'Profil tidak ditemukan.',
                style: GoogleFonts.outfit(color: AppColors.textMuted),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile Header
                ClayContainer(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.lilac,
                        backgroundImage: profile['avatar'] != null
                            ? NetworkImage(profile['avatar'])
                            : null,
                        child: profile['avatar'] == null
                            ? const Icon(
                                LucideIcons.user,
                                size: 40,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile['name'] ?? 'Pengguna',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${profile['username'] ?? 'username'}',
                        style: GoogleFonts.outfit(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      if (profile['bio'] != null &&
                          profile['bio'].toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          profile['bio'],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: AppColors.textDark,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            '${profile['forum_count'] ?? 0}',
                            'Forum',
                          ),
                          _buildStatItem(
                            '${profile['topics_count'] ?? 0}',
                            'Topik',
                          ),
                          _buildStatItem(
                            '${profile['posts_count'] ?? 0}',
                            'Postingan',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                if (isOwnProfile) ...[
                  ClayButton(
                    color: AppColors.babyBlue,
                    onTap: () => _showEditProfileDialog(profile),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.edit, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Edit Profil',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClayButton(
                    color: AppColors.softPeach,
                    onTap: _showChangePasswordDialog,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.lock, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Ganti Password',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ClayButton(
                    color: AppColors.softPeach,
                    onTap: () {
                      ref.read(profileProvider.notifier).blockUser(profile['id']);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.userX, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Blokir Pengguna',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
