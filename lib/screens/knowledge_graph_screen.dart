import 'dart:math';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/note.dart';

class GraphNode {
  final String id;
  final String label;
  final String type; // 'hub', 'folder', 'note', 'tag'
  final Color color;
  double x;
  double y;

  GraphNode({
    required this.id,
    required this.label,
    required this.type,
    required this.color,
    this.x = 0,
    this.y = 0,
  });
}

class GraphEdge {
  final String source;
  final String target;
  GraphEdge({required this.source, required this.target});
}

class KnowledgeGraphScreen extends StatefulWidget {
  final List<Note> notes;
  final Function(String noteId)? onSelectNote;

  const KnowledgeGraphScreen({
    super.key,
    required this.notes,
    this.onSelectNote,
  });

  @override
  State<KnowledgeGraphScreen> createState() => _KnowledgeGraphScreenState();
}

class _KnowledgeGraphScreenState extends State<KnowledgeGraphScreen> {
  int _viewMode = 0; // 0 = Sơ đồ cây cấu trúc (Tree View), 1 = Mạng lưới nơ-ron (Network Graph)
  final List<GraphNode> _nodes = [];
  final List<GraphEdge> _edges = [];
  GraphNode? _selectedNode;

  @override
  void initState() {
    super.initState();
    _buildGraph();
  }

