import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../core/app_theme.dart';
import '../models/note.dart';
import '../ui_refinement/widgets/refined_note_editor_header.dart';

class NoteEditor extends StatefulWidget {
  const NoteEditor({
    super.key,
    required this.note,
    required this.titleController,
    required this.contentController,
    required this.onTitleChanged,
    required this.onContentChanged,
    required this.onDelete,
    required this.onOpenAi,
    required this.onEditTags,
    required this.onCreateNote,
    this.onOpenMenu,
    this.onBack,
    this.onOpenFlashcards,
    this.onTogglePin,
    this.onFolderChanged,
    this.aiPanelOpen = false,
    this.savingStatus = 'Đã lưu',
  });

  final Note? note;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onContentChanged;
  final VoidCallback onDelete;
  final VoidCallback onOpenAi;
  final VoidCallback onEditTags;
  final VoidCallback onCreateNote;
  final VoidCallback? onOpenMenu;
  final VoidCallback? onBack;
  final VoidCallback? onOpenFlashcards;
  final VoidCallback? onTogglePin;
  final ValueChanged<String>? onFolderChanged;
  final bool aiPanelOpen;
  final String savingStatus;

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  bool _isPreviewMode = false;

  void _insertFormatting(String prefix, {String suffix = '', String defaultPlaceholder = ''}) {
    final text = widget.contentController.text;
    final selection = widget.contentController.selection;
    if (selection.start < 0) {
      final insertText = defaultPlaceholder.isNotEmpty
          ? '\n$prefix$defaultPlaceholder$suffix'
          : '\n$prefix$suffix';
      final newText = text + insertText;
      widget.contentController.text = newText;
      widget.contentController.selection = TextSelection.collapsed(offset: newText.length);
      widget.onContentChanged(newText);
      return;
    }

    if (selection.isCollapsed) {
      if (defaultPlaceholder.isNotEmpty) {
        final newText = text.replaceRange(selection.start, selection.end, '$prefix$defaultPlaceholder$suffix');
        widget.contentController.text = newText;
        widget.contentController.selection = TextSelection(
          baseOffset: selection.start + prefix.length,
          extentOffset: selection.start + prefix.length + defaultPlaceholder.length,
        );
        widget.onContentChanged(newText);
        return;
      }
    }

    final selectedText = selection.textInside(text);
    final newText = text.replaceRange(selection.start, selection.end, '$prefix$selectedText$suffix');
    widget.contentController.text = newText;
    widget.contentController.selection = TextSelection.collapsed(
      offset: selection.start + prefix.length + selectedText.length + suffix.length,
    );
    widget.onContentChanged(newText);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.note == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.note_add_outlined, size: 48, color: AppColors.muted),
            const SizedBox(height: 16),
            const Text('Chưa có ghi chú nào.'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: widget.onCreateNote,
              icon: const Icon(Icons.add),
              label: const Text('Tạo ghi chú mới'),
            ),
          ],
        ),
      );
    }
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          // Top action bar (Refined & Zero Overflow)
          RefinedNoteEditorHeader(
            note: widget.note!,
            savingStatus: widget.savingStatus,
            isPreviewMode: _isPreviewMode,
            aiPanelOpen: widget.aiPanelOpen,
            onTogglePreview: () => setState(() => _isPreviewMode = !_isPreviewMode),
            onOpenAi: widget.onOpenAi,
            onEditTags: widget.onEditTags,
            onDelete: widget.onDelete,
            onOpenMenu: widget.onOpenMenu,
            onBack: widget.onBack,
            onOpenFlashcards: widget.onOpenFlashcards,
            onTogglePin: widget.onTogglePin,
            onFolderChanged: widget.onFolderChanged,
          ),

          // Trạng thái Loading / Saving siêu mỏng (2px)
          if (widget.savingStatus == 'Đang lưu...')
            const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),

          // Thanh công cụ định dạng Markdown nhanh & AI Chips (Hỗ trợ kéo chuột & phím tắt)
          if (!_isPreviewMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFBFD),
                border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
              ),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                  },
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  child: Row(
                    children: [
                      _formatBtn('✨ Trợ lý AI', widget.onOpenAi, isHighlight: true),
                      _formatBtn('☑️ Checklist', () => _insertFormatting('- [ ] ', defaultPlaceholder: 'Mục việc cần làm')),
                      _formatBtn('🪄 Tóm tắt ý', () => _insertFormatting('> **Tóm tắt:**\n> ', defaultPlaceholder: 'Ý chính')),
                      _formatBtn('H1', () => _insertFormatting('# ', defaultPlaceholder: 'Tiêu đề 1')),
                      _formatBtn('H2', () => _insertFormatting('## ', defaultPlaceholder: 'Tiêu đề 2')),
                      _formatBtn('B', () => _insertFormatting('**', suffix: '**', defaultPlaceholder: 'in đậm'), isBold: true),
                      _formatBtn('I', () => _insertFormatting('*', suffix: '*', defaultPlaceholder: 'in nghiêng'), isItalic: true),
                      _formatBtn('• Bullet', () => _insertFormatting('- ', defaultPlaceholder: 'Mục danh sách')),
                      _formatBtn('</> Code', () => _insertFormatting('```\n', suffix: '\n```', defaultPlaceholder: '// Code')),
                      _formatBtn('"" Trích dẫn', () => _insertFormatting('> ', defaultPlaceholder: 'Trích dẫn')),
                    ],
                  ),
                ),
              ),
            ),

          // Content body (Editor or Markdown Preview)
          Expanded(
            child: _isPreviewMode
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.titleController.text.isEmpty ? 'Chưa có tiêu đề' : widget.titleController.text,
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.3),
                            ),
                            const Divider(height: 32),
                            MarkdownBody(
                              data: widget.contentController.text.isEmpty
                                  ? '*(Chưa có nội dung)*'
                                  : widget.contentController.text,
                              selectable: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final contentPadding = constraints.maxWidth < 600 ? 20.0 : 48.0;
                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          contentPadding,
                          constraints.maxWidth < 600 ? 24 : 36,
                          contentPadding,
                          80,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 840),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: widget.titleController,
                                  onChanged: widget.onTitleChanged,
                                  minLines: 1,
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  textCapitalization: TextCapitalization.sentences,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: constraints.maxWidth < 600 ? 26 : 34,
                                    color: AppColors.text,
                                    height: 1.25,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Tiêu đề ghi chú...',
                                    border: InputBorder.none,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: widget.contentController,
                                  onChanged: widget.onContentChanged,
                                  minLines: 14,
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  textCapitalization: TextCapitalization.sentences,
                                  style: TextStyle(
                                    fontSize: constraints.maxWidth < 600 ? 15 : 17,
                                    height: 1.7,
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Nhập nội dung ghi chú (hỗ trợ Markdown, To-Do, danh sách)...',
                                    hintStyle: TextStyle(color: AppColors.subtle),
                                    border: InputBorder.none,
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

          // Thanh hiển thị số lượng Từ / Ký tự ở chân màn hình (Word & Character Counter)
          Container(
            height: 26,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.note!.wordCount} từ • ${widget.contentController.text.length} ký tự',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.muted, fontFamily: 'monospace'),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.savingStatus == 'Đã lưu' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      widget.savingStatus,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: widget.savingStatus == 'Đã lưu' ? const Color(0xFF059669) : const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formatBtn(
    String label,
    VoidCallback onTap, {
    bool isBold = false,
    bool isItalic = false,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: isHighlight ? AppColors.primaryLight : Colors.white,
            border: Border.all(
              color: isHighlight ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: (isBold || isHighlight) ? FontWeight.bold : FontWeight.w500,
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              color: isHighlight ? AppColors.primaryDark : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}
