import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../../services/auth_service.dart';
import '../theme/refined_palette.dart';
import '../accessibility/responsive_layout_helper.dart';

/// Giao diện Dashboard tối giản, hiện đại và tinh gọn của SmartNoteAI
/// Theo đúng yêu cầu người dùng:
/// 1. Thanh trên: Menu 3 gạch, Biểu tượng Đăng nhập, Nút Tạo ghi chú, Nút Chỉnh sửa (Đã xóa chữ "Xin chào khách")
/// 2. Khối 4 ô tính năng trung tâm:
///    - Trợ lý AI (Hỏi đáp & tóm tắt)
///    - Bản đồ tri thức (Sơ đồ cây cấu trúc app & cây thư mục phân nhánh)
///    - Nạp dữ liệu (Đọc hiểu PDF & Web)
///    - Quiz (Tạo thẻ ghi chú & trắc nghiệm nộp bài)
/// 3. Đã loại bỏ các khối rườm rà (4 thẻ đếm số, thanh lưu nhanh, chủ đề tags, ghi chú gần đây) để tối giản không gian.
/// 4. Thanh điều hướng nổi hình viên thuốc cố định sát mép đáy màn hình.
class RefinedDashboardView extends StatelessWidget {
  final List<Note> notes;
  final AuthService? authService;
  final ValueChanged<Note> onSelectNote;
  final VoidCallback onNewNote;
  final VoidCallback onOpenKnowledgeGraph;
  final VoidCallback onOpenIngest;
  final VoidCallback? onOpenFlashcards;
  final VoidCallback? onOpenAi;
  final void Function(String route)? onViewChanged;
  final VoidCallback? onOpenMenu;
  final ValueChanged<String>? onQuickCreate;
  final VoidCallback? onOpenAuth;
  final VoidCallback? onOpenRightPanel;

