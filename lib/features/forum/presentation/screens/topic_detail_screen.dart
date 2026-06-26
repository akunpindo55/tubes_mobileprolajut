import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/clay_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/forum_provider.dart';

class TopicDetailScreen extends ConsumerStatefulWidget {
  final int topicId;

  const TopicDetailScreen({super.key, required this.topicId});

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  final _commentController = TextEditingController();
  int? _replyingToCommentId;
  String? _replyingToUsername;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(forumProvider.notifier).loadTopicDetail(widget.topicId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isNotEmpty) {
      final ok = await ref
          .read(forumProvider.notifier)
          .replyTopic(
            widget.topicId,
            text,
            parentCommentId: _replyingToCommentId,
          );
      if (ok && mounted) {
        _commentController.clear();
        setState(() {
          _replyingToCommentId = null;
          _replyingToUsername = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final forumState = ref.watch(forumProvider);
    final topic = forumState.topicDetails[widget.topicId];

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
          'Topik Diskusi',
          style: GoogleFonts.outfit(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: forumState.isLoading && topic == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.mint),
            )
          : topic == null
          ? Center(
              child: Text(
                'Topik tidak ditemukan.',
                style: GoogleFonts.outfit(color: AppColors.textMuted),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => ref
                        .read(forumProvider.notifier)
                        .loadTopicDetail(widget.topicId),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Main Topic Thread Header Card
                        ClayContainer(
                          color: Colors.white,
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: AppColors.softPeach,
                                    radius: 16,
                                    child: Icon(
                                      LucideIcons.user,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          topic.user['name'] ?? 'Mahasiswa',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        Text(
                                          '@${topic.user['username'] ?? 'username'}',
                                          style: GoogleFonts.outfit(
                                            color: AppColors.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                topic.title,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                topic.content,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  height: 1.45,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Replies Title Header
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'Semua Balasan',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),

                        // Threaded Comments
                        if (topic.comments == null || topic.comments!.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                'Belum ada tanggapan. Jadilah yang pertama menjawab!',
                                style: GoogleFonts.outfit(
                                  color: AppColors.textMuted,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        else
                          ...topic.comments!.map(
                            (comment) => _buildCommentNode(comment),
                          ),
                      ],
                    ),
                  ),
                ),

                // Reply Input Box at the bottom
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AppColors.border, width: 2),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_replyingToUsername != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppColors.lilac.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Membalas @$_replyingToUsername',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _replyingToCommentId = null;
                                      _replyingToUsername = null;
                                    });
                                  },
                                  child: const Icon(
                                    LucideIcons.x,
                                    size: 16,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _commentController,
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Tulis balasan Anda...',
                                  hintStyle: const TextStyle(
                                    color: AppColors.textMuted,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.background,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: AppColors.mint,
                                      width: 2.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ClayContainer(
                              color: AppColors.mint,
                              borderRadius: 16,
                              width: 48,
                              height: 48,
                              child: IconButton(
                                icon: const Icon(
                                  LucideIcons.send,
                                  color: AppColors.textDark,
                                  size: 20,
                                ),
                                onPressed: _submitComment,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCommentNode(ForumCommentModel comment, {double depth = 0}) {
    final currentUserId = ref.watch(authProvider).user?['id'] as int?;
    final isMyComment = currentUserId != null && comment.userId == currentUserId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: depth * 24.0, bottom: 12.0),
          child: ClayContainer(
            color: depth > 0
                ? AppColors.lilac.withValues(alpha: 0.08)
                : Colors.white,
            borderColor: depth > 0
                ? AppColors.lilac.withValues(alpha: 0.3)
                : AppColors.border,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.lilac,
                      radius: 12,
                      child: Icon(
                        LucideIcons.user,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        comment.user['name'] ?? 'Mahasiswa',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onLongPress: isMyComment
                          ? () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Hapus Komentar'),
                                  content: const Text(
                                    'Apakah Anda yakin ingin menghapus komentar ini?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(ctx);
                                        final ok = await ref
                                            .read(forumProvider.notifier)
                                            .deleteComment(comment.id);
                                        if (ok && mounted) {
                                          ref
                                              .read(forumProvider.notifier)
                                              .loadTopicDetail(widget.topicId);
                                        }
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                      ),
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          : null,
                      onTap: () {
                        setState(() {
                          _replyingToCommentId = comment.id;
                          _replyingToUsername =
                              comment.user['username'] ?? 'username';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.border,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isMyComment
                                  ? LucideIcons.trash2
                                  : LucideIcons.cornerUpLeft,
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isMyComment ? 'Hapus' : 'Balas',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  comment.content,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Recursive children replies representation
        if (comment.replies.isNotEmpty)
          ...comment.replies.map(
            (reply) => _buildCommentNode(reply, depth: depth + 1),
          ),
      ],
    );
  }
}