  void _buildGraph() {
    _nodes.clear();
    _edges.clear();

    const double centerX = 200;
    const double centerY = 240;
    final random = Random(42);

    // 1. Hub trung tâm
    _nodes.add(GraphNode(
      id: "hub",
      label: "SmartNoteAI Hub",
      type: "hub",
      color: AppColors.primary,
      x: centerX,
      y: centerY,
    ));

    // 2. Thư mục (Folders)
    final folders = widget.notes.map((n) => n.folder).toSet().toList();
    for (int i = 0; i < folders.length; i++) {
      final f = folders[i];
      final angle = (i * 2 * pi) / (folders.isEmpty ? 1 : folders.length);
      final fx = centerX + 110 * cos(angle);
      final fy = centerY + 110 * sin(angle);

      _nodes.add(GraphNode(
        id: "folder-$f",
        label: f,
        type: "folder",
        color: AppColors.accentPurple,
        x: fx,
        y: fy,
      ));
      _edges.add(GraphEdge(source: "hub", target: "folder-$f"));
    }

    // 3. Ghi chú (Notes) & Tags
    for (var n in widget.notes) {
      final angle = random.nextDouble() * 2 * pi;
      final dist = 80 + random.nextDouble() * 110;
      final nx = centerX + dist * cos(angle);
      final ny = centerY + dist * sin(angle);

      _nodes.add(GraphNode(
        id: "note-${n.id}",
        label: n.title,
        type: "note",
        color: AppColors.accentEmerald,
        x: nx,
        y: ny,
      ));
      _edges.add(GraphEdge(source: "folder-${n.folder}", target: "note-${n.id}"));

      for (var t in n.tags) {
        final tagId = "tag-$t";
        if (!_nodes.any((node) => node.id == tagId)) {
          final tx = nx + 40 * cos(random.nextDouble() * 2 * pi);
          final ty = ny + 40 * sin(random.nextDouble() * 2 * pi);
          _nodes.add(GraphNode(
            id: tagId,
            label: "#$t",
            type: "tag",
            color: AppColors.accentAmber,
            x: tx,
            y: ty,
          ));
        }
        _edges.add(GraphEdge(source: "note-${n.id}", target: tagId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.account_tree_outlined, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Sơ Đồ Cây Cấu Trúc & Bản Đồ Tri Thức",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.only(bottom: 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(
                  value: 0,
                  icon: Icon(Icons.account_tree_rounded, size: 16),
                  label: Text('Sơ đồ cây phân nhánh'),
                ),
                ButtonSegment<int>(
                  value: 1,
                  icon: Icon(Icons.hub_outlined, size: 16),
                  label: Text('Đồ thị mạng liên kết'),
                ),
              ],
              selected: {_viewMode},
              onSelectionChanged: (set) => setState(() => _viewMode = set.first),
            ),
          ),
        ),
      ),
      body: _viewMode == 0 ? _buildTreeView() : _buildNetworkGraphView(),
    );
  }

  /// Chế độ xem Sơ đồ cây phân nhánh (Tree View): Cấu trúc app & cây thư mục hoàn chỉnh
  Widget _buildTreeView() {
    // Gom nhóm ghi chú theo thư mục
    final Map<String, List<Note>> folderGroups = {};
    for (final n in widget.notes) {
      final f = n.folder.isNotEmpty ? n.folder : 'Chung';
      folderGroups.putIfAbsent(f, () => []).add(n);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Gốc ứng dụng (Root Node)
              _treeCard(
                icon: Icons.computer_rounded,
                iconColor: const Color(0xFF6366F1),
                bgColor: const Color(0xFFEEF2FF),
                title: 'SmartNoteAI — Kiến trúc Hệ thống & Kho Tri thức Cục bộ',
                subtitle: 'Lưu trữ phân tầng: Drift SQLite Wasm (Cục bộ 0ms) + ChromaDB (Vector Search)',
                badge: '${widget.notes.length} ghi chú',
                isRoot: true,
              ),

              const SizedBox(height: 12),
              _treeDivider('HẠ TẦNG DỊCH VỤ VẬN HÀNH (INFRASTRUCTURE)'),
              const SizedBox(height: 8),

              // Nhánh Hạ tầng: hiển thị 2x2 trên mobile và 1x4 trên desktop
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  if (isMobile) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _serviceMiniCard(
                                title: 'Frontend Web',
                                subtitle: 'Flutter CanvasKit',
                                port: 'Port 50563',
                                statusColor: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _serviceMiniCard(
                                title: 'FastAPI Backend',
                                subtitle: 'Gateway & Sync',
                                port: 'Port 8000',
                                statusColor: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _serviceMiniCard(
                                title: 'ChromaDB',
                                subtitle: 'Vector Storage RAG',
                                port: 'Port 8002',
                                statusColor: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _serviceMiniCard(
                                title: 'Ollama Server',
                                subtitle: 'qwen2.5:3b Local AI',
                                port: 'Port 11434',
                                statusColor: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: _serviceMiniCard(
                          title: 'Frontend Web',
                          subtitle: 'Flutter CanvasKit / Wasm',
                          port: 'Port 50563',
                          statusColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _serviceMiniCard(
                          title: 'FastAPI Backend',
                          subtitle: 'Gateway & Sync Engine',
                          port: 'Port 8000',
                          statusColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _serviceMiniCard(
                          title: 'ChromaDB',
                          subtitle: 'Vector Storage RAG',
                          port: 'Port 8002',
                          statusColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _serviceMiniCard(
                          title: 'Ollama Server',
                          subtitle: 'qwen2.5:3b Local AI',
                          port: 'Port 11434',
                          statusColor: Colors.green,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),
              _treeDivider('CÂY PHÂN NHÁNH THƯ MỤC LƯU TRỮ (DIRECTORY HIERARCHY)'),
              const SizedBox(height: 12),

              if (folderGroups.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(
                    child: Text(
                      'Chưa có thư mục hay ghi chú nào được tạo.\nBạn hãy bấm "+ Ghi chú mới" để bắt đầu xây dựng cây tri thức!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                // Cây phân nhánh từng thư mục
                for (final entry in folderGroups.entries) ...[
                  _buildFolderBranch(entry.key, entry.value),
                  const SizedBox(height: 14),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderBranch(String folderName, List<Note> notes) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.folder_rounded, color: Color(0xFFD97706), size: 20),
        ),
        title: Text(
          'Thư mục: $folderName',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          'Chứa ${notes.length} tệp • Lưu tại Drift SQLite (Table: notes) & Chroma Collection',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          const Divider(height: 1),
          for (final note in notes)
            InkWell(
              onTap: () {
                if (widget.onSelectNote != null) {
                  Navigator.pop(context);
                  widget.onSelectNote!(note.id);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.subdirectory_arrow_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 8),
                    const Icon(Icons.description_outlined, size: 16, color: Color(0xFF6366F1)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title.isNotEmpty ? note.title : 'Ghi chú chưa có tiêu đề',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            '${note.wordCount} từ • Cập nhật: ${note.updatedAt.day}/${note.updatedAt.month}/${note.updatedAt.year}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                    if (note.isPinned)
                      const Icon(Icons.push_pin, size: 14, color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    const Text('Mở xem ↗', style: TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _treeDivider(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, color: const Color(0xFF6366F1)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const SizedBox(
          width: 32,
          child: Divider(),
        ),
      ],
    );
  }

  Widget _treeCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required String badge,
    bool isRoot = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRoot ? const Color(0xFF818CF8) : const Color(0xFFE2E8F0),
          width: isRoot ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: isRoot ? 0.08 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(badge, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          ),
        ],
      ),
    );
  }

  Widget _serviceMiniCard({
    required String title,
    required String subtitle,
    required String port,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 3.5, backgroundColor: statusColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(port, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF6366F1))),
          Text(subtitle, style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  /// Chế độ xem Mạng lưới nơ-ron (Network Graph cũ)
  Widget _buildNetworkGraphView() {
    return Stack(
      children: [
        CustomPaint(
          size: Size.infinite,
          painter: _NetworkGraphPainter(nodes: _nodes, edges: _edges),
        ),
        for (var node in _nodes)
          Positioned(
            left: node.x - 24,
            top: node.y - 24,
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedNode = node);
                if (node.type == 'note' && widget.onSelectNote != null) {
                  final noteId = node.id.replaceFirst('note-', '');
                  widget.onSelectNote!(noteId);
                }
              },
              child: Tooltip(
                message: "${node.label} (${node.type})",
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: node.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedNode?.id == node.id ? Colors.white : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: node.color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      node.type == 'hub'
                          ? Icons.hub
                          : node.type == 'folder'
                              ? Icons.folder
                              : node.type == 'tag'
                                  ? Icons.tag
                                  : Icons.description,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NetworkGraphPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;

  _NetworkGraphPainter({required this.nodes, required this.edges});

  @override
  void paint(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 1.5;

    for (var edge in edges) {
      final s = nodes.firstWhere((n) => n.id == edge.source, orElse: () => nodes.first);
      final t = nodes.firstWhere((n) => n.id == edge.target, orElse: () => nodes.first);
      canvas.drawLine(Offset(s.x, s.y), Offset(t.x, t.y), edgePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