  const RefinedDashboardView({
    super.key,
    required this.notes,
    this.authService,
    required this.onSelectNote,
    required this.onNewNote,
    required this.onOpenKnowledgeGraph,
    required this.onOpenIngest,
    this.onOpenFlashcards,
    this.onOpenAi,
    this.onViewChanged,
    this.onOpenMenu,
    this.onQuickCreate,
    this.onOpenAuth,
    this.onOpenRightPanel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveLayoutHelper.isMobile(context);

    return Scaffold(
      backgroundColor: isDark ? RefinedPalette.darkBackground : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Nội dung chính
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18, 16, 18, isMobile ? 88 : 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Thanh trên cùng: Menu 3 gạch, Biểu tượng Đăng nhập, Nút Tạo ghi chú, Nút Chỉnh sửa
                      _buildTopActionBar(context, isMobile, isDark),
                      const SizedBox(height: 24),

                      // 2. Khối Trợ lý AI & Kho Tri thức (4 ô lớn: Trợ lý AI, Cây tri thức, Nạp tài liệu, Quiz)
                      _buildAiKnowledgeHub(context, isMobile, isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Thanh điều hướng nổi hình viên thuốc ở mép đáy màn hình (Floating Pill Bar)
          if (isMobile)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Center(
                child: _buildFloatingPillBar(context, isDark),
              ),
            ),
        ],
      ),
    );
  }

  /// Thanh trên cùng: Menu 3 gạch, Logo SmartNoteAI, Nút Mở thanh tác vụ bên phải (Chứa Đăng nhập, Tạo mới, Sửa)
  Widget _buildTopActionBar(BuildContext context, bool isMobile, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Nút 3 gạch mở sidebar bên trái
          if (onOpenMenu != null) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded, size: 24),
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              tooltip: 'Mở thanh công cụ',
              onPressed: onOpenMenu,
            ),
            const SizedBox(width: 4),
          ],

          // Tên ứng dụng SmartNoteAI tinh gọn ở giữa / bên trái (tự co giãn)
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF2E7D32),
                    size: 15,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'SmartNoteAI',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Nút mở Thanh tác vụ bên phải (Chứa Đăng nhập, Tạo ghi chú mới, Chỉnh sửa nội dung)
          if (onOpenRightPanel != null)
            InkWell(
              onTap: onOpenRightPanel,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded, size: 16, color: Color(0xFF6366F1)),
                    SizedBox(width: 6),
                    Text(
                      'Tác vụ',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 4 Ô chức năng cốt lõi (Trợ lý AI, Sơ đồ cây tri thức, Nạp dữ liệu, Quiz)
  Widget _buildAiKnowledgeHub(BuildContext context, bool isMobile, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trợ lý AI & Kho Tri thức',
                      style: TextStyle(
                        fontSize: isMobile ? 15 : 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Hỏi đáp, tóm tắt sơ đồ cây và nạp tài liệu tự động',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: const Text(
                    'AI Engine v2',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Lưới 4 ô: Trợ lý AI, Bản đồ tri thức, Nạp tài liệu, Quiz
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth < 620 ? 1 : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: crossAxisCount == 1 ? 2.5 : 2.0,
                children: [
                  _hubCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Trợ lý AI',
                    subtitle: 'Hỏi đáp & tóm tắt thông minh',
                    iconColor: const Color(0xFF6366F1),
                    bgColor: const Color(0xFFEEF2FF),
                    isDark: isDark,
                    onTap: onOpenAi ?? () {},
                  ),
                  _hubCard(
                    icon: Icons.account_tree_outlined, // Sơ đồ cây phân nhánh
                    title: 'Bản đồ Tri thức',
                    subtitle: 'Sơ đồ cây cấu trúc & phân nhánh thư mục',
                    iconColor: const Color(0xFF0284C7),
                    bgColor: const Color(0xFFE0F2FE),
                    isDark: isDark,
                    onTap: onOpenKnowledgeGraph,
                  ),
                  _hubCard(
                    icon: Icons.cloud_upload_outlined,
                    title: 'Nạp tài liệu',
                    subtitle: 'Đọc hiểu PDF, DOCX, CSV & Web',
                    iconColor: const Color(0xFF059669),
                    bgColor: const Color(0xFFD1FAE5),
                    isDark: isDark,
                    onTap: onOpenIngest,
                  ),
                  _hubCard(
                    icon: Icons.quiz_outlined, // Quiz: thẻ trắc nghiệm & nộp bài
                    title: 'Quiz',
                    subtitle: 'Tạo thẻ ghi chú & trắc nghiệm nộp bài',
                    iconColor: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFEF3C7),
                    isDark: isDark,
                    onTap: onOpenFlashcards ?? () {},
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _hubCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color bgColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  /// Thanh điều hướng nổi hình viên thuốc cố định sát mép đáy màn hình (Floating Pill Bar)
  Widget _buildFloatingPillBar(BuildContext context, bool isDark) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pillIconBtn(
            icon: Icons.home_rounded,
            tooltip: 'Trang chủ',
            isActive: true,
            onTap: () => onViewChanged?.call('dashboard'),
          ),
          const SizedBox(width: 14),
          _pillIconBtn(
            icon: Icons.search_rounded,
            tooltip: 'Tìm kiếm',
            isActive: false,
            onTap: () => onViewChanged?.call('notes'),
          ),
          const SizedBox(width: 14),
          _pillIconBtn(
            icon: Icons.checklist_rounded,
            tooltip: 'Việc cần làm',
            isActive: false,
            onTap: () => onViewChanged?.call('tasks'),
          ),
          const SizedBox(width: 14),
          _pillIconBtn(
            icon: Icons.folder_rounded,
            tooltip: 'Thư mục tổng',
            isActive: false,
            onTap: () => onViewChanged?.call('folders'),
          ),
        ],
      ),
    );
  }

  Widget _pillIconBtn({
    required IconData icon,
    required String tooltip,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFF59E0B) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            icon,
            size: 19,
            color: isActive ? Colors.white : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}
