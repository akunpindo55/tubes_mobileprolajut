import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/clay_widgets.dart';
import '../providers/report_provider.dart';

class ReportScreen extends ConsumerStatefulWidget {
  final String reportableType;
  final int reportableId;
  final String? targetName;

  const ReportScreen({
    super.key,
    required this.reportableType,
    required this.reportableId,
    this.targetName,
  });

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  String? _selectedReason;
  final _descriptionController = TextEditingController();

  static const List<Map<String, String>> _reasons = [
    {'value': 'spam', 'label': 'Spam'},
    {'value': 'harassment', 'label': 'Pelecehan'},
    {'value': 'inappropriate', 'label': 'Konten Tidak Pantas'},
    {'value': 'misinformation', 'label': 'Informasi Palsu'},
    {'value': 'other', 'label': 'Lainnya'},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);

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
          'Laporkan',
          style: GoogleFonts.outfit(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClayContainer(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Laporkan ${widget.targetName ?? widget.reportableType}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pilih alasan mengapa Anda melaporkan konten ini.',
                  style: GoogleFonts.outfit(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Alasan Pelaporan',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          ..._reasons.map((reason) {
            final isSelected = _selectedReason == reason['value'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClayContainer(
                color: isSelected
                    ? AppColors.softPeach.withValues(alpha: 0.2)
                    : Colors.white,
                borderColor: isSelected
                    ? AppColors.softPeach
                    : AppColors.border,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: RadioListTile<String>(
                  value: reason['value']!,
                  groupValue: _selectedReason,
                  onChanged: (value) {
                    setState(() => _selectedReason = value);
                  },
                  title: Text(
                    reason['label']!,
                    style: GoogleFonts.outfit(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  activeColor: AppColors.softPeach,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            );
          }),
          if (_selectedReason == 'other') ...[
            const SizedBox(height: 12),
            ClayTextField(
              controller: _descriptionController,
              label: 'Deskripsi',
              placeholder: 'Jelaskan alasan Anda secara detail...',
            ),
          ],
          const SizedBox(height: 24),
          ClayButton(
            color: AppColors.softPeach,
            onTap: () {
              if (_selectedReason == null) return;
              ref.read(reportProvider.notifier).submitReport(
                reportableType: widget.reportableType,
                reportableId: widget.reportableId,
                reason: _selectedReason!,
                description: _descriptionController.text.trim(),
              ).then((ok) {
                if (ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Laporan berhasil dikirim!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  if (mounted) context.pop();
                }
              });
            },
            child: reportState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Kirim Laporan',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
