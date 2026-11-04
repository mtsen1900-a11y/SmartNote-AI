import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/note.dart';

class TrashView extends StatelessWidget {
  final List<Note> deletedNotes;
  final ValueChanged<Note> onRestoreNote;
  final ValueChanged<Note> onPermanentDelete;
  final VoidCallback? onEmptyTrash;
  final VoidCallback? onOpenMenu;
  final VoidCallback? onBackToDashboard;

  const TrashView({
    super.key,
    required this.deletedNotes,
    required this.onRestoreNote,
    required this.onPermanentDelete,
    this.onEmptyTrash,
    this.onOpenMenu,
    this.onBackToDashboard,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 420;
                return Row(
                  children: [
                    if (onBackToDashboard != null) ...[
                      IconButton(
                        tooltip: 'Quay lại',
                        icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                        onPressed: onBackToDashboard,
                      ),
                      IconButton(
                        tooltip: 'Về trang chủ',
                        icon: const Icon(Icons.home_rounded, size: 22, color: AppColors.primary),
                        onPressed: onBackToDashboard,
                      ),
                      const SizedBox(width: 4),
                    ] else if (onOpenMenu != null) ...[
                      IconButton(
                        icon: const Icon(Icons.menu_rounded, size: 24),
                        onPressed: onOpenMenu,
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 24),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Thùng rác',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: AppColors.text),
                      ),
                    ),
                    if (deletedNotes.isNotEmpty && onEmptyTrash != null)
                      OutlinedButton.icon(
                        onPressed: onEmptyTrash,
                        icon: const Icon(Icons.delete_forever, size: 16, color: AppColors.danger),
                        label: Text(isNarrow ? 'Dọn rác' : 'Dọn sạch thùng rác', style: const TextStyle(color: AppColors.danger)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.danger),
                          padding: EdgeInsets.symmetric(horizontal: isNarrow ? 8 : 12, vertical: 6),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 6),
            const Text(
              'Các ghi chú đã xóa sẽ được lưu trữ an toàn tại đây (Tombstone Soft-Delete) và có thể khôi phục bất cứ lúc nào.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 20),

            if (deletedNotes.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      const Icon(Icons.auto_delete_outlined, size: 48, color: AppColors.muted),
                      const SizedBox(height: 12),
                      const Text(
                        'Thùng rác trống. Không có ghi chú nào bị xóa.',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: deletedNotes.length,
                itemBuilder: (ctx, idx) {
                  final n = deletedNotes[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(
                        n.title.isEmpty ? 'Ghi chú chưa có tiêu đề' : n.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        n.content.replaceAll('\n', ' ').trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton.icon(
                            onPressed: () => onRestoreNote(n),
                            icon: const Icon(Icons.restore, size: 14),
                            label: const Text('Khôi phục'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Xóa vĩnh viễn',
                            icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
                            onPressed: () => onPermanentDelete(n),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
