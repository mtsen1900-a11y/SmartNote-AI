import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/note.dart';

class TaskItem {
  final String noteId;
  final String noteTitle;
  final String folder;
  final String taskText;
  final bool isCompleted;
  final int lineIndex;

  TaskItem({
    required this.noteId,
    required this.noteTitle,
    required this.folder,
    required this.taskText,
    required this.isCompleted,
    required this.lineIndex,
  });
}

class TasksView extends StatefulWidget {
  final List<Note> notes;
  final Function(String noteId, String oldText, String newText) onToggleTask;
  final VoidCallback? onOpenMenu;
  final VoidCallback? onBackToDashboard;
  final ValueChanged<String>? onAddNewTask;

  const TasksView({
    super.key,
    required this.notes,
    required this.onToggleTask,
    this.onOpenMenu,
    this.onBackToDashboard,
    this.onAddNewTask,
  });

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> {
  String _filter = 'all'; // 'all' | 'pending' | 'completed'
  final TextEditingController _taskInputController = TextEditingController();

  @override
  void dispose() {
    _taskInputController.dispose();
    super.dispose();
  }

  void _submitNewTask() {
    final text = _taskInputController.text.trim();
    if (text.isEmpty) return;
    widget.onAddNewTask?.call(text);
    _taskInputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Trích xuất tất cả các dòng task từ toàn bộ ghi chú
    final List<TaskItem> allTasks = [];
    for (final note in widget.notes) {
      final lines = note.content.split('\n');
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        final matchUnchecked = RegExp(r'^-\s*\[\s*\]\s+(.*)$').firstMatch(line);
        final matchChecked = RegExp(r'^-\s*\[[xX]\]\s+(.*)$').firstMatch(line);

        if (matchUnchecked != null) {
          allTasks.add(TaskItem(
            noteId: note.id,
            noteTitle: note.title,
            folder: note.folder,
            taskText: matchUnchecked.group(1) ?? '',
            isCompleted: false,
            lineIndex: i,
          ));
        } else if (matchChecked != null) {
          allTasks.add(TaskItem(
            noteId: note.id,
            noteTitle: note.title,
            folder: note.folder,
            taskText: matchChecked.group(1) ?? '',
            isCompleted: true,
            lineIndex: i,
          ));
        }
      }
    }

    final completedCount = allTasks.where((t) => t.isCompleted).length;
    final pendingCount = allTasks.length - completedCount;

    final displayedTasks = allTasks.where((t) {
      if (_filter == 'pending') return !t.isCompleted;
      if (_filter == 'completed') return t.isCompleted;
      return true;
    }).toList();

    final progressRatio = allTasks.isEmpty ? 0.0 : (completedCount / allTasks.length);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header có cả nút Thoát ⬅️ và nút Home 🏠
            Row(
              children: [
                if (widget.onBackToDashboard != null) ...[
                  IconButton(
                    tooltip: 'Quay lại',
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                    onPressed: widget.onBackToDashboard,
                  ),
                  IconButton(
                    tooltip: 'Về trang chủ',
                    icon: const Icon(Icons.home_rounded, size: 22, color: AppColors.primary),
                    onPressed: widget.onBackToDashboard,
                  ),
                  const SizedBox(width: 4),
                ] else if (widget.onOpenMenu != null) ...[
                  IconButton(
                    icon: const Icon(Icons.menu_rounded, size: 24),
                    onPressed: widget.onOpenMenu,
                  ),
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.check_circle_outline, color: AppColors.accentEmerald, size: 24),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Việc cần làm (Checklist)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: AppColors.text),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Thanh nhập việc cần làm mới trực tiếp
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_task_rounded, color: AppColors.accentEmerald, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _taskInputController,
                      onSubmitted: (_) => _submitNewTask(),
                      decoration: const InputDecoration(
                        hintText: 'Nhập việc cần làm mới (nhấn Enter để thêm)...',
                        border: InputBorder.none,
                        isDense: true,
                        hintStyle: TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  ),
                  FilledButton(
                    onPressed: _submitNewTask,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentEmerald,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Thêm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Thanh tiến độ tự động
            if (allTasks.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tiến độ công việc',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text),
                        ),
                        Text(
                          '$completedCount/${allTasks.length} việc (${(progressRatio * 100).toInt()}%)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentEmerald),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressRatio,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentEmerald),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Metrics (Bấm vào để lọc nhanh)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _metricBadge('Chờ thực hiện', '$pendingCount', AppColors.accentAmber, isSelected: _filter == 'pending', onTap: () => setState(() => _filter = 'pending')),
                  const SizedBox(width: 12),
                  _metricBadge('Đã hoàn thành', '$completedCount', AppColors.accentEmerald, isSelected: _filter == 'completed', onTap: () => setState(() => _filter = 'completed')),
                  const SizedBox(width: 12),
                  _metricBadge('Tổng số việc', '${allTasks.length}', AppColors.primary, isSelected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('Tất cả (${allTasks.length})', 'all'),
                  const SizedBox(width: 8),
                  _filterChip('Chờ làm ($pendingCount)', 'pending'),
                  const SizedBox(width: 8),
                  _filterChip('Đã xong ($completedCount)', 'completed'),
                ],
              ),
            ),
            const SizedBox(height: 18),

            if (displayedTasks.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const Icon(Icons.task_alt, size: 48, color: AppColors.muted),
                      const SizedBox(height: 12),
                      Text(
                        _filter == 'pending'
                            ? 'Tuyệt vời! Bạn không còn việc nào đang chờ thực hiện.'
                            : (_filter == 'completed'
                                ? 'Chưa có công việc nào được hoàn thành.'
                                : 'Chưa có công việc nào!\nĐể tạo việc cần làm, trong ghi chú hãy gõ cú pháp "- [ ] Tên việc cần làm".'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayedTasks.length,
                itemBuilder: (ctx, idx) {
                  final task = displayedTasks[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      value: task.isCompleted,
                      activeColor: AppColors.accentEmerald,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (val) {
                        final oldPrefix = task.isCompleted ? '- [x] ' : '- [ ] ';
                        final newPrefix = task.isCompleted ? '- [ ] ' : '- [x] ';
                        widget.onToggleTask(task.noteId, '$oldPrefix${task.taskText}', '$newPrefix${task.taskText}');
                      },
                      title: Text(
                        task.taskText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          color: task.isCompleted ? AppColors.muted : AppColors.text,
                        ),
                      ),
                      subtitle: Text(
                        'Ghi chú: ${task.noteTitle} · ${task.folder}',
                        style: const TextStyle(fontSize: 11, color: AppColors.subtle),
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

  Widget _filterChip(String label, String value) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? Colors.white : AppColors.text,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _metricBadge(String label, String value, Color color, {bool isSelected = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.25) : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.25), width: isSelected ? 1.5 : 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label: ', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
            Text(value, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
