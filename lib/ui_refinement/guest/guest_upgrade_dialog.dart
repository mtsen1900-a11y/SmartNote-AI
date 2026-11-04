import 'package:flutter/material.dart';
import '../theme/refined_palette.dart';
import 'guest_session.dart';

/// Hộp thoại so sánh quyền lợi giữa Chế độ Khách và Tài khoản đã đăng nhập
class GuestUpgradeDialog extends StatelessWidget {
  final VoidCallback onOpenAuth;
  final FeatureAccess? requestedFeature;

  const GuestUpgradeDialog({
    super.key,
    required this.onOpenAuth,
    this.requestedFeature,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onOpenAuth,
    FeatureAccess? requestedFeature,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => GuestUpgradeDialog(
        onOpenAuth: onOpenAuth,
        requestedFeature: requestedFeature,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: RefinedPalette.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_outlined,
                    color: RefinedPalette.primary,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                requestedFeature != null
                    ? 'Mở khóa tính năng nâng cao'
                    : 'Bảng phân quyền sử dụng SmartNoteAI',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              
              // Explanation
              Text(
                requestedFeature != null
                    ? GuestSession().getRestrictionReason(requestedFeature!)
                    : 'SmartNoteAI cho phép bạn khám phá miễn phí với chế độ Khách, hoặc đăng nhập để có toàn bộ sức mạnh AI.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),

              // Permissions Table
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    _buildRow(
                      'Xem & Khám phá Dashboard',
                      guest: true,
                      user: true,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildRow(
                      'Tạo & Chỉnh sửa ghi chú',
                      guestText: 'Tối đa 5 ghi chú',
                      user: true,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildRow(
                      'Tóm tắt & Phân tích bằng AI',
                      guest: false,
                      user: true,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildRow(
                      'Hỏi đáp RAG trên tài liệu',
                      guest: false,
                      user: true,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildRow(
                      'Đồng bộ đám mây đa thiết bị',
                      guest: false,
                      user: true,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Tiếp tục khám phá'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onOpenAuth();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: RefinedPalette.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Đăng nhập ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    String label, {
    bool? guest,
    String? guestText,
    required bool user,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
          ),
          // Guest status
          if (guestText != null)
            Text(
              guestText,
              style: const TextStyle(fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.w600),
            )
          else if (guest == true)
            const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF10B981))
          else
            const Icon(Icons.lock_outline, size: 15, color: Color(0xFF94A3B8)),
          const SizedBox(width: 24),
          // Account status
          const Icon(Icons.check_circle, size: 16, color: Color(0xFF4F46E5)),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    );
  }
}
