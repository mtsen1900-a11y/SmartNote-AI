import 'package:flutter/material.dart';
import '../theme/refined_palette.dart';

/// Bộ trợ năng & Tiện ích tính toán Responsive cho SmartNoteAI
class ResponsiveLayoutHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 760;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= 760 && w < 1050;
  }

  static bool isLaptop(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= 1050 && w < 1200;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1200;

  static bool isSmallMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 390;

  /// Khoảng đệm đáy an toàn (Safe bottom padding) tránh bị SnackBar hoặc Bottom Sheet che khuất nội dung
  static const EdgeInsets bottomSafeScrollPadding = EdgeInsets.only(
    left: 16,
    right: 16,
    top: 16,
    bottom: 88, // 88px padding dưới giúp tránh che khuất bởi SnackBar/ActionBar
  );
}

/// Widget bọc vùng bấm tối thiểu 44x44px đảm bảo tiêu chuẩn WCAG
class MinTouchTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? tooltip;
  final BorderRadius? borderRadius;

  const MinTouchTarget({
    super.key,
    required this.child,
    this.onTap,
    this.tooltip,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: RefinedPalette.minTouchTargetSize,
        minHeight: RefinedPalette.minTouchTargetSize,
      ),
      child: Center(child: child),
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(RefinedPalette.radiusSmall),
        child: content,
      );
    }

    if (tooltip != null) {
      content = Tooltip(message: tooltip!, child: content);
    }

    return content;
  }
}
