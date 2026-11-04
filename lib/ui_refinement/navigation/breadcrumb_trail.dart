import 'package:flutter/material.dart';
import '../theme/refined_palette.dart';

class BreadcrumbItem {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  const BreadcrumbItem({
    required this.label,
    this.icon,
    this.onTap,
  });
}

/// Dải điều hướng phân cấp (Breadcrumb Trail)
class BreadcrumbTrail extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const BreadcrumbTrail({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildItem(items[i], isLast: i == items.length - 1, isDark: isDark),
            if (i < items.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildItem(BreadcrumbItem item, {required bool isLast, required bool isDark}) {
    final isClickable = item.onTap != null && !isLast;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.icon != null) ...[
          Icon(
            item.icon,
            size: 14,
            color: isLast
                ? (isDark ? Colors.white : RefinedPalette.textPrimary)
                : (isDark ? const Color(0xFF94A3B8) : RefinedPalette.textSecondary),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          item.label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isLast ? FontWeight.bold : FontWeight.w500,
            color: isLast
                ? (isDark ? Colors.white : RefinedPalette.textPrimary)
                : (isClickable
                    ? RefinedPalette.primary
                    : (isDark ? const Color(0xFF94A3B8) : RefinedPalette.textSecondary)),
          ),
        ),
      ],
    );

    if (isClickable) {
      return InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: content,
    );
  }
}
