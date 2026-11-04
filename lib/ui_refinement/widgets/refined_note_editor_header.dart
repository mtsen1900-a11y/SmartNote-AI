import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/note.dart';
import '../../services/file_exporter.dart';
import '../theme/refined_palette.dart';

/// Thanh công cụ trên cùng của trình soạn thảo - Đã tinh chỉnh chống tràn màn hình (Zero Overflow)
class RefinedNoteEditorHeader extends StatelessWidget {
  final Note note;
  final String savingStatus;
  final bool isPreviewMode;
  final bool aiPanelOpen;
  final VoidCallback onTogglePreview;
  final VoidCallback onOpenAi;
  final VoidCallback onEditTags;
  final VoidCallback onDelete;
  final VoidCallback? onOpenMenu;
  final VoidCallback? onBack;
  final VoidCallback? onOpenFlashcards;
  final VoidCallback? onTogglePin;
  final ValueChanged<String>? onFolderChanged;

  const RefinedNoteEditorHeader({
    super.key,
    required this.note,
    required this.savingStatus,
    required this.isPreviewMode,
    required this.aiPanelOpen,
    required this.onTogglePreview,
    required this.onOpenAi,
    required this.onEditTags,
    required this.onDelete,
    this.onOpenMenu,
    this.onBack,
    this.onOpenFlashcards,
    this.onTogglePin,
    this.onFolderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 640;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? RefinedPalette.darkSurface : RefinedPalette.surface,
            border: Border(
              bottom: BorderSide(
                color: isDark ? RefinedPalette.darkBorder : RefinedPalette.border,
              ),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 12 : 18,
            vertical: isNarrow ? 6 : 10,
          ),
          child: isNarrow ? _buildMobileLayout(context, isDark) : _buildDesktopLayout(context, isDark),
        );
      },
    );
  }

  /// Bố cục 2 dòng thông minh trên điện thoại: Không bao giờ bị tràn pixel
  Widget _buildMobileLayout(BuildContext context, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dòng 1: Điều hướng, Trạng thái lưu, và các nút Thao tác chính
        Row(
          children: [
            // Nút Menu, Nút Thoát ⬅️ và Nút Home 🏠
            if (onBack != null) ...[
              IconButton(
                tooltip: 'Quay lại',
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                onPressed: onBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              ),
              IconButton(
                tooltip: 'Về trang chủ',
                icon: const Icon(Icons.home_rounded, size: 20, color: RefinedPalette.primary),
                onPressed: onBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              ),
            ] else if (onOpenMenu != null)
              IconButton(
                tooltip: 'Mở danh sách',
                icon: const Icon(Icons.menu_rounded, size: 20),
                onPressed: onOpenMenu,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            const SizedBox(width: 4),

            // Trạng thái lưu
            _buildSavingStatusBadge(),

            const Spacer(),

            // Nút Ghim nhanh
            if (onTogglePin != null)
              IconButton(
                tooltip: note.isPinned ? 'Bỏ ghim' : 'Ghim',
                icon: Icon(
                  note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: note.isPinned ? RefinedPalette.warning : RefinedPalette.textMuted,
                  size: 19,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                onPressed: onTogglePin,
              ),

            // Nút Xem trước Markdown
            IconButton(
              tooltip: isPreviewMode ? 'Soạn thảo' : 'Xem trước',
              icon: Icon(
                isPreviewMode ? Icons.edit_outlined : Icons.visibility_outlined,
                color: isPreviewMode ? RefinedPalette.primary : RefinedPalette.textSecondary,
                size: 19,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              onPressed: onTogglePreview,
            ),

            // Nút menu phụ (Flashcard, Xóa)
            PopupMenuButton<String>(
              tooltip: 'Tác vụ khác',
              icon: const Icon(Icons.more_vert, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 34),
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'copy',
                  child: Row(
                    children: [
                      Icon(Icons.copy_rounded, size: 16),
                      SizedBox(width: 8),
                      Text('Sao chép nội dung'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export_md',
                  child: Row(
                    children: [
                      Icon(Icons.download_rounded, size: 16),
                      SizedBox(width: 8),
                      Text('Tải tệp Markdown (.md)'),
                    ],
                  ),
                ),
                if (onOpenFlashcards != null)
                  const PopupMenuItem(
                    value: 'flashcards',
                    child: Row(
                      children: [
                        Icon(Icons.style_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('Ôn tập Flashcards'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 16, color: RefinedPalette.danger),
                      SizedBox(width: 8),
                      Text('Chuyển vào Thùng rác', style: TextStyle(color: RefinedPalette.danger)),
                    ],
                  ),
                ),
              ],
              onSelected: (val) {
                if (val == 'copy') {
                  Clipboard.setData(ClipboardData(text: '${note.title}\n\n${note.content}'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('✅ Đã sao chép nội dung ghi chú!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
                if (val == 'export_md') {
                  final safeTitle = (note.title.trim().isEmpty ? 'ghi_chu' : note.title.trim())
                      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
                  exportTextFile('$safeTitle.md', '# ${note.title}\n\n${note.content}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('✅ Đã tải về "$safeTitle.md"!'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
                if (val == 'flashcards') onOpenFlashcards?.call();
                if (val == 'delete') onDelete();
              },
            ),
            const SizedBox(width: 4),

            // Nút AI nhỏ gọn
            FilledButton.tonal(
              onPressed: onOpenAi,
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: const Size(0, 30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 13),
                  SizedBox(width: 3),
                  Text('AI', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Dòng 2: Thư mục + Danh sách thẻ cuộn ngang + Số từ (Không bao giờ bị tràn)
        SizedBox(
          height: 28,
          child: Row(
            children: [
              // Thư mục ghi chú
              if (onFolderChanged != null) ...[
                PopupMenuButton<String>(
                  tooltip: 'Chọn thư mục',
                  initialValue: note.folder,
                  onSelected: onFolderChanged,
                  itemBuilder: (ctx) => [
                    for (final f in ['Cá nhân', 'Công việc', 'Học tập', 'Dự án', 'Ý tưởng'])
                      PopupMenuItem(value: f, child: Text(f)),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF312E81) : RefinedPalette.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? const Color(0xFF4338CA) : const Color(0xFFC7D2FE),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.folder_outlined, size: 11, color: RefinedPalette.primary),
                        const SizedBox(width: 3),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 75),
                          child: Text(
                            note.folder,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : RefinedPalette.primaryDark,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 13, color: RefinedPalette.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],

              // Danh sách thẻ cuộn ngang
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final tag in note.tags)
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : RefinedPalette.surfaceSecondary,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : RefinedPalette.borderSubtle,
                            ),
                          ),
                          child: Text('#$tag', style: const TextStyle(fontSize: 10.5, color: RefinedPalette.textSecondary)),
                        ),
                      ),
                    InkWell(
                      onTap: onEditTags,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: RefinedPalette.primary.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 11, color: RefinedPalette.primary),
                            SizedBox(width: 2),
                            Text('Thẻ', style: TextStyle(fontSize: 10.5, color: RefinedPalette.primary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${note.wordCount} từ',
                style: const TextStyle(fontSize: 10.5, color: RefinedPalette.textMuted, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Bố cục Desktop rộng rãi, thanh lịch
  Widget _buildDesktopLayout(BuildContext context, bool isDark) {
    return Row(
      children: [
        if (onBack != null) ...[
          IconButton(
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            onPressed: onBack,
          ),
          IconButton(
            tooltip: 'Về trang chủ',
            icon: const Icon(Icons.home_rounded, size: 20, color: RefinedPalette.primary),
            onPressed: onBack,
          ),
          const SizedBox(width: 4),
        ] else if (onOpenMenu != null) ...[
          IconButton(
            tooltip: 'Mở danh sách',
            icon: const Icon(Icons.menu_rounded, size: 20),
            onPressed: onOpenMenu,
          ),
          const SizedBox(width: 4),
        ],

        _buildSavingStatusBadge(),
        const SizedBox(width: 10),

        Text(
          '${note.wordCount} từ',
          style: const TextStyle(fontSize: 12, color: RefinedPalette.textMuted, fontFamily: 'monospace'),
        ),
        const SizedBox(width: 12),

        // Thư mục
        if (onFolderChanged != null)
          PopupMenuButton<String>(
            tooltip: 'Chọn thư mục',
            initialValue: note.folder,
            onSelected: onFolderChanged,
            itemBuilder: (ctx) => [
              for (final f in ['Cá nhân', 'Công việc', 'Học tập', 'Dự án', 'Ý tưởng'])
                PopupMenuItem(value: f, child: Text(f)),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF312E81) : RefinedPalette.primaryLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: RefinedPalette.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder_outlined, size: 12, color: RefinedPalette.primary),
                  const SizedBox(width: 4),
                  Text(
                    note.folder,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : RefinedPalette.primaryDark,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 14, color: RefinedPalette.primary),
                ],
              ),
            ),
          ),
        const SizedBox(width: 8),

        // Danh sách thẻ (Cuộn ngang an toàn, không bao giờ bị tràn)
        Flexible(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final tag in note.tags)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : RefinedPalette.surfaceSecondary,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : RefinedPalette.border),
                      ),
                      child: Text('#$tag', style: const TextStyle(fontSize: 11, color: RefinedPalette.textSecondary)),
                    ),
                  ),
                InkWell(
                  onTap: onEditTags,
                  borderRadius: BorderRadius.circular(6),
                  child: const Tooltip(
                    message: 'Chỉnh sửa thẻ',
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.add_circle_outline, size: 17),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const Spacer(),

        // Ghim
        if (onTogglePin != null)
          IconButton(
            tooltip: note.isPinned ? 'Bỏ ghim' : 'Ghim ghi chú',
            icon: Icon(
              note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: note.isPinned ? RefinedPalette.warning : RefinedPalette.textMuted,
              size: 20,
            ),
            onPressed: onTogglePin,
          ),

        // Preview
        IconButton(
          tooltip: isPreviewMode ? 'Soạn thảo' : 'Xem trước Markdown',
          icon: Icon(
            isPreviewMode ? Icons.edit_outlined : Icons.visibility_outlined,
            color: isPreviewMode ? RefinedPalette.primary : RefinedPalette.textSecondary,
            size: 20,
          ),
          onPressed: onTogglePreview,
        ),

        // Flashcards
        if (onOpenFlashcards != null)
          IconButton(
            tooltip: 'Học Flashcards',
            icon: const Icon(Icons.style_outlined, color: RefinedPalette.warning, size: 20),
            onPressed: onOpenFlashcards,
          ),

        // Sao chép nội dung
        IconButton(
          tooltip: 'Sao chép nội dung',
          icon: const Icon(Icons.copy_rounded, color: RefinedPalette.textSecondary, size: 19),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: '${note.title}\n\n${note.content}'));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('✅ Đã sao chép nội dung ghi chú!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),

        // Tải file Markdown (.md)
        IconButton(
          tooltip: 'Tải tệp Markdown (.md)',
          icon: const Icon(Icons.download_rounded, color: RefinedPalette.textSecondary, size: 19),
          onPressed: () {
            final safeTitle = (note.title.trim().isEmpty ? 'ghi_chu' : note.title.trim())
                .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
            exportTextFile('$safeTitle.md', '# ${note.title}\n\n${note.content}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('✅ Đã tải về "$safeTitle.md"!'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),

        // Xóa
        IconButton(
          tooltip: 'Chuyển vào Thùng rác',
          icon: const Icon(Icons.delete_outline, color: RefinedPalette.danger, size: 20),
          onPressed: onDelete,
        ),

        const SizedBox(width: 4),

        // AI Panel button
        FilledButton.tonalIcon(
          onPressed: onOpenAi,
          icon: const Icon(Icons.auto_awesome, size: 16),
          label: const Text('AI Assistant'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildSavingStatusBadge() {
    final isSaving = savingStatus == 'Đang lưu...';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSaving ? RefinedPalette.warningLight : RefinedPalette.successLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSaving ? Icons.sync : Icons.check_circle_outline,
            size: 11,
            color: isSaving ? RefinedPalette.warning : RefinedPalette.success,
          ),
          const SizedBox(width: 3),
          Text(
            savingStatus,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isSaving ? RefinedPalette.warning : RefinedPalette.success,
            ),
          ),
        ],
      ),
    );
  }
}
