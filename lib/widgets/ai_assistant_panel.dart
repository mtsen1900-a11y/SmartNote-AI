import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_theme.dart';
import '../models/note.dart';
import '../services/ai_api_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final List<String> sources;
  final String intent;
  final Map<String, dynamic>? toolAction;
  final Map<String, dynamic>? resultData;
  bool actionConfirmed;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.sources = const [],
    this.intent = 'knowledge_rag',
    this.toolAction,
    this.resultData,
    this.actionConfirmed = false,
  });
}

class AiAssistantPanel extends StatefulWidget {
  const AiAssistantPanel({
    super.key,
    required this.note,
    required this.onClose,
    required this.onApplyTags,
    this.onInsertText,
    this.onCreateNoteWithData,
    this.onOpenFlashcards,
    this.aiApiService,
  });

  final Note note;
  final VoidCallback onClose;
  final ValueChanged<List<String>> onApplyTags;
  final ValueChanged<String>? onInsertText;
  final void Function({required String title, required String content, String? folder, List<String>? tags})?
      onCreateNoteWithData;
  final VoidCallback? onOpenFlashcards;
  final AiApiService? aiApiService;

  @override
  State<AiAssistantPanel> createState() => _AiAssistantPanelState();
}

class _AiAssistantPanelState extends State<AiAssistantPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _chipScrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isProcessing = false;
  String? _actionResult;
  String _scope = 'all'; // 'all' (Toàn bộ kho tri thức) | 'current' (Ghi chú hiện tại)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _questionController.dispose();
    _scrollController.dispose();
    _chipScrollController.dispose();
    super.dispose();
  }

  AiApiService get _apiService =>
      widget.aiApiService ?? AiApiService(getAuthToken: () => null);

  Future<void> _sendQuestion([String? directText]) async {
    final query = (directText ?? _questionController.text).trim();
    if (query.isEmpty || _isProcessing) return;

    setState(() {
      _messages.add(ChatMessage(text: query, isUser: true));
      _isProcessing = true;
      if (directText == null) _questionController.clear();
    });
    _scrollToBottom();

    final dynamic noteId = _scope == 'current' ? widget.note.id : null;
    final res = await _apiService.askAi(query, noteId: noteId);

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _messages.add(ChatMessage(
        text: res.answer,
        isUser: false,
        sources: res.sourceTitles,
        intent: res.intent,
        toolAction: res.toolAction,
        resultData: res.resultData,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _executeAction(String actionName, String promptAction) async {
    setState(() {
      _isProcessing = true;
      _actionResult = null;
    });

    String result;
    if (promptAction == 'summarize') {
      result = await _apiService.summarize(widget.note.content);
    } else {
      result = await _apiService.writingAssist(widget.note.content, promptAction);
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _actionResult = result;
    });
  }

  void _confirmCreateNote(ChatMessage msg) {
    if (msg.toolAction == null) return;
    final params = msg.toolAction!['parameters'] as Map<String, dynamic>? ?? {};
    final title = params['title']?.toString() ?? 'Ghi chú từ AI';
    final content = params['content']?.toString() ?? '';
    final folder = params['folder']?.toString() ?? 'Ý tưởng';
    final tagsRaw = params['tags'] as List<dynamic>? ?? [];
    final tags = tagsRaw.map((e) => e.toString()).toList();

    widget.onCreateNoteWithData?.call(
      title: title,
      content: content,
      folder: folder,
      tags: tags,
    );

    setState(() {
      msg.actionConfirmed = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Đã lưu ghi chú "$title" vào kho tri thức của bạn!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebar,
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF6366F1)),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Trợ Lý Tri Thức AI & RAG',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
          ),

          // Scope Selector Bar (Phạm vi truy vấn tri thức)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.softSurface,
              border: const Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, size: 14, color: AppColors.muted),
                const SizedBox(width: 6),
                const Text('Phạm vi: ', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                const SizedBox(width: 4),
                Expanded(
                  child: DropdownButton<String>(
                    value: _scope,
                    isDense: true,
                    isExpanded: true,
                    underline: const SizedBox(),
                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('🌐 Toàn bộ kho tri thức cá nhân', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'current',
                        child: Text(
                          '📄 Ghi chú này: ${widget.note.displayTitle}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _scope = v ?? 'all'),
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF6366F1),
            unselectedLabelColor: AppColors.muted,
            indicatorColor: const Color(0xFF6366F1),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Trò chuyện NLU & RAG'),
              Tab(text: 'Trợ lý viết AI'),
            ],
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatTab(),
                _buildWritingActionsTab(),
              ],
            ),
          ),

          // Footer Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: 13, color: Color(0xFF10B981)),
                SizedBox(width: 6),
                Text(
                  'User Isolation: RAG chỉ truy xuất dữ liệu của bạn',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.psychology_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Hỏi bất kỳ điều gì bằng tiếng Việt tự nhiên.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'AI hiểu các yêu cầu: Tạo ghi chú mới, Tóm tắt, Lập việc cần làm, Tạo Flashcard, Tìm kiếm nội dung tương tự.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.subtle, fontSize: 11, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                )
              : ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                      PointerDeviceKind.stylus,
                    },
                  ),
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    interactive: true,
                    thickness: 6,
                    radius: const Radius.circular(3),
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return _buildMessageItem(msg);
                      },
                    ),
                  ),
                ),
        ),

        // Quick Suggestion Chips (Hỗ trợ kéo chuột trên Web & cảm ứng điện thoại)
        Container(
          height: 38,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
            ),
            child: ListView(
              controller: _chipScrollController,
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _quickChip('💡 Tóm tắt ý', 'Hãy tóm tắt ngắn gọn các ý chính quan trọng'),
                _quickChip('✅ Lập việc cần làm', 'Lập danh sách việc cần làm (To-Do list) từ nội dung này'),
                _quickChip('🗂️ Tạo thẻ Flashcard', 'Tạo thẻ Flashcard ôn tập từ ghi chú này'),
                _quickChip('📝 Tạo ghi chú mới', 'Tạo một ghi chú mới tóm tắt dự án'),
              ],
            ),
          ),
        ),

        if (_isProcessing)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: LinearProgressIndicator(color: Color(0xFF6366F1), minHeight: 2),
          ),

        // Input Bar
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _questionController,
                  decoration: InputDecoration(
                    hintText: _scope == 'current' ? 'Hỏi về ghi chú này...' : 'Hỏi AI trên toàn bộ tri thức...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onSubmitted: (_) => _sendQuestion(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isProcessing ? null : () => _sendQuestion(),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
                      )
                    : const Icon(Icons.send_rounded, color: Color(0xFF6366F1)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickChip(String label, String prompt) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.border),
        onPressed: _isProcessing ? null : () => _sendQuestion(prompt),
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: msg.isUser ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: msg.isUser ? null : Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              msg.text,
              style: TextStyle(
                color: msg.isUser ? Colors.white : AppColors.text,
                fontSize: 13,
                height: 1.45,
              ),
            ),

            // Tool Action: Đề xuất tạo ghi chú mới có xác nhận
            if (!msg.isUser && msg.toolAction != null && msg.toolAction!['name'] == 'create_note') ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.softSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.note_add_outlined, size: 16, color: Color(0xFF6366F1)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            msg.toolAction!['parameters']?['title'] ?? 'Dự thảo ghi chú mới',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      msg.toolAction!['parameters']?['content'] ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                    const SizedBox(height: 10),
                    if (msg.actionConfirmed)
                      const Row(
                        children: [
                          Icon(Icons.check_circle, size: 14, color: AppColors.accentEmerald),
                          SizedBox(width: 4),
                          Text('Đã lưu thành công!', style: TextStyle(fontSize: 11, color: AppColors.accentEmerald, fontWeight: FontWeight.bold)),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FilledButton.icon(
                            onPressed: () => _confirmCreateNote(msg),
                            icon: const Icon(Icons.check, size: 14),
                            label: const Text('Xác nhận lưu', style: TextStyle(fontSize: 11)),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],

            // Action: Nút mở Flashcards nếu sinh ra thẻ học
            if (!msg.isUser && msg.intent == 'generate_flashcards' && widget.onOpenFlashcards != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: widget.onOpenFlashcards,
                icon: const Icon(Icons.style_outlined, size: 14, color: Color(0xFF6366F1)),
                label: const Text('Mở màn hình Ôn tập Flashcard', style: TextStyle(fontSize: 11, color: Color(0xFF6366F1))),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],

            // Source Citations
            if (msg.sources.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Nguồn tham khảo:', style: TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: msg.sources
                    .map(
                      (s) => Chip(
                        avatar: const Icon(Icons.bookmark_border, size: 12, color: AppColors.primary),
                        label: Text(s, style: const TextStyle(fontSize: 10)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: AppColors.softSurface,
                      ),
                    )
                    .toList(),
              ),
            ],

            // Message Actions (Sao chép, Chèn vào bài)
            if (!msg.isUser) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: msg.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('📋 Đã sao chép câu trả lời!'), duration: Duration(seconds: 1)),
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Row(
                        children: [
                          Icon(Icons.copy_rounded, size: 12, color: AppColors.muted),
                          SizedBox(width: 4),
                          Text('Sao chép', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                        ],
                      ),
                    ),
                  ),
                  if (widget.onInsertText != null) ...[
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => widget.onInsertText!(msg.text),
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Row(
                          children: [
                            Icon(Icons.add_circle_outline, size: 12, color: Color(0xFF6366F1)),
                            SizedBox(width: 4),
                            Text('Chèn vào bài', style: TextStyle(fontSize: 10, color: Color(0xFF6366F1))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWritingActionsTab() {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      child: Scrollbar(
        thumbVisibility: true,
        thickness: 6,
        radius: const Radius.circular(3),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'CÔNG CỤ VIẾT THÔNG MINH',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.muted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _actionTile('Tóm tắt ghi chú', 'summarize', Icons.short_text_rounded),
          _actionTile('Trau chuốt văn phong', 'improve', Icons.auto_fix_high_rounded),
          _actionTile('Sửa lỗi chính tả', 'fix_spelling', Icons.spellcheck_rounded),
          _actionTile('Chuyển thành Checklist', 'checklist', Icons.checklist_rounded),
          _actionTile('Lập Kế hoạch Hành động', 'action_plan', Icons.assignment_outlined),
          const SizedBox(height: 16),
          if (_actionResult != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kết quả từ AI:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      if (widget.onInsertText != null)
                        TextButton.icon(
                          onPressed: () => widget.onInsertText!(_actionResult!),
                          icon: const Icon(Icons.add_circle_outline, size: 14),
                          label: const Text('Chèn vào bài', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(_actionResult!, style: const TextStyle(fontSize: 13, height: 1.5)),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  ),
);
  }

  Widget _actionTile(String title, String actionCode, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : () => _executeAction(title, actionCode),
        icon: Icon(icon, size: 18),
        label: Align(alignment: Alignment.centerLeft, child: Text(title)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }
}
