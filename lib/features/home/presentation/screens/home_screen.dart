import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/clay_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../feed/presentation/providers/feed_provider.dart';
import '../../../forum/presentation/providers/forum_provider.dart';
import '../../../notification/presentation/providers/notification_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    // Load initial data
    Future.microtask(() {
      ref.read(feedProvider.notifier).loadFeed();
      ref.read(chatProvider.notifier).loadConversations();
      ref.read(forumProvider.notifier).loadMyForums();
      ref.read(forumProvider.notifier).loadPublicForums();
      ref.read(notificationProvider.notifier).loadNotifications();
      ref.read(notificationProvider.notifier).startPolling();
    });
  }

  @override
  void dispose() {
    ref.read(notificationProvider.notifier).stopPolling();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentTab = index;
    });
    // Trigger refreshes depending on current tab
    if (index == 0) ref.read(feedProvider.notifier).loadFeed();
    if (index == 1) ref.read(chatProvider.notifier).loadConversations();
    if (index == 2) {
      ref.read(forumProvider.notifier).loadMyForums();
      ref.read(forumProvider.notifier).loadPublicForums();
    }
    if (index == 3) ref.read(notificationProvider.notifier).loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _getTabTitle(),
          style: GoogleFonts.outfit(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.user, color: AppColors.textDark),
            onSelected: (value) {
              if (value == 'profile') {
                context.push('/profile');
              } else if (value == 'logout') {
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(LucideIcons.user, color: AppColors.textDark),
                  title: Text('Profil Saya'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(LucideIcons.logOut, color: Colors.redAccent),
                  title: Text('Logout', style: TextStyle(color: Colors.redAccent)),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTab,
        children: [_FeedTab(), _ChatTab(), _ForumTab(), _NotificationTab()],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16, top: 8),
        color: Colors.white,
        child: ClayContainer(
          color: Colors.white,
          borderRadius: 24,
          borderWidth: 3.0,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabItem(0, LucideIcons.home, 'Home'),
              _buildTabItem(1, LucideIcons.messageSquare, 'Chat'),
              _buildTabItem(2, LucideIcons.users, 'Forum'),
              _buildTabItemWithBadge(3, LucideIcons.bell, 'Notif'),
            ],
          ),
        ),
      ),
    );
  }

  String _getTabTitle() {
    switch (_currentTab) {
      case 0:
        return 'Campus Feed';
      case 1:
        return 'Direct Messages';
      case 2:
        return 'Diskusi Forum';
      case 3:
        return 'Notifikasi Anda';
      default:
        return 'Campus Connect';
    }
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    final isSelected = _currentTab == index;
    final activeColor = index == 0
        ? AppColors.softPeach
        : index == 1
        ? AppColors.babyBlue
        : index == 2
        ? AppColors.mint
        : AppColors.lilac;

    return GestureDetector(
      onTap: () => _onTabChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 2.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.textDark : AppColors.textMuted,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabItemWithBadge(int index, IconData icon, String label) {
    final isSelected = _currentTab == index;
    final activeColor = AppColors.lilac;
    final unreadCount = ref.watch(notificationProvider).unreadCount;

    return GestureDetector(
      onTap: () => _onTabChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 2.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.textDark : AppColors.textMuted,
                  size: 22,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================== FEED TAB ====================
class _FeedTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedProvider);

    return Column(
      children: [
        // Create Post Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ClayContainer(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.softPeach,
                  child: Icon(LucideIcons.user, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showCreatePostSheet(context, ref),
                    child: Text(
                      'Apa yang Anda pikirkan hari ini?',
                      style: GoogleFonts.outfit(color: AppColors.textMuted),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    LucideIcons.image,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => _showCreatePostSheet(context, ref),
                ),
              ],
            ),
          ),
        ),

        // Posts List
        Expanded(
          child: feedState.isLoading
              ? _buildShimmerLoader()
              : RefreshIndicator(
                  onRefresh: () => ref.read(feedProvider.notifier).loadFeed(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: feedState.posts.length,
                    itemBuilder: (context, index) {
                      final post = feedState.posts[index];
                      return _buildPostCard(context, ref, post);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPostCard(BuildContext context, WidgetRef ref, PostModel post) {
    final isLiked = post.userReaction == 'like';
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?['id'] as int?;
    final postUserId = post.user['id'] as int?;
    final isMyPost = currentUserId != null && postUserId != null && currentUserId == postUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClayContainer(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Meta
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    final username = post.user['username']?.toString();
                    if (username != null && username.isNotEmpty) {
                      context.push('/profile/$username');
                    }
                  },
                  child: CircleAvatar(
                    backgroundColor: AppColors.babyBlue,
                    backgroundImage: post.user['avatar'] != null
                        ? NetworkImage(post.user['avatar'])
                        : null,
                    child: post.user['avatar'] == null
                        ? const Icon(LucideIcons.user, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.user['name'] ?? 'Mahasiswa',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        '@${post.user['username'] ?? 'username'}',
                        style: GoogleFonts.outfit(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Visibility Indicator + More menu
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: post.visibility == 'public'
                            ? AppColors.mint.withValues(alpha: 0.2)
                            : AppColors.lilac.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: post.visibility == 'public'
                              ? AppColors.mint
                              : AppColors.lilac,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        post.visibility == 'public' ? 'Publik' : 'Internal',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: const Icon(LucideIcons.moreHorizontal,
                          size: 16, color: AppColors.textMuted),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditPostSheet(context, ref, post);
                        } else if (value == 'delete') {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Hapus Postingan'),
                              content: const Text(
                                'Apakah Anda yakin ingin menghapus postingan ini?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    ref
                                        .read(feedProvider.notifier)
                                        .deletePost(post.id);
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                  ),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          );
                        } else if (value == 'report') {
                          context.push('/report/post/${post.id}');
                        }
                      },
                      itemBuilder: (builderContext) => [
                        if (isMyPost) ...[
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(LucideIcons.edit,
                                  color: AppColors.babyBlue, size: 18),
                              title: Text('Edit',
                                  style: TextStyle(fontSize: 13)),
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(LucideIcons.trash2,
                                  color: Colors.redAccent, size: 18),
                              title: Text('Hapus',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.redAccent)),
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                        const PopupMenuItem(
                          value: 'report',
                          child: ListTile(
                            leading: Icon(LucideIcons.flag,
                                color: Colors.orange, size: 18),
                            title: Text('Laporkan',
                                style: TextStyle(fontSize: 13)),
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Content
            Text(
              post.content,
              style: GoogleFonts.outfit(
                color: AppColors.textDark,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            if (post.media.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildPostMedia(context, post.media),
            ],
            const SizedBox(height: 16),

            // Footer Actions
            Row(
              children: [
                // React Button
                GestureDetector(
                  onTap: () => ref
                      .read(feedProvider.notifier)
                      .reactPost(post.id, 'like'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isLiked
                          ? AppColors.softPeach.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isLiked ? AppColors.softPeach : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.heart,
                          color: isLiked
                              ? Colors.redAccent
                              : AppColors.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.reactionsTotal}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Comment Button trigger
                GestureDetector(
                  onTap: () => _showCommentsDialog(context, ref, post.id, currentUserId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.messageSquare,
                          color: AppColors.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.commentsCount}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostMedia(BuildContext context, List<dynamic> media) {
    final count = media.length;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: count == 1
          ? _buildMediaItem(context, media[0], double.infinity, 280)
          : count == 2
              ? Row(
                  children: [
                    Expanded(child: _buildMediaItem(context, media[0], double.infinity, 220)),
                    const SizedBox(width: 4),
                    Expanded(child: _buildMediaItem(context, media[1], double.infinity, 220)),
                  ],
                )
              : count == 3
                  ? Column(
                      children: [
                        _buildMediaItem(context, media[0], double.infinity, 220),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(child: _buildMediaItem(context, media[1], double.infinity, 120)),
                            const SizedBox(width: 4),
                            Expanded(child: _buildMediaItem(context, media[2], double.infinity, 120)),
                          ],
                        ),
                      ],
                    )
                  : GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      childAspectRatio: 1.2,
                      children: media.take(4).map((m) => _buildMediaItem(context, m, double.infinity, null)).toList(),
                    ),
    );
  }

  Widget _buildMediaItem(BuildContext context, dynamic mediaItem, double width, double? height) {
    final url = mediaItem['media_url'] ?? '';
    final type = mediaItem['media_type'] ?? 'image';
    final child = type == 'video'
        ? Stack(
            alignment: Alignment.center,
            children: [
              Image.network(url, width: width, height: height, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(LucideIcons.file, size: 32)),
              const Icon(LucideIcons.playCircle, color: Colors.white, size: 40),
            ],
          )
        : Image.network(url, width: width, height: height, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(LucideIcons.file, size: 32));

    return GestureDetector(
      onTap: () => _showMediaPreview(context, url, type),
      child: child,
    );
  }

  void _showMediaPreview(BuildContext context, String url, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: type == 'video'
                  ? const Icon(LucideIcons.video, color: Colors.white, size: 64)
                  : Image.network(url, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(LucideIcons.file, color: Colors.white, size: 64)),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditPostSheet(BuildContext context, WidgetRef ref, PostModel post) {
    final controller = TextEditingController(text: post.content);
    String visibility = post.visibility;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Postingan',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Visibilitas:',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Publik'),
                        selected: visibility == 'public',
                        selectedColor: AppColors.mint.withValues(alpha: 0.4),
                        onSelected: (_) {
                          setModalState(() => visibility = 'public');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Internal'),
                        selected: visibility == 'private',
                        selectedColor: AppColors.lilac.withValues(alpha: 0.4),
                        onSelected: (_) {
                          setModalState(() => visibility = 'private');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClayTextField(
                    controller: controller,
                    label: 'Apa kabar?',
                    placeholder: 'Edit postingan Anda...',
                  ),
                  const SizedBox(height: 20),
                  ClayButton(
                    color: AppColors.babyBlue,
                    onTap: () async {
                      if (controller.text.trim().isNotEmpty) {
                        final done = await ref
                            .read(feedProvider.notifier)
                            .updatePost(
                              post.id,
                              controller.text.trim(),
                              visibility: visibility,
                            );
                        if (done && context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                    child: Text(
                      'Simpan Perubahan',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreatePostSheet(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    String visibility = 'public';
    List<String> selectedFiles = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Buat Postingan Baru',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Visibilitas:',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Publik'),
                        selected: visibility == 'public',
                        selectedColor: AppColors.mint.withValues(alpha: 0.4),
                        onSelected: (_) {
                          setModalState(() => visibility = 'public');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Internal'),
                        selected: visibility == 'private',
                        selectedColor: AppColors.lilac.withValues(alpha: 0.4),
                        onSelected: (_) {
                          setModalState(() => visibility = 'private');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClayTextField(
                    controller: controller,
                    label: 'Apa kabar?',
                    placeholder:
                        'Ceritakan kejadian seru di kampus hari ini...',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          LucideIcons.image,
                          color: selectedFiles.isNotEmpty ? AppColors.babyBlue : AppColors.textMuted,
                        ),
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.any,
                            allowMultiple: true,
                          );
                          if (result != null) {
                            setModalState(() {
                              selectedFiles = result.paths.whereType<String>().toList();
                            });
                          }
                        },
                      ),
                      if (selectedFiles.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${selectedFiles.length} file',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 16),
                          onPressed: () {
                            setModalState(() => selectedFiles = []);
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  ClayButton(
                    color: AppColors.softPeach,
                    onTap: () async {
                      if (controller.text.trim().isNotEmpty) {
                        final done = await ref
                            .read(feedProvider.notifier)
                            .createPost(
                              controller.text.trim(),
                              visibility: visibility,
                              filePaths: selectedFiles.isNotEmpty ? selectedFiles : null,
                            );
                        if (context.mounted) {
                          Navigator.pop(context);
                          if (!done) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gagal mengirim postingan. Coba lagi.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: Text(
                      'Kirim Postingan',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCommentsDialog(BuildContext context, WidgetRef ref, int postId, int? currentUserId) {
    final commentController = TextEditingController();
    ref.read(feedProvider.notifier).loadComments(postId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final comments =
                ref.watch(feedProvider).commentsByPost[postId] ?? [];

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Komentar',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: comments.isEmpty
                          ? Center(
                              child: Text(
                                'Belum ada komentar. Jadilah yang pertama!',
                                style: GoogleFonts.outfit(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: comments.length,
                              itemBuilder: (context, index) {
                                final c = comments[index];
                                final isMyComment = currentUserId != null &&
                                    c.userId == currentUserId;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.lilac,
                                    backgroundImage: c.user['avatar'] != null
                                        ? NetworkImage(c.user['avatar'])
                                        : null,
                                    child: c.user['avatar'] == null
                                        ? const Icon(LucideIcons.user, size: 18)
                                        : null,
                                  ),
                                  title: Text(
                                    c.user['name'] ?? 'Mahasiswa',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(c.comment),
                                  trailing: isMyComment
                                      ? IconButton(
                                          icon: const Icon(
                                            LucideIcons.trash2,
                                            size: 18,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () {
                                            ref
                                                .read(feedProvider.notifier)
                                                .deletePostComment(
                                                  postId,
                                                  c.id,
                                                );
                                          },
                                        )
                                      : null,
                                );
                              },
                            ),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: ClayTextField(
                            controller: commentController,
                            label: 'Komentar baru',
                            placeholder: 'Tulis komentar Anda...',
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            LucideIcons.send,
                            color: AppColors.babyBlue,
                          ),
                          onPressed: () async {
                            if (commentController.text.trim().isNotEmpty) {
                              final ok = await ref
                                  .read(feedProvider.notifier)
                                  .addComment(
                                    postId,
                                    commentController.text.trim(),
                                  );
                              if (ok && context.mounted) {
                                commentController.clear();
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Gagal mengirim komentar.'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ==================== CHAT TAB ====================
class _ChatTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ClayButton(
            color: AppColors.babyBlue,
            onTap: () => _showUserSearchDialog(context, ref),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.plus, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Mulai Obrolan Baru',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: chatState.isLoading
              ? _buildShimmerLoader()
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(chatProvider.notifier).loadConversations(),
                  child: chatState.conversations.isEmpty
                      ? Center(
                          child: Text(
                            'Belum ada obrolan.',
                            style: GoogleFonts.outfit(
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: chatState.conversations.length,
                          itemBuilder: (context, index) {
                            final convo = chatState.conversations[index];
                            final lastMsgMap = convo.lastMessage;
                            String lastMsg = 'Belum ada pesan.';
                            if (lastMsgMap != null) {
                              final body = lastMsgMap['body']?.toString();
                              final type = lastMsgMap['message_type']?.toString();
                              if (type == 'image') {
                                lastMsg = '📷 Gambar';
                              } else if (type == 'file') {
                                lastMsg = '📁 File lampiran';
                              } else if (body != null && body.trim().isNotEmpty) {
                                lastMsg = body;
                              }
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () => context.push('/chat/${convo.id}'),
                                child: ClayContainer(
                                  color: Colors.white,
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppColors.lilac,
                                        backgroundImage: convo.avatar != null
                                            ? NetworkImage(convo.avatar!)
                                            : null,
                                        child: convo.avatar == null
                                            ? const Icon(
                                                LucideIcons.messageSquare,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              convo.name,
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textDark,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              lastMsg,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.outfit(
                                                color: AppColors.textMuted,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        LucideIcons.chevronRight,
                                        color: AppColors.textMuted,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }

  void _showUserSearchDialog(BuildContext context, WidgetRef ref) {
    final searchController = TextEditingController();
    List<dynamic> users = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Cari Pengguna',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClayTextField(
                          controller: searchController,
                          label: 'Username',
                          placeholder: 'Masukkan nama pengguna...',
                        ),
                      ),
                      const SizedBox(width: 8),
                      isSearching
                          ? const CircularProgressIndicator()
                          : IconButton(
                              icon: const Icon(
                                LucideIcons.search,
                                color: AppColors.babyBlue,
                              ),
                              onPressed: () async {
                                final text = searchController.text.trim();
                                if (text.isNotEmpty) {
                                  setModalState(() => isSearching = true);
                                  try {
                                    final response = await ref
                                        .read(apiProvider)
                                        .get(
                                          '/users/search',
                                          queryParameters: {'username': text},
                                        );
                                    if (response.data['success'] == true) {
                                      setModalState(() {
                                        users = response.data['data'];
                                        isSearching = false;
                                      });
                                    }
                                  } catch (_) {
                                    setModalState(() => isSearching = false);
                                  }
                                }
                              },
                            ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: users.isEmpty
                        ? Center(
                            child: Text(
                              'Masukkan username untuk mencari.',
                              style: GoogleFonts.outfit(
                                color: AppColors.textMuted,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final u = users[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.softPeach,
                                  backgroundImage: u['avatar'] != null
                                      ? NetworkImage(u['avatar'])
                                      : null,
                                  child: u['avatar'] == null
                                      ? const Icon(LucideIcons.user)
                                      : null,
                                ),
                                title: Text(u['name'] ?? 'Mahasiswa'),
                                subtitle: Text('@${u['username']}'),
                                trailing: IconButton(
                                  icon: const Icon(
                                    LucideIcons.messageSquare,
                                    color: AppColors.babyBlue,
                                  ),
                                  onPressed: () async {
                                    await ref
                                        .read(chatProvider.notifier)
                                        .startConversation(u['id']);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ==================== FORUM TAB ====================
class _ForumTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ForumTab> createState() => _ForumTabState();
}

class _ForumTabState extends ConsumerState<_ForumTab>
    with SingleTickerProviderStateMixin {
  late TabController _forumTabController;

  @override
  void initState() {
    super.initState();
    _forumTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _forumTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forumState = ref.watch(forumProvider);

    return Column(
      children: [
        // Tab switching header
        TabBar(
          controller: _forumTabController,
          labelColor: AppColors.textDark,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.mint,
          indicatorWeight: 3.0,
          tabs: const [
            Tab(text: 'Forum Saya'),
            Tab(text: 'Forum Publik'),
          ],
        ),

        // Create Forum Action
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ClayButton(
            color: AppColors.mint,
            onTap: () => _showCreateForumDialog(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.plus, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Buat Forum Baru',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _forumTabController,
            children: [
              _buildForumListView(forumState.myForums, isMyForums: true),
              _buildForumListView(forumState.publicForums, isMyForums: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForumListView(
    List<ForumModel> list, {
    required bool isMyForums,
  }) {
    final forumState = ref.watch(forumProvider);

    if (forumState.isLoading) return _buildShimmerLoader();

    if (forumState.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                'Gagal Memuat Forum',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                forumState.errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ClayButton(
                color: AppColors.mint,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                onTap: () {
                  ref.read(forumProvider.notifier).loadMyForums();
                  ref.read(forumProvider.notifier).loadPublicForums();
                },
                child: Text(
                  'Coba Lagi',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (list.isEmpty) {
      return Center(
        child: Text(
          isMyForums
              ? 'Anda belum bergabung dengan forum mana pun.'
              : 'Belum ada forum publik.',
          style: GoogleFonts.outfit(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final f = list[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: ClayContainer(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.name,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (f.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          f.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                isMyForums
                    ? ClayButton(
                        color: AppColors.babyBlue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        onTap: () => context.push('/forum/${f.id}'),
                        child: Text(
                          'Buka',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ClayButton(
                        color: AppColors.mint,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        onTap: () =>
                            ref.read(forumProvider.notifier).joinForum(f.id),
                        child: Text(
                          'Gabung',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateForumDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isPrivate = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Buat Forum Baru',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClayTextField(
                    controller: nameController,
                    label: 'Nama Forum',
                    placeholder: 'e.g. Mahasiswa Teknik Informatika',
                  ),
                  const SizedBox(height: 12),
                  ClayTextField(
                    controller: descController,
                    label: 'Deskripsi Forum',
                    placeholder:
                        'Tulis deskripsi singkat mengenai forum ini...',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Jenis Forum:',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Publik'),
                        selected: !isPrivate,
                        selectedColor: AppColors.mint.withValues(alpha: 0.4),
                        onSelected: (_) {
                          setModalState(() => isPrivate = false);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Privat'),
                        selected: isPrivate,
                        selectedColor: AppColors.lilac.withValues(alpha: 0.4),
                        onSelected: (_) {
                          setModalState(() => isPrivate = true);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ClayButton(
                    color: AppColors.mint,
                    onTap: () async {
                      if (nameController.text.trim().isNotEmpty) {
                        final ok = await ref
                            .read(forumProvider.notifier)
                            .createForum(
                              nameController.text.trim(),
                              descController.text.trim(),
                              isPrivate,
                            );
                        if (context.mounted) {
                          if (ok) {
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gagal membuat forum. Coba lagi.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: Text(
                      'Buat Forum',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ==================== NOTIFICATION TAB ====================
class _NotificationTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/notifications'),
                child: Text(
                  'Lihat Semua',
                  style: GoogleFonts.outfit(
                    color: AppColors.lilac,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (state.notifications.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClayButton(
              color: AppColors.lilac,
              onTap: () =>
                  ref.read(notificationProvider.notifier).markAllAsRead(),
              child: Text(
                'Tandai Semua Dibaca',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        Expanded(
          child: state.isLoading
              ? _buildShimmerLoader()
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(notificationProvider.notifier)
                      .loadNotifications(),
                  child: state.notifications.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada notifikasi.',
                            style: GoogleFonts.outfit(
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: state.notifications.length > 5
                              ? 5
                              : state.notifications.length,
                          itemBuilder: (context, index) {
                            final n = state.notifications[index];
                            final title = n.displayTitle;
                            final body = n.displayBody;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () {
                                  if (!n.isRead) {
                                    ref
                                        .read(notificationProvider.notifier)
                                        .markAsRead(n.id);
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
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: n.isRead
                                            ? Colors.grey[200]
                                            : AppColors.lilac,
                                        child: Icon(
                                          n.isRead
                                              ? LucideIcons.check
                                              : LucideIcons.bellRing,
                                          color: n.isRead
                                              ? Colors.grey
                                              : Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              body,
                                              style: GoogleFonts.outfit(
                                                color: AppColors.textMuted,
                                                fontSize: 13,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}

// Global Shimmer Indicator
Widget _buildShimmerLoader() {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: ListView.builder(
      itemCount: 4,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    ),
  );
}
