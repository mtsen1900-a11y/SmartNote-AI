import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/note.dart';
import '../services/auth_service.dart';

class DashboardView extends StatefulWidget {
  final List<Note> notes;
  final AuthService? authService;
  final ValueChanged<Note> onSelectNote;
  final VoidCallback onNewNote;
  final VoidCallback onOpenKnowledgeGraph;
  final VoidCallback onOpenIngestDialog;
  final VoidCallback onOpenAi;
  final ValueChanged<String>? onQuickCapture;
  final VoidCallback? onOpenMenu;

  const DashboardView({
    super.key,
    required this.notes,
    this.authService,
    required this.onSelectNote,
    required this.onNewNote,
    required this.onOpenKnowledgeGraph,
    required this.onOpenIngestDialog,
    required this.onOpenAi,
    this.onQuickCapture,
    this.onOpenMenu,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final TextEditingController _quickCaptureController = TextEditingController();

  @override
  void dispose() {
    _quickCaptureController.dispose();
    super.dispose();
  }

  void _submitQuickCapture() {
    final text = _quickCaptureController.text.trim();
    if (text.isEmpty) return;
    widget.onQuickCapture?.call(text);
    _quickCaptureController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⚡ Đã ghi nhanh ý tưởng vào kho ghi chú!'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.authService?.currentUser?.username ?? 'bạn';
    final totalNotes = widget.notes.length;
    final totalFolders = widget.notes.map((n) => n.folder).toSet().length;
    final totalTags = widget.notes.expand((n) => n.tags).toSet().length;

    // Tính số việc cần làm thực tế từ các dòng - [ ] trong nội dung ghi chú
    int pendingTasks = 0;
    for (final n in widget.notes) {
      final matches = RegExp(r'-\s*\[\s*\]').allMatches(n.content);
      pendingTasks += matches.length;
    }

    final pinnedNotes = widget.notes.where((n) => n.isPinned).toList();
    final recentNotes = List<Note>.from(widget.notes)..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header & Quick Action
            Row(
              children: [
                if (widget.onOpenMenu != null) ...[
                  IconButton(
                    tooltip: 'Mở danh mục',
                    icon: const Icon(Icons.menu_rounded, size: 26, color: AppColors.text),
                    onPressed: widget.onOpenMenu,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chào, $username 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Chào mừng bạn đến với Nền tảng Tri thức Thông minh SmartNoteAI SaaS.',
                        style: TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: widget.onNewNote,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ghi chú mới'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Metrics Cards Row (4 thẻ thống kê dữ liệu thật)
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                return GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isWide ? 1.6 : 1.3,
                  children: [
                    _metricCard('Tổng ghi chú', '$totalNotes', Icons.description_outlined, AppColors.primary),
                    _metricCard('Thư mục', '$totalFolders', Icons.folder_open_outlined, AppColors.accentPurple),
                    _metricCard('Thẻ Tags', '$totalTags', Icons.label_outline, AppColors.accentAmber),
                    _metricCard('Việc cần làm', '$pendingTasks', Icons.check_circle_outline, AppColors.accentEmerald),
                  ],
                );
              },
            ),

            const SizedBox(height: 18),

            // Quick Capture Input (Ghi nhanh tức thì)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: AppColors.accentAmber, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _quickCaptureController,
                      decoration: const InputDecoration(
                        hintText: 'Ghi nhanh ý tưởng hoặc việc cần làm (nhấn Enter để lưu)...',
                        hintStyle: TextStyle(fontSize: 13, color: AppColors.muted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _submitQuickCapture(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: _submitQuickCapture,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Lưu nhanh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions Bar
            const Text(
              'Hành động nhanh',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _quickActionButton(
                  icon: Icons.cloud_download_outlined,
                  label: 'Nạp dữ liệu (Ingest Web/File)',
                  color: AppColors.primary,
                  onTap: widget.onOpenIngestDialog,
                ),
                _quickActionButton(
                  icon: Icons.hub_outlined,
                  label: 'Khám phá Bản đồ tri thức',
                  color: AppColors.accentPurple,
                  onTap: widget.onOpenKnowledgeGraph,
                ),
                _quickActionButton(
                  icon: Icons.auto_awesome,
                  label: 'Hỏi đáp AI / RAG Chat',
                  color: AppColors.accentAmber,
                  onTap: widget.onOpenAi,
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Pinned Notes
            if (pinnedNotes.isNotEmpty) ...[
              const Row(
                children: [
                  Icon(Icons.push_pin, size: 16, color: AppColors.accentAmber),
                  SizedBox(width: 6),
                  Text(
                    'Ghi chú đã ghim',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: pinnedNotes.length,
                  itemBuilder: (ctx, idx) {
                    final n = pinnedNotes[idx];
                    return InkWell(
                      onTap: () => widget.onSelectNote(n),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 220,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title.isEmpty ? 'Chưa có tiêu đề' : n.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Text(
                                n.content.replaceAll('\n', ' ').trim(),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Recent Notes List
            const Text(
              'Ghi chú cập nhật gần đây',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text),
            ),
            const SizedBox(height: 10),
            if (recentNotes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Chưa có ghi chú nào. Hãy tạo ghi chú đầu tiên!', style: TextStyle(color: AppColors.muted)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentNotes.take(6).length,
                itemBuilder: (ctx, idx) {
                  final n = recentNotes[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => widget.onSelectNote(n),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.softSurface,
                        child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 18),
                      ),
                      title: Text(
                        n.title.isEmpty ? 'Ghi chú chưa có tiêu đề' : n.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      subtitle: Text(
                        '${n.folder} · ${n.wordCount} từ',
                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.subtle),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
