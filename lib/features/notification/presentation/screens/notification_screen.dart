import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/clay_widgets.dart';
import '../providers/notification_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);

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
          'Notifikasi',
          style: GoogleFonts.outfit(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (state.notifications.isNotEmpty) ...[
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: Colors.red),
              tooltip: 'Hapus semua',
              onPressed: () => _confirmDeleteAll(context, ref),
            ),
            IconButton(
              icon: const Icon(LucideIcons.checkCheck, color: AppColors.lilac),
              tooltip: 'Tandai semua dibaca',
              onPressed: () => ref.read(notificationProvider.notifier).markAllAsRead(),
            ),
          ],
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.lilac),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(notificationProvider.notifier).loadNotifications(),
              child: state.notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.bellOff, size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada notifikasi',
                            style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.notifications.length,
                      itemBuilder: (context, index) {
                        final n = state.notifications[index];
                        return Dismissible(
                          key: ValueKey(n.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(LucideIcons.trash2, color: Colors.white, size: 24),
                          ),
                          confirmDismiss: (direction) async {
                            return await _confirmDeleteOne(context);
                          },
                          onDismissed: (_) {
                            ref.read(notificationProvider.notifier).deleteNotification(n.id);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () {
                                if (!n.isRead) {
                                  ref.read(notificationProvider.notifier).markAsRead(n.id);
                                }
                              },
                              child: ClayContainer(
                                color: n.isRead
                                    ? Colors.white
                                    : AppColors.lilac.withValues(alpha: 0.15),
                                borderColor: n.isRead
                                    ? AppColors.border
                                    : AppColors.lilac,
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: n.isRead
                                          ? Colors.grey[200]
                                          : AppColors.lilac,
                                      child: Icon(
                                        _iconForType(n.type),
                                        color: n.isRead
                                            ? Colors.grey
                                            : Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            n.displayTitle,
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textDark,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            n.displayBody,
                                            style: GoogleFonts.outfit(
                                              color: AppColors.textMuted,
                                              fontSize: 13,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _timeAgo(n.createdAt),
                                            style: GoogleFonts.outfit(
                                              color: AppColors.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!n.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.lilac,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'message':
        return LucideIcons.messageSquare;
      case 'post_comment':
        return LucideIcons.messageCircle;
      case 'post_reaction':
        return LucideIcons.heart;
      case 'forum_invitation':
        return LucideIcons.userPlus;
      case 'forum_kick':
        return LucideIcons.userX;
      default:
        return LucideIcons.bell;
    }
  }

  String _timeAgo(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m yang lalu';
      if (diff.inHours < 24) return '${diff.inHours}j yang lalu';
      if (diff.inDays < 7) return '${diff.inDays}h yang lalu';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Future<bool> _confirmDeleteOne(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Notifikasi'),
        content: const Text('Hapus notifikasi ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Notifikasi'),
        content: const Text('Semua notifikasi akan dihapus. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus Semua', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (result == true) {
      await ref.read(notificationProvider.notifier).deleteAllNotifications();
    }
    return result ?? false;
  }
}

