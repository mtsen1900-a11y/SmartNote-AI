import 'package:flutter/material.dart';
import '../theme/refined_palette.dart';
import 'guest_upgrade_dialog.dart';

/// Thanh thông báo trạng thái Chế độ Khách (Calm & Non-intrusive)
class GuestBanner extends StatelessWidget {
  final VoidCallback onOpenAuth;

  const GuestBanner({
    super.key,
    required this.onOpenAuth,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2E1065) : RefinedPalette.guestLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF581C87) : const Color(0xFFDDD6FE),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: RefinedPalette.guestAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.explore_outlined,
              size: 16,
              color: RefinedPalette.guestAccent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bạn đang trải nghiệm Chế độ Khách',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF4C1D95),
                  ),
                ),
                Text(
                  'Ghi chú lưu tạm trên trình duyệt. Đăng nhập để mở khóa AI và đồng bộ.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFFC4B5FD) : const Color(0xFF6D28D9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => GuestUpgradeDialog.show(context, onOpenAuth: onOpenAuth),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('Quyền lợi', style: TextStyle(fontSize: 12)),
          ),
          FilledButton(
            onPressed: onOpenAuth,
            style: FilledButton.styleFrom(
              backgroundColor: RefinedPalette.guestAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Đăng nhập', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
