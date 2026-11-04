import 'package:flutter/material.dart';
import '../theme/refined_palette.dart';
import 'breadcrumb_trail.dart';

/// Thanh điều hướng trên cùng kèm nút Back và Breadcrumb ngữ cảnh
class BackNavigationBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final List<BreadcrumbItem>? breadcrumbs;
  final Widget? trailing;
  final String? subtitle;

  const BackNavigationBar({
    super.key,
    required this.title,
    required this.onBack,
    this.breadcrumbs,
    this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.sizeOf(context).width < 760;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? RefinedPalette.darkSurface : RefinedPalette.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? RefinedPalette.darkBorder : RefinedPalette.border,
          ),
        ),
      ),
      child: Row(
        children: [
          // Nút Quay lại (Back Button) kích thước chuẩn cảm ứng
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(RefinedPalette.radiusSmall),
            child: Tooltip(
              message: 'Quay lại màn hình trước',
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: RefinedPalette.minTouchTargetSize,
                  minHeight: RefinedPalette.minTouchTargetSize,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(RefinedPalette.radiusSmall),
                  color: isDark ? const Color(0xFF334155) : RefinedPalette.surfaceSecondary,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: isDark ? Colors.white : RefinedPalette.textPrimary,
                    ),
                    if (!isMobile) ...[
                      const SizedBox(width: 4),
                      Text(
                        'Quay lại',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : RefinedPalette.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Breadcrumb hoặc Tiêu đề
          Expanded(
            child: (breadcrumbs != null && breadcrumbs!.isNotEmpty && !isMobile)
                ? BreadcrumbTrail(items: breadcrumbs!)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isMobile ? 15 : 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : RefinedPalette.textPrimary,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? RefinedPalette.textMuted : RefinedPalette.textSecondary,
                          ),
                        ),
                    ],
                  ),
          ),

          // Tùy chọn bên phải (Action buttons)
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
