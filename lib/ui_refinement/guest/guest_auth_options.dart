import 'package:flutter/material.dart';
import '../theme/refined_palette.dart';
import 'guest_session.dart';

/// Thành phần mở rộng cho màn hình Authentication:
/// Cho phép người dùng lựa chọn "Tiếp tục với tư cách Khách" để trải nghiệm nhanh
class GuestAuthOptions extends StatelessWidget {
  final VoidCallback onContinueAsGuest;

  const GuestAuthOptions({
    super.key,
    required this.onContinueAsGuest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'hoặc',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
            ),
            Expanded(child: Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
          ],
        ),
        const SizedBox(height: 14),

        // Nút Tiếp tục với tư cách Khách
        OutlinedButton.icon(
          onPressed: () {
            GuestSession().startGuestSession();
            onContinueAsGuest();
          },
          icon: const Icon(Icons.explore_outlined, size: 18, color: RefinedPalette.guestAccent),
          label: const Text(
            'Tiếp tục với tư cách Khách (Khám phá nhanh)',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: RefinedPalette.guestAccent,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            side: BorderSide(
              color: isDark ? const Color(0xFF581C87) : const Color(0xFFDDD6FE),
              width: 1.2,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: isDark
                ? const Color(0xFF2E1065).withValues(alpha: 0.3)
                : RefinedPalette.guestLight.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Khám phá giao diện & tạo ghi chú tạm không cần tài khoản',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ],
    );
  }
}
