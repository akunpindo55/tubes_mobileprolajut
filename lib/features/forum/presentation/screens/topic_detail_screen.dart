import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
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
  String? _selectedFilePath;
  bool _isSubmitting = false;

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
    if (text.isEmpty && _selectedFilePath == null) return;
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final ok = await ref
        .read(forumProvider.notifier)
        .replyTopic(
          widget.topicId,
          text,
          parentCommentId: _replyingToCommentId,
          filePath: _selectedFilePath,
        );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      if (ok) {
        _commentController.clear();
        setState(() {
          _replyingToCommentId = null;
          _replyingToUsername = null;
          _selectedFilePath = null;
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
          ? _buildTopicShimmerLoader()
          : forumState.errorMessage != null && topic == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.alertCircle, color: Colors.redAccent, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'Gagal memuat detail topik:',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      forumState.errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ClayButton(
                      color: AppColors.mint,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      onTap: () => ref
                          .read(forumProvider.notifier)
                          .loadTopicDetail(widget.topicId),
                      child: Text(
                        'Coba Lagi',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
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
                               if (topic.fileUrl != null) ...[
                                 const SizedBox(height: 12),
                                 _buildMessageFilePreview(topic.fileUrl!),
                               ],
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
                        if (_selectedFilePath != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.paperclip, size: 14, color: AppColors.lilac),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _selectedFilePath!.split('/').last,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _selectedFilePath = null),
                                  child: const Icon(LucideIcons.x, size: 14, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                LucideIcons.paperclip,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                              onPressed: () async {
                                final result = await FilePicker.platform.pickFiles(
                                  type: FileType.any,
                                );
                                if (result != null && result.files.single.path != null) {
                                  setState(() {
                                    _selectedFilePath = result.files.single.path;
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 4),
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
                              child: _isSubmitting
                                  ? const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: AppColors.textDark,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : IconButton(
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
                 if (comment.fileUrl != null) ...[
                   const SizedBox(height: 8),
                   _buildMessageFilePreview(comment.fileUrl!),
                 ],
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

  Widget _buildTopicShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Main Thread Skeleton Card
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 24),
          // Comments Header
          Container(
            width: 120,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          // Comments list skeleton
          ...List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
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
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageFilePreview(String url) {
    final isImage = RegExp(r'\.(jpe?g|png|gif|bmp|webp)$', caseSensitive: false).hasMatch(url);
    final fileName = url.split('/').last;

    if (isImage) {
      return GestureDetector(
        onTap: () => _showImagePreview(context, url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: 200,
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFilePlaceholder(fileName),
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: () async {
          try {
            final tempDir = await getTemporaryDirectory();
            final file = File('${tempDir.path}/$fileName');

            final dio = Dio();
            final response = await dio.get(
              url,
              options: Options(responseType: ResponseType.bytes),
            );

            if (response.data != null) {
              await file.writeAsBytes(response.data as List<int>);
            } else {
              throw Exception('Data kosong');
            }

            if (context.mounted) {
              await showModalBottomSheet(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(fileName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        const Divider(),
                        ListTile(
                          leading: const Icon(LucideIcons.download, color: AppColors.lilac),
                          title: const Text('Buka dengan aplikasi terkait'),
                          onTap: () async {
                            final openResult = await OpenFilex.open(file.path);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (openResult.type != ResultType.done && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gagal membuka file: ${openResult.message}')),
                              );
                            }
                          },
                        ),
                        ListTile(
                          leading: const Icon(LucideIcons.copy, color: AppColors.lilac),
                          title: const Text('Salin URL'),
                          onTap: () async {
                            await Clipboard.setData(ClipboardData(text: url));
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('URL tersalin!')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(fileName),
                  content: Text('Gagal mengunduh file: $e'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
                  ],
                ),
              );
            }
          }
        },
        child: _buildFilePlaceholder(fileName),
      );
    }
  }

  Widget _buildFilePlaceholder(String fileName) {
    return Container(
      width: 200,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.file, size: 24, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppColors.textDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
