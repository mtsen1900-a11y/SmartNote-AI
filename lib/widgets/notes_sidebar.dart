import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/note.dart';
import '../services/auth_service.dart';
import '../ui_refinement/components/help_center_dialog.dart';

class NotesSidebar extends StatelessWidget {
  const NotesSidebar({
    super.key,
    required this.notes,
    required this.selectedNoteId,
    required this.selectedTag,
    required this.searchQuery,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSelectTag,
    required this.onSelectNote,
    required this.onNewNote,
    this.authService,
    this.currentView = 'notes',
    this.onViewChanged,
    this.onOpenKnowledgeGraph,
    this.onOpenIngestDialog,
    this.onOpenHelpCenter,
    this.onOpenAuth,
    this.width = 292,
  });

  final List<Note> notes;
  final String? selectedNoteId;
  final String? selectedTag;
  final String searchQuery;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onSelectTag;
  final ValueChanged<Note> onSelectNote;
  final VoidCallback onNewNote;
  final AuthService? authService;
  final String currentView;
  final ValueChanged<String>? onViewChanged;
  final VoidCallback? onOpenKnowledgeGraph;
  final VoidCallback? onOpenIngestDialog;
  final VoidCallback? onOpenHelpCenter;
  final VoidCallback? onOpenAuth;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            // 1. Tên app [SmartNoteAI] với khung hình quyển sổ màu xanh lá đẹp mắt
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9), // Xanh lá pastel nhạt
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFA5D6A7), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded, // Quyển sổ màu xanh lá
                      color: Color(0xFF2E7D32),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'SmartNoteAI',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. [Tìm kiếm file]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.softSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 16, color: AppColors.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Tìm kiếm file, ghi chú...',
                          hintStyle: TextStyle(fontSize: 12, color: AppColors.subtle),
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (searchQuery.isNotEmpty)
                      InkWell(
                        onTap: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                        child: const Icon(Icons.close, size: 16, color: AppColors.muted),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),

            // 3. Menu điều hướng chính: Bảng điều khiển -> Bảng ghi chú -> Thư mục tổng -> Thùng rác -> Hướng dẫn
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  _navMenuItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Bảng điều khiển',
                    isActive: currentView == 'dashboard',
                    onTap: () => onViewChanged?.call('dashboard'),
                  ),
                  _navMenuItem(
                    icon: Icons.folder_copy_rounded,
                    label: 'Thư mục tổng',
                    isActive: currentView == 'folders' || currentView == 'gallery' || currentView == 'favorites',
                    onTap: () => onViewChanged?.call('folders'),
                  ),
                  _navMenuItem(
                    icon: Icons.delete_outline_rounded,
                    label: 'Thùng rác',
                    isActive: currentView == 'trash',
                    onTap: () => onViewChanged?.call('trash'),
                  ),
                  _navMenuItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Hướng dẫn sử dụng',
                    isActive: false,
                    onTap: () {
                      if (onOpenHelpCenter != null) {
                        onOpenHelpCenter!();
                      } else {
                        HelpCenterDialog.show(context, onSelectView: onViewChanged);
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),
            const Divider(height: 1),

            // Phần bên dưới để trống theo yêu cầu người dùng (không hiển thị danh sách ghi chú mới ở thanh công cụ)
            const Spacer(),

            // Footer trạng thái đồng bộ cục bộ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cloud_done_outlined, size: 15, color: AppColors.accentEmerald),
                  SizedBox(width: 6),
                  Text('Đã đồng bộ cục bộ', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navMenuItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? AppColors.primary : AppColors.muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? AppColors.primaryDark : AppColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
