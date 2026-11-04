import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../theme/refined_palette.dart';
import 'gallery_note_card.dart';

/// Màn hình quản lý Thư mục và Duyệt ghi chú dạng thẻ Gallery chuẩn phong cách Apple Notes
class AppleNotesGalleryView extends StatefulWidget {
  final List<Note> notes;
  final ValueChanged<Note> onSelectNote;
  final VoidCallback onNewNote;
  final void Function({required String title, required String content, String? folder})? onNewNoteWithFolder;
  final VoidCallback? onBackToDashboard;
  final VoidCallback? onOpenMenu;
  final void Function(String oldName, String newName)? onRenameFolder;
  final void Function(String folderName)? onDeleteFolder;

  const AppleNotesGalleryView({
    super.key,
    required this.notes,
    required this.onSelectNote,
    required this.onNewNote,
    this.onNewNoteWithFolder,
    this.onBackToDashboard,
    this.onOpenMenu,
    this.onRenameFolder,
    this.onDeleteFolder,
  });

  @override
  State<AppleNotesGalleryView> createState() => _AppleNotesGalleryViewState();
}

class _AppleNotesGalleryViewState extends State<AppleNotesGalleryView> {
  String? _selectedFolder; // null = đang ở màn hình danh sách Thư mục (Ảnh 1 & 3)
  final Set<String> _customFolders = {};
  String _searchKeyword = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _snackBarTimer;

  @override
  void dispose() {
    _snackBarTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _allFolders {
    final set = <String>{};
    set.addAll(_customFolders);
    for (final n in widget.notes) {
      if (n.folder.trim().isNotEmpty && n.folder.trim() != 'Cá nhân' && n.folder.trim() != 'Công việc' && n.folder.trim() != 'Học tập' && n.folder.trim() != 'Dự án' && n.folder.trim() != 'Ý tưởng') {
        set.add(n.folder.trim());
      }
    }
    return set.toList();
  }

  void _promptCreateFolder() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.create_new_folder_outlined, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Text('Thư mục mới', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nhập tên thư mục...',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            _addFolder(controller.text.trim(), ctx);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => _addFolder(controller.text.trim(), ctx),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _addFolder(String name, BuildContext dialogCtx) {
    if (name.isNotEmpty) {
      setState(() {
        _customFolders.add(name);
        _selectedFolder = name;
      });
      Navigator.pop(dialogCtx);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 76, left: 16, right: 16),
          content: Text('✅ Đã tạo thư mục "$name"'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _promptRenameFolder(String oldName) {
    final controller = TextEditingController(text: oldName);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_outlined, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Text('Đổi tên thư mục', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nhập tên thư mục mới...',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            _renameFolder(oldName, controller.text.trim(), ctx);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => _renameFolder(oldName, controller.text.trim(), ctx),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _renameFolder(String oldName, String newName, BuildContext dialogCtx) {
    if (newName.isNotEmpty && newName != oldName) {
      setState(() {
        _customFolders.remove(oldName);
        _customFolders.add(newName);
        if (_selectedFolder == oldName) {
          _selectedFolder = newName;
        }
      });
      widget.onRenameFolder?.call(oldName, newName);
      Navigator.pop(dialogCtx);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 76, left: 16, right: 16),
          content: Text('✅ Đã đổi tên thư mục thành "$newName"'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmDeleteFolder(String folderName) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Xóa thư mục?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa thư mục "$folderName"?\nCác ghi chú bên trong sẽ được chuyển an toàn về thư mục "Cá nhân".',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteFolder(folderName);
            },
            child: const Text('Xóa thư mục'),
          ),
        ],
      ),
    );
  }

