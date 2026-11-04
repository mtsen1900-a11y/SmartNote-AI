import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/refined_palette.dart';

class HelpFeatureItem {
  final String title;
  final IconData icon;
  final String shortDesc;
  final String usage;
  final String permission;
  final bool isAccountOnly;
  final VoidCallback? onNavigate;

  const HelpFeatureItem({
    required this.title,
    required this.icon,
    required this.shortDesc,
    required this.usage,
    required this.permission,
    this.isAccountOnly = false,
    this.onNavigate,
  });
}

/// Trung tâm Hướng dẫn & Khám phá SmartNoteAI
class HelpCenterDialog extends StatefulWidget {
  final void Function(String route)? onSelectView;

  const HelpCenterDialog({
    super.key,
    this.onSelectView,
  });

  static Future<void> show(BuildContext context, {void Function(String route)? onSelectView}) {
    return showDialog(
      context: context,
      builder: (ctx) => HelpCenterDialog(onSelectView: onSelectView),
    );
  }

  @override
  State<HelpCenterDialog> createState() => _HelpCenterDialogState();
}

class _HelpCenterDialogState extends State<HelpCenterDialog> {
  String _searchFilter = '';

  List<HelpFeatureItem> _getFeatures() => [
    HelpFeatureItem(
      title: '1. Ghi chú và Chỉnh sửa',
      icon: Icons.edit_note,
      shortDesc: 'Tạo, định dạng và lưu trữ ý tưởng với Markdown',
      usage: 'Bấm nút "+ Ghi chú mới" hoặc nhập vào thanh "Ghi nhanh". Sử dụng thanh công cụ để định dạng Tiêu đề, In đậm, Danh sách hoặc To-Do.',
      permission: 'Miễn phí & Khách (tối đa 5 ghi chú)',
      onNavigate: () => widget.onSelectView?.call('notes'),
    ),
    HelpFeatureItem(
      title: '2. Quản lý Thư mục (Folders)',
      icon: Icons.folder_outlined,
      shortDesc: 'Phân loại tri thức theo không gian chủ đề',
      usage: 'Chọn Thư mục trong trình soạn thảo (Cá nhân, Công việc, Học tập, Dự án, Ý tưởng) để gom nhóm tài liệu khoa học.',
      permission: 'Miễn phí & Khách',
      onNavigate: () => widget.onSelectView?.call('dashboard'),
    ),
    HelpFeatureItem(
      title: '3. Quản lý Thẻ (Tags)',
      icon: Icons.tag,
      shortDesc: 'Gắn nhãn đa chiều để kết nối các chủ đề liên quan',
      usage: 'Bấm biểu tượng (+) cạnh thẻ trong ghi chú để thêm thẻ mới. Lọc nhanh ghi chú theo thẻ trên thanh Sidebar.',
      permission: 'Miễn phí & Khách',
      onNavigate: () => widget.onSelectView?.call('notes'),
    ),
    HelpFeatureItem(
      title: '4. Tìm kiếm Nhanh',
      icon: Icons.search,
      shortDesc: 'Tìm lại tức thì theo tiêu đề và nội dung',
      usage: 'Sử dụng ô tìm kiếm trên thanh Sidebar để lọc danh sách ghi chú với độ trễ 0ms.',
      permission: 'Miễn phí & Khách',
      onNavigate: () => widget.onSelectView?.call('notes'),
    ),
    HelpFeatureItem(
      title: '5. Trợ lý AI (NLU Assistant)',
      icon: Icons.auto_awesome,
      shortDesc: 'Hỏi đáp ngôn ngữ tự nhiên và thực hiện tác vụ',
      usage: 'Bấm nút "AI" ở góc trên bên phải màn hình ghi chú. Đặt câu hỏi bằng tiếng Việt hoặc yêu cầu tạo danh sách công việc.',
      permission: 'Cần Đăng nhập (Khách chỉ xem mẫu)',
      isAccountOnly: true,
    ),
    HelpFeatureItem(
      title: '6. Tóm tắt & Phân tích Tài liệu',
      icon: Icons.summarize_outlined,
      shortDesc: 'Chắt lọc nội dung cốt lõi và trích dẫn tài liệu',
      usage: 'Yêu cầu Trợ lý AI "Tóm tắt ghi chú này" để nhận các ý chính, số lượng từ và luận điểm quan trọng có trích dẫn nguồn.',
      permission: 'Cần Đăng nhập',
      isAccountOnly: true,
    ),
    HelpFeatureItem(
      title: '7. Nhập Dữ liệu Đa Nguồn (Ingest)',
      icon: Icons.upload_file,
      shortDesc: 'Nhập văn bản thô, cào bài viết từ Web URL hoặc tệp',
      usage: 'Chọn "Nhập dữ liệu" trên Sidebar, dán link bài viết hoặc đoạn văn bản dài để hệ thống tự động lập chỉ mục.',
      permission: 'Cần Đăng nhập (bảo vệ chống SSRF)',
      isAccountOnly: true,
    ),
    HelpFeatureItem(
      title: '8. Quản lý Nhiệm vụ (Tasks)',
      icon: Icons.check_circle_outline,
      shortDesc: 'Tự động tổng hợp checklist từ toàn bộ ghi chú',
      usage: 'Viết cú pháp "- [ ] Việc cần làm" trong ghi chú. Hệ thống tự động gom vào màn hình "Nhiệm vụ" để theo dõi tiến độ.',
      permission: 'Miễn phí & Khách',
      onNavigate: () => widget.onSelectView?.call('tasks'),
    ),
    HelpFeatureItem(
      title: '9. Đồng bộ Hóa Ngoại tuyến (Sync)',
      icon: Icons.sync,
      shortDesc: 'Lưu trữ cục bộ Drift SQLite và đồng bộ máy chủ',
      usage: 'Ứng dụng luôn lưu tức thì tại máy của bạn. Khi có mạng, dữ liệu tự động đồng bộ 2 chiều lên máy chủ cá nhân.',
      permission: 'Cần Đăng nhập để đồng bộ đám mây',
      isAccountOnly: true,
    ),
    HelpFeatureItem(
      title: '10. Chế độ Khách & Tài khoản Cá nhân',
      icon: Icons.account_circle_outlined,
      shortDesc: 'Khám phá nhanh không cần tài khoản hoặc sở hữu Workspace riêng',
      usage: 'Chế độ Khách lưu dữ liệu tạm trên trình duyệt. Đăng nhập để sở hữu URL Workspace riêng và mở khóa toàn bộ AI.',
      permission: 'Linh hoạt',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allFeatures = _getFeatures();
    final filtered = _searchFilter.isEmpty
        ? allFeatures
        : allFeatures
            .where((f) =>
                f.title.toLowerCase().contains(_searchFilter.toLowerCase()) ||
                f.shortDesc.toLowerCase().contains(_searchFilter.toLowerCase()) ||
                f.usage.toLowerCase().contains(_searchFilter.toLowerCase()))
            .toList();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 500;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: isCompact ? 14 : 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: RefinedPalette.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_book_outlined, color: RefinedPalette.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Khám phá SmartNoteAI',
                          style: TextStyle(
                            fontSize: isCompact ? 16 : 17,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : RefinedPalette.textPrimary,
                          ),
                        ),
                        Text(
                          'Hướng dẫn chi tiết 10 tính năng và quyền sử dụng',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF94A3B8) : RefinedPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tìm kiếm tính năng
              TextField(
                onChanged: (val) => setState(() => _searchFilter = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm tính năng hoặc cách sử dụng...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Danh sách tính năng cuộn mượt (Khắc phục hoàn toàn lỗi tràn kí tự trên màn hình nhỏ)
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                    },
                  ),
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final item = filtered[idx];
                      return Container(
                        padding: EdgeInsets.all(isCompact ? 12 : 14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : RefinedPalette.surfaceSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : RefinedPalette.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(item.icon, size: 18, color: RefinedPalette.primary),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : RefinedPalette.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: item.isAccountOnly
                                              ? RefinedPalette.primaryLight
                                              : RefinedPalette.successLight,
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          item.permission,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: item.isAccountOnly
                                                ? RefinedPalette.primary
                                                : RefinedPalette.success,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 6),
                          Text(
                            item.shortDesc,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.usage,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? const Color(0xFF94A3B8) : RefinedPalette.textSecondary,
                              height: 1.35,
                            ),
                          ),
                          if (item.onNavigate != null) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  item.onNavigate!();
                                },
                                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                                label: const Text('Đi tới tính năng', style: TextStyle(fontSize: 11.5)),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
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
