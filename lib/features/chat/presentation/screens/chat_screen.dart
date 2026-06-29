import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/clay_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final int conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  int? _replyingToMessageId;
  String? _replyingToBody;
  String? _selectedFilePath;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(chatProvider.notifier).loadMessages(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
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
                    'Undang Pengguna',
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
                                  backgroundColor: AppColors.babyBlue,
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
                                    color: AppColors.babyBlue,
                                  ),
                                  onPressed: () async {
                                    await ref
                                        .read(chatProvider.notifier)
                                        .inviteUser(
                                          widget.conversationId,
                                          u['id'],
                                        );
                                    if (ctx.mounted) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Pengguna berhasil diundang!',
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

  void _send() {
    final body = _textController.text.trim();
    final currentUserId = ref.read(authProvider).user?['id'] as int?;

    if (body.isNotEmpty || _selectedFilePath != null) {
      ref.read(chatProvider.notifier).sendMessage(
        widget.conversationId,
        body,
        replyTo: _replyingToMessageId,
        senderId: currentUserId,
        filePath: _selectedFilePath,
      );
      _textController.clear();
      setState(() {
        _replyingToMessageId = null;
        _replyingToBody = null;
        _selectedFilePath = null;
      });
    }
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
      // Handle non-image files
      final fileName = url.split('/').last;

      return GestureDetector(
        onTap: () async {
          try {
            // Download file
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

            // Show options: Open with installed app or Copy URL
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
                          leading: const Icon(LucideIcons.download, color: AppColors.babyBlue),
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
                          leading: const Icon(LucideIcons.copy, color: AppColors.babyBlue),
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
          Flexible(
            child: Text(
              fileName,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?['id'] as int?;

    final conversation = chatState.conversations.firstWhere(
      (c) => c.id == widget.conversationId,
      orElse: () => ConversationModel(
        id: widget.conversationId,
        name: 'Pesan Langsung',
        type: 'direct',
      ),
    );

    final messages =
        chatState.messagesByConversation[widget.conversationId] ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.babyBlue,
              radius: 18,
              backgroundImage: conversation.avatar != null
                  ? NetworkImage(conversation.avatar!)
                  : null,
              child: conversation.avatar == null
                  ? const Icon(LucideIcons.user, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                conversation.name,
                style: GoogleFonts.outfit(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical, color: AppColors.textDark),
            onSelected: (value) async {
              if (value == 'invite') {
                _showInviteUserDialog();
              } else if (value == 'leave') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Keluar dari Obrolan'),
                    content: const Text(
                      'Apakah Anda yakin ingin keluar dari obrolan ini?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                        ),
                        child: const Text('Keluar'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await ref
                      .read(chatProvider.notifier)
                      .leaveConversation(widget.conversationId);
                  if (mounted) context.pop();
                }
              } else if (value == 'destroy') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hapus Obrolan'),
                    content: const Text(
                      'Apakah Anda yakin ingin menghapus obrolan ini untuk Anda?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                        ),
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await ref
                      .read(chatProvider.notifier)
                      .destroyConversation(widget.conversationId);
                  if (mounted) context.pop();
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'invite',
                child: ListTile(
                  leading: Icon(LucideIcons.userPlus, color: AppColors.textDark),
                  title: Text('Undang Pengguna'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const PopupMenuItem(
                value: 'leave',
                child: ListTile(
                  leading: Icon(LucideIcons.logOut, color: Colors.redAccent),
                  title: Text('Keluar', style: TextStyle(color: Colors.redAccent)),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const PopupMenuItem(
                value: 'destroy',
                child: ListTile(
                  leading: Icon(LucideIcons.trash2, color: Colors.redAccent),
                  title: Text('Hapus untuk Saya', style: TextStyle(color: Colors.redAccent)),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.isLoading && messages.isEmpty
                ? _buildChatShimmerLoader()
                : messages.isEmpty
                ? Center(
                    child: Text(
                      'Kirim pesan pertama Anda!',
                      style: GoogleFonts.outfit(color: AppColors.textMuted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == currentUserId;
                      return _buildMessageBubble(msg, isMe, currentUserId);
                    },
                  ),
          ),

          // Reply indicator
          if (_replyingToBody != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.lilac, width: 2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.cornerUpLeft, size: 16, color: AppColors.lilac),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Membalas pesan',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.lilac,
                          ),
                        ),
                        Text(
                          _replyingToBody!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 16, color: AppColors.textMuted),
                    onPressed: () {
                      setState(() {
                        _replyingToMessageId = null;
                        _replyingToBody = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 2),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedFilePath != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.paperclip, size: 14, color: AppColors.babyBlue),
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
                          IconButton(
                            icon: const Icon(LucideIcons.x, size: 14, color: AppColors.textMuted),
                            onPressed: () => setState(() => _selectedFilePath = null),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
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
                          controller: _textController,
                          style: const TextStyle(color: AppColors.textDark),
                          decoration: InputDecoration(
                            hintText: _replyingToBody != null ? 'Balas pesan...' : 'Ketik pesan...',
                            hintStyle: const TextStyle(color: AppColors.textMuted),
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
                                color: AppColors.babyBlue,
                                width: 2.5,
                              ),
                            ),
                          ),
                          onFieldSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ClayContainer(
                        color: AppColors.babyBlue,
                        borderRadius: 16,
                        width: 48,
                        height: 48,
                        child: IconButton(
                          icon: const Icon(
                            LucideIcons.send,
                            color: AppColors.textDark,
                            size: 20,
                          ),
                          onPressed: _send,
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

  Widget _buildMessageBubble(MessageModel msg, bool isMe, int? currentUserId) {
    final bubbleColor = isMe ? AppColors.babyBlue : Colors.white;
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final margin = isMe
        ? const EdgeInsets.only(left: 60)
        : const EdgeInsets.only(right: 60);

    final bool isReadByOthers = isMe && msg.reads.any((r) => r['user_id'] != currentUserId);
    final String? replyBody = msg.replyToMessage?['body'];

    return Column(
      crossAxisAlignment: alignment,
      children: [
        // Swipe to reply / long press to delete
        Dismissible(
          key: ValueKey('msg_${msg.id}'),
          direction: isMe ? DismissDirection.endToStart : DismissDirection.startToEnd,
          onDismissed: (_) {
            setState(() {
              _replyingToMessageId = msg.id;
              _replyingToBody = msg.body;
            });
          },
          confirmDismiss: (_) async {
            setState(() {
              _replyingToMessageId = msg.id;
              _replyingToBody = msg.body;
            });
            return false;
          },
          background: Container(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.cornerUpLeft, color: AppColors.lilac, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Balas',
                  style: GoogleFonts.outfit(
                    color: AppColors.lilac,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          child: GestureDetector(
            onLongPress: isMe
                ? () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Hapus Pesan'),
                        content: const Text(
                          'Apakah Anda yakin ingin menghapus pesan ini?',
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
                                  .read(chatProvider.notifier)
                                  .deleteMessage(
                                    widget.conversationId,
                                    msg.id,
                                  );
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
            child: Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isMe) ...[
                  const CircleAvatar(
                    backgroundColor: AppColors.lilac,
                    radius: 14,
                    child: Icon(LucideIcons.user, size: 12, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Container(
                    margin: margin + const EdgeInsets.symmetric(vertical: 4),
                    child: ClayContainer(
                      color: bubbleColor,
                      borderRadius: 18,
                      borderWidth: 2.5,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reply preview
                          if (replyBody != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: AppColors.lilac.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border(
                                  left: BorderSide(
                                    color: AppColors.lilac,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Text(
                                replyBody,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                          if (msg.fileUrl != null) ...[
                            _buildMessageFilePreview(msg.fileUrl!),
                            const SizedBox(height: 6),
                          ],
                          Text(
                            msg.body ?? '',
                            style: GoogleFonts.outfit(
                              color: AppColors.textDark,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Timestamp + read receipt + sending indicator
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (msg.isSending)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              Text(
                                _formatTime(msg.createdAt),
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              if (isMe && !msg.isSending) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  isReadByOthers
                                      ? LucideIcons.checkCheck
                                      : LucideIcons.check,
                                  size: 14,
                                  color: isReadByOthers
                                      ? AppColors.babyBlue
                                      : AppColors.textMuted,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        reverse: true,
        itemCount: 6,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final isMe = index % 2 == 0;
          final bubbleWidth = isMe ? 200.0 : 150.0;
          final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
          return Align(
            alignment: alignment,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isMe) ...[
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 14,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    width: bubbleWidth,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return '';
    }
  }
}