  void _deleteFolder(String folderName) {
    setState(() {
      _customFolders.remove(folderName);
      if (_selectedFolder == folderName) {
        _selectedFolder = null;
      }
    });
    widget.onDeleteFolder?.call(folderName);
    _snackBarTimer?.cancel();
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 76, left: 16, right: 16),
        content: Text('🗑️ Đã xóa thư mục "$folderName"'),
        duration: const Duration(seconds: 10),
        showCloseIcon: true,
        closeIconColor: Colors.white,
      ),
    );
    _snackBarTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        messenger.hideCurrentSnackBar();
      }
    });
  }

  String _getTimeGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDay = DateTime(date.year, date.month, date.day);
    final diffDays = today.difference(noteDay).inDays;

    if (diffDays == 0) return 'Hôm nay';
    if (diffDays == 1) return 'Hôm qua';
    if (diffDays <= 7) return '7 ngày trước';
    if (diffDays <= 30) return '30 ngày trước';
    return 'Tháng ${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Nội dung chính
            Expanded(
              child: _selectedFolder == null
                  ? _buildFolderListView(isDark)
                  : _buildCardGalleryView(isDark),
            ),

            // Thanh tìm kiếm & Nút Tạo mới cố định dưới cùng chuẩn phong cách Apple Notes
            _buildBottomFloatingBar(isDark),
          ],
        ),
      ),
    );
  }

  /// Màn hình Danh sách Thư mục tổng (Khớp hoàn toàn mô hình [Thư mục tổng] -> [Ghi chú đã ghim] + [Thư mục])
  Widget _buildFolderListView(bool isDark) {
    final folders = _allFolders;
    final totalNotesCount = widget.notes.length;
    final pinnedNotes = widget.notes.where((n) => n.isPinned).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh tiêu đề trên cùng có cả nút Thoát ⬅️ và nút Home 🏠
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (widget.onBackToDashboard != null) ...[
                          IconButton(
                            tooltip: 'Trang chủ',
                            icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                            onPressed: widget.onBackToDashboard,
                          ),
                          IconButton(
                            tooltip: 'Về trang chủ',
                            icon: const Icon(Icons.home_rounded, size: 24, color: RefinedPalette.primary),
                            onPressed: widget.onBackToDashboard,
                          ),
                          const SizedBox(width: 4),
                        ] else if (widget.onOpenMenu != null)
                          IconButton(
                            tooltip: 'Menu',
                            icon: const Icon(Icons.menu_rounded, size: 22),
                            onPressed: widget.onOpenMenu,
                          ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Thư mục tổng',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              color: isDark ? Colors.white : RefinedPalette.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tạo thư mục mới',
                    icon: const Icon(Icons.create_new_folder_outlined, color: RefinedPalette.primary, size: 24),
                    onPressed: _promptCreateFolder,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // =========================================================
              // PHẦN 1: CÁC GHI CHÚ ĐÃ GHIM (Nhấn vào hiện ngay nội dung file)
              // =========================================================
              if (pinnedNotes.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.push_pin_rounded, size: 16, color: Color(0xFFD97706)),
                      const SizedBox(width: 6),
                      Text(
                        'Các ghi chú đã ghim (${pinnedNotes.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : RefinedPalette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < pinnedNotes.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 48, endIndent: 16),
                        _buildPinnedNoteItemRow(
                          note: pinnedNotes[i],
                          isDark: isDark,
                          isFirst: i == 0,
                          isLast: i == pinnedNotes.length - 1,
                          onTap: () => widget.onSelectNote(pinnedNotes[i]),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // =========================================================
              // PHẦN 2: THƯ MỤC (Nhấn vào hiện các file chứa nội dung)
              // =========================================================
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.folder_outlined, size: 17, color: RefinedPalette.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Thư mục (${folders.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : RefinedPalette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Khối Inset Grouped Thư mục (Bo góc 18px, nền trắng như Apple Notes)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Mục Tất cả ghi chú
                    _buildFolderItemRow(
                      icon: Icons.folder_copy_outlined,
                      iconColor: const Color(0xFFD97706),
                      title: 'Tất cả ghi chú',
                      count: totalNotesCount,
                      isDark: isDark,
                      isFirst: true,
                      isLast: folders.isEmpty,
                      onTap: () => setState(() => _selectedFolder = 'Tất cả ghi chú'),
                    ),

                    // Từng thư mục cụ thể (cho phép sửa, xóa)
                    for (int i = 0; i < folders.length; i++) ...[
                      const Divider(height: 1, indent: 48, endIndent: 16),
                      _buildFolderItemRow(
                        icon: Icons.folder_outlined,
                        iconColor: const Color(0xFFEAB308),
                        title: folders[i],
                        count: widget.notes.where((n) => n.folder == folders[i]).length,
                        isDark: isDark,
                        isFirst: false,
                        isLast: i == folders.length - 1,
                        onTap: () => setState(() => _selectedFolder = folders[i]),
                        onRename: () => _promptRenameFolder(folders[i]),
                        onDelete: () => _confirmDeleteFolder(folders[i]),
                      ),
                    ],

                    if (folders.isEmpty) ...[
                      const Divider(height: 1, indent: 48, endIndent: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Chưa có thư mục nào. Nhấn [+] ở trên để tạo mới.',
                                style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinnedNoteItemRow({
    required Note note,
    required bool isDark,
    required bool isFirst,
    required bool isLast,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(18) : Radius.zero,
        bottom: isLast ? const Radius.circular(18) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            const Icon(Icons.push_pin, color: Color(0xFFD97706), size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title.isNotEmpty ? note.title : 'Ghi chú không tiêu đề',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : RefinedPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${note.folder} • ${note.wordCount} từ',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderItemRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required int count,
    required bool isDark,
    required bool isFirst,
    required bool isLast,
    required VoidCallback onTap,
    VoidCallback? onRename,
    VoidCallback? onDelete,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(18) : Radius.zero,
        bottom: isLast ? const Radius.circular(18) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : RefinedPalette.textPrimary,
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
            if (onRename != null || onDelete != null) ...[
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                itemBuilder: (ctx) => [
                  if (onRename != null)
                    const PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16, color: Color(0xFFD97706)),
                          SizedBox(width: 8),
                          Text('Đổi tên', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  if (onDelete != null)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Xóa thư mục', style: TextStyle(fontSize: 13, color: Colors.red)),
                        ],
                      ),
                    ),
                ],
                onSelected: (val) {
                  if (val == 'rename') onRename?.call();
                  if (val == 'delete') onDelete?.call();
                },
              ),
            ] else ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
            ],
          ],
        ),
      ),
    );
  }

  /// Màn hình Danh sách Ghi chú dạng Thẻ Gallery theo thời gian (Khớp hoàn toàn Ảnh 2)
  Widget _buildCardGalleryView(bool isDark) {
    final folderName = _selectedFolder ?? 'Ghi chú';
    final notesInFolder = _selectedFolder == 'Tất cả ghi chú'
        ? widget.notes
        : widget.notes.where((n) => n.folder == _selectedFolder).toList();

    // Lọc theo từ khóa tìm kiếm nếu có
    final filteredNotes = _searchKeyword.trim().isEmpty
        ? notesInFolder
        : notesInFolder.where((n) {
            final needle = _searchKeyword.trim().toLowerCase();
            return n.title.toLowerCase().contains(needle) || n.content.toLowerCase().contains(needle);
          }).toList();

    // Gom nhóm theo thời gian (30 ngày trước, Tháng 9, Tháng 8...)
    final Map<String, List<Note>> grouped = {};
    for (final note in filteredNotes) {
      final groupKey = _getTimeGroup(note.updatedAt);
      grouped.putIfAbsent(groupKey, () => []).add(note);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh điều hướng trên cùng có nút Quay lại < Thư mục
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _selectedFolder = null),
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          child: Row(
                            children: [
                              Icon(Icons.arrow_back_ios_rounded, color: RefinedPalette.primary, size: 18),
                              SizedBox(width: 4),
                              Text(
                                'Thư mục tổng',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: RefinedPalette.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (widget.onBackToDashboard != null) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'Về trang chủ',
                          icon: const Icon(Icons.home_rounded, color: RefinedPalette.primary, size: 22),
                          onPressed: widget.onBackToDashboard,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                      ],
                    ],
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz_rounded, size: 24),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'new_note', child: Text('Tạo ghi chú mới')),
                      const PopupMenuItem(value: 'clear_search', child: Text('Làm mới tìm kiếm')),
                    ],
                    onSelected: (val) {
                      if (val == 'new_note') _createNewNoteInFolder();
                      if (val == 'clear_search') setState(() => _searchKeyword = '');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Tiêu đề Thư mục lớn + Số lượng ghi chú
              Text(
                folderName,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: isDark ? Colors.white : RefinedPalette.textPrimary,
                ),
              ),
              Text(
                '${filteredNotes.length} ghi chú',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),

              if (filteredNotes.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        const Icon(Icons.note_alt_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('Chưa có ghi chú nào trong mục này.'),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: _createNewNoteInFolder,
                          child: const Text('Tạo ghi chú ngay'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // Các nhóm thời gian (30 ngày trước, Tháng 9, Tháng 8...)
                for (final entry in grouped.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 10),
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                        color: isDark ? Colors.white : RefinedPalette.textPrimary,
                      ),
                    ),
                  ),

                  // Lưới thẻ ghi chú (2 cột trên mobile, 3 cột trên tablet/desktop)
                  LayoutBuilder(
                    builder: (ctx, constraints) {
                      final crossAxisCount = constraints.maxWidth < 450 ? 2 : (constraints.maxWidth < 700 ? 3 : 4);
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.76,
                        ),
                        itemCount: entry.value.length,
                        itemBuilder: (ctx, idx) {
                          final note = entry.value[idx];
                          return GalleryNoteCard(
                            note: note,
                            onTap: () => widget.onSelectNote(note),
                          );
                        },
                      );
                    },
                  ),
                ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _createNewNoteInFolder() {
    if (widget.onNewNoteWithFolder != null && _selectedFolder != null && _selectedFolder != 'Tất cả ghi chú') {
      widget.onNewNoteWithFolder!(
        title: '',
        content: '',
        folder: _selectedFolder,
      );
    } else {
      widget.onNewNote();
    }
  }

  /// Thanh điều hướng trôi dưới đáy màn hình (Search Pill + New Note Button)
  Widget _buildBottomFloatingBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), width: 0.8)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Row(
            children: [
              // Thanh tìm kiếm hình con nhộng (Pill Search)
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Tìm kiếm',
                            hintStyle: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 14),
                          onChanged: (val) => setState(() => _searchKeyword = val),
                        ),
                      ),
                      if (_searchKeyword.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.cancel, size: 16, color: Color(0xFF94A3B8)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchKeyword = '');
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Nút tạo ghi chú mới hình tròn/bo góc (Icon cây bút trong ô vuông bo góc)
              InkWell(
                onTap: _createNewNoteInFolder,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: RefinedPalette.primary,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
