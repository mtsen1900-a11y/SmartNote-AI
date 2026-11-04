import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../theme/refined_palette.dart';

/// Thẻ ghi chú dạng Gallery chuẩn phong cách Apple Notes
class GalleryNoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const GalleryNoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onLongPress,
  });

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString().substring(dt.year.toString().length - 2);
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final snippetLines = note.content
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#'))
        .take(4)
        .toList();

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thẻ tài liệu thu nhỏ (Document Preview Tile)
          AspectRatio(
            aspectRatio: 1.15,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Nội dung xem trước dạng dòng văn bản thu nhỏ
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (note.title.isNotEmpty)
                        Text(
                          note.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : RefinedPalette.textPrimary,
                          ),
                        ),
                      if (note.title.isNotEmpty) const SizedBox(height: 4),
                      if (snippetLines.isEmpty)
                        Text(
                          '*(Chưa có nội dung)*',
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        )
                      else
                        for (final line in snippetLines)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              line,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                height: 1.25,
                              ),
                            ),
                          ),
                    ],
                  ),

                  // Huy hiệu ghim nếu có
                  if (note.isPinned)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Icon(Icons.push_pin, size: 10, color: Color(0xFFD97706)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Tiêu đề ghi chú (Đậm)
          Text(
            note.title.isNotEmpty ? note.title : 'Ghi chú mới',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : RefinedPalette.textPrimary,
            ),
          ),

          // Ngày tháng cập nhật (ví dụ: 20/10/26)
          Text(
            _formatDate(note.updatedAt),
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
