import 'package:flutter/material.dart';
import '../theme/refined_palette.dart';

/// Thẻ giới thiệu tinh giản, rõ ràng, không thuật ngữ kỹ thuật hay roadmap nội bộ
class CleanIntroCard extends StatelessWidget {
  final VoidCallback? onOpenHelpCenter;

  const CleanIntroCard({
    super.key,
    this.onOpenHelpCenter,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? RefinedPalette.darkSurface : RefinedPalette.surface,
        borderRadius: BorderRadius.circular(RefinedPalette.radiusMedium),
        border: Border.all(
          color: isDark ? RefinedPalette.darkBorder : RefinedPalette.border,
        ),
        boxShadow: RefinedPalette.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: RefinedPalette.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: RefinedPalette.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SmartNoteAI – Your Personal Knowledge Space',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : RefinedPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Không gian ghi chú và quản lý tri thức cá nhân, giúp bạn lưu trữ, sắp xếp, tìm kiếm và khai thác thông tin hiệu quả với sự hỗ trợ của AI.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? RefinedPalette.textMuted : RefinedPalette.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (onOpenHelpCenter != null) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onOpenHelpCenter,
                  icon: const Icon(Icons.help_outline, size: 16),
                  label: const Text('Hướng dẫn', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: RefinedPalette.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // 6 mục tính năng ngắn gọn dạng thẻ phẳng
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: const [
              _FeaturePill(icon: Icons.edit_note, title: 'Ghi chú thông minh', desc: 'Tạo & sửa linh hoạt'),
              _FeaturePill(icon: Icons.folder_open, title: 'Tổ chức tri thức', desc: 'Thư mục & thẻ Tags'),
              _FeaturePill(icon: Icons.search, title: 'Tìm kiếm nhanh', desc: 'Tra cứu tức thì'),
              _FeaturePill(icon: Icons.psychology_outlined, title: 'AI Assistant', desc: 'Tóm tắt & phân tích'),
              _FeaturePill(icon: Icons.upload_file, title: 'Quản lý tài liệu', desc: 'Nhập đa định dạng'),
              _FeaturePill(icon: Icons.sync, title: 'Đồng bộ dữ liệu', desc: 'Làm việc ngoại tuyến'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _FeaturePill({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : RefinedPalette.surfaceSecondary,
        borderRadius: BorderRadius.circular(RefinedPalette.radiusSmall),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : RefinedPalette.borderSubtle,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: RefinedPalette.primary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : RefinedPalette.textPrimary,
                ),
              ),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? const Color(0xFF94A3B8) : RefinedPalette.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
