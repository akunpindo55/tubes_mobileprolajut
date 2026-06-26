import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/clay_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/forum_provider.dart';

class ForumDetailScreen extends ConsumerStatefulWidget {
  final int forumId;

  const ForumDetailScreen({super.key, required this.forumId});

  @override
  ConsumerState<ForumDetailScreen> createState() => _ForumDetailScreenState();
}

class _ForumDetailScreenState extends ConsumerState<ForumDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(forumProvider.notifier).loadTopics(widget.forumId);
    });
  }

  void _showInviteUserDialog() {
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
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
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
                    'Undang Anggota',
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
                          label: 'Cari pengguna',
                          placeholder: 'Masukkan username...',
                        ),
                      ),
                      const SizedBox(width: 8),
                      isSearching
                          ? const CircularProgressIndicator()
                          : IconButton(
                              icon: const Icon(
                                LucideIcons.search,
                                color: AppColors.mint,
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
                              'Cari pengguna untuk diundang.',
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
                                  backgroundColor: AppColors.mint,
                                  backgroundImage: u['avatar'] != null
                                      ? NetworkImage(u['avatar'])
                                      : null,
                                  child: u['avatar'] == null
                                      ? const Icon(LucideIcons.user)
                                      : null,
                                ),
                                title: Text(u['name'] ?? ''),
                                subtitle: Text('@${u['username']}'),
                                trailing: IconButton(
                                  icon: const Icon(
                                    LucideIcons.userPlus,
                                    color: AppColors.mint,
                                  ),
                                  onPressed: () async {
                                    await ref
                                        .read(forumProvider.notifier)
                                        .inviteMember(
                                          widget.forumId,
                                          u['id'],
                                        );
                                    if (ctx.mounted) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Anggota berhasil diundang!',
                                          ),
                                        ),
                                      );
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

  void _showCreateTopicDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
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
                'Buat Diskusi Baru',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              ClayTextField(
                controller: titleController,
                label: 'Judul Topik',
                placeholder: 'e.g. Info Buku Referensi Semester 3',
              ),
              const SizedBox(height: 12),
              ClayTextField(
                controller: contentController,
                label: 'Isi Diskusi',
                placeholder: 'Tulis detail pertanyaan atau pembahasan Anda...',
              ),
              const SizedBox(height: 20),
              ClayButton(
                color: AppColors.mint,
                onTap: () async {
                  if (titleController.text.trim().isNotEmpty &&
                      contentController.text.trim().isNotEmpty) {
                    final ok = await ref
                        .read(forumProvider.notifier)
                        .createTopic(
                          widget.forumId,
                          titleController.text.trim(),
                          contentController.text.trim(),
                        );
                    if (ok && context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                child: Text(
                  'Buat Topik',
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
    final forumState = ref.watch(forumProvider);

    // Find current forum in lists
    final myForums = forumState.myForums;
    final publicForums = forumState.publicForums;
    final forum = [...myForums, ...publicForums].firstWhere(
      (f) => f.id == widget.forumId,
      orElse: () => ForumModel(
        id: widget.forumId,
        name: 'Detail Forum',
        isPrivate: false,
        createdBy: 0,
        createdAt: '',
      ),
    );

    final topics = forumState.topicsByForum[widget.forumId] ?? [];

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
          forum.name,
          style: GoogleFonts.outfit(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.userPlus, color: AppColors.mint),
            onPressed: _showInviteUserDialog,
            tooltip: 'Undang Anggota',
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: Colors.redAccent),
            onPressed: () async {
              final navigator = GoRouter.of(context);
              final ok = await ref
                  .read(forumProvider.notifier)
                  .leaveForum(widget.forumId);
              if (ok && mounted) {
                navigator.pop();
              }
            },
            tooltip: 'Keluar Forum',
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner/Header Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ClayContainer(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Forum Diskusi',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      fontSize: 16,
                    ),
                  ),
                  if (forum.description != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      forum.description!,
                      style: GoogleFonts.outfit(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Search or Quick CTA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClayButton(
              color: AppColors.mint,
              onTap: _showCreateTopicDialog,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.plus, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Mulai Topik Diskusi Baru',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Discussion Topics list
          Expanded(
            child: forumState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.mint),
                  )
                : topics.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada topik diskusi. Yuk buat!',
                      style: GoogleFonts.outfit(color: AppColors.textMuted),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref
                        .read(forumProvider.notifier)
                        .loadTopics(widget.forumId),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: topics.length,
                      itemBuilder: (context, index) {
                        final topic = topics[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onLongPress: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Hapus Topik'),
                                  content: const Text(
                                    'Apakah Anda yakin ingin menghapus topik ini?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(ctx);
                                        await ref
                                            .read(forumProvider.notifier)
                                            .deleteTopic(topic.id);
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                      ),
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onTap: () => context.push('/topic/${topic.id}'),
                            child: ClayContainer(
                              color: Colors.white,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    topic.title,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    topic.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.user,
                                        size: 14,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        topic.user['name'] ?? 'Mahasiswa',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        LucideIcons.chevronRight,
                                        size: 16,
                                        color: AppColors.textMuted,
                                      ),
                                    ],
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
      ),
    );
  }
}
