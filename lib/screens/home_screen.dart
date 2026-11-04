import 'dart:async';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/note.dart';
import '../services/note_storage.dart';
import '../services/auth_service.dart';
import '../services/ai_api_service.dart';
import '../widgets/ai_assistant_panel.dart';
import '../widgets/note_editor.dart';
import '../widgets/notes_sidebar.dart';
import '../widgets/data_ingestion_dialog.dart';
import '../widgets/tasks_view.dart';
import '../widgets/trash_view.dart';
import '../widgets/right_action_panel.dart';
import '../ui_refinement/widgets/refined_dashboard_view.dart';
import '../ui_refinement/widgets/apple_notes_gallery_view.dart';
import '../ui_refinement/guest/guest_session.dart';
import 'knowledge_graph_screen.dart';
import 'flashcard_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthService? authService;

  const HomeScreen({super.key, this.authService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _storage = NoteStorage();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _searchController = TextEditingController();
  late final AiApiService _aiApiService;

  List<Note> _notes = [];
  final List<Note> _deletedNotes = [];
  String? _selectedId;
  String? _selectedTag;
  String _searchQuery = '';
  String _currentView = 'dashboard'; // 'dashboard' | 'notes'
  String _savingStatus = 'Đã lưu';
  bool _showAiPanel = false;
  bool _isLoading = true;
  Timer? _saveDebounce;

  Note? get _selectedNote {
    for (final note in _notes) {
      if (note.id == _selectedId) return note;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _aiApiService = AiApiService(getAuthToken: () => widget.authService?.accessToken);
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    List<Note>? stored;
    try {
      stored = await _storage.load();
    } catch (_) {
      stored = null;
    }
    if (!mounted) return;
    // Lọc bỏ các file mẫu tạo sẵn nếu có theo yêu cầu người dùng
    var list = stored ?? _sampleNotes();
    list = list.where((n) {
      final title = n.title.trim().toLowerCase();
      return !title.contains('chào mừng đến với smartnoteai') &&
          !title.contains('kế hoạch phát triển tính năng sprint');
    }).toList();

    setState(() {
      _notes = list;
      _selectedId = list.isEmpty ? null : list.first.id;
      _isLoading = false;
    });
    _setControllers(_selectedNote);
    if (stored == null && list.isNotEmpty) _queueSave();
    // Đồng bộ vector ghi chú vào ChromaDB cho AI RAG
    for (final n in list) {
      _aiApiService.indexNote(noteId: n.id, title: n.title, content: n.content);
    }
  }

  Timer? _snackBarTimer;

  void _showAppSnackBar(
    String text, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 10),
  }) {
    if (!mounted) return;
    _snackBarTimer?.cancel();
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duration,
        showCloseIcon: true,
        closeIconColor: Colors.white,
        margin: const EdgeInsets.only(bottom: 76, left: 16, right: 16),
        content: Text(text),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(label: actionLabel, onPressed: onAction)
            : null,
      ),
    );
    // Tự động tắt thông báo sau 10 giây bất kể môi trường
    _snackBarTimer = Timer(duration, () {
      if (mounted) {
        messenger.hideCurrentSnackBar();
      }
    });
  }

  void _setControllers(Note? note) {
    final title = note?.title ?? '';
    final content = note?.content ?? '';
    _titleController.value = TextEditingValue(
      text: title,
      selection: TextSelection.collapsed(offset: title.length),
    );
    _contentController.value = TextEditingValue(
      text: content,
      selection: TextSelection.collapsed(offset: content.length),
    );
  }

  void _queueSave() {
    setState(() => _savingStatus = 'Đang lưu...');
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), _saveNotes);
  }

  Future<void> _saveNotes() async {
    try {
      await _storage.save(List<Note>.from(_notes));
      if (mounted) setState(() => _savingStatus = 'Đã lưu');
      final curr = _selectedNote;
      if (curr != null) {
        _aiApiService.indexNote(noteId: curr.id, title: curr.title, content: curr.content);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _savingStatus = 'Lỗi lưu');
      _showAppSnackBar('Không lưu được dữ liệu cục bộ.');
    }
  }

  void _selectNote(Note note) {
    setState(() {
      _selectedId = note.id;
      _currentView = 'notes';
    });
    _setControllers(note);
    _closeDrawerIfOpen();
  }

  void _closeDrawerIfOpen() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _createNote() {
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Ghi chú mới',
      content: '',
      folder: 'Cá nhân',
      tags: const ['moi'],
      updatedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
    setState(() {
      _notes.insert(0, newNote);
      _selectedId = newNote.id;
      _currentView = 'notes';
    });
    _setControllers(newNote);
    _queueSave();
    _closeDrawerIfOpen();
  }

  void _createNoteWithData({
    required String title,
    required String content,
    String? folder,
    List<String>? tags,
  }) {
    final newNote = Note(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      content: content,
      folder: folder ?? 'Cá nhân',
      tags: tags ?? const ['ai-generated'],
      updatedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
    setState(() {
      _notes.insert(0, newNote);
      _selectedId = newNote.id;
      _currentView = 'notes';
    });
    _setControllers(newNote);
    _queueSave();
    _closeDrawerIfOpen();
  }

  void _renameFolder(String oldName, String newName) {
    setState(() {
      for (int i = 0; i < _notes.length; i++) {
        if (_notes[i].folder == oldName) {
          _notes[i] = _notes[i].copyWith(
            folder: newName,
            updatedAt: DateTime.now(),
          );
        }
      }
    });
    _queueSave();
  }

  void _deleteFolder(String folderName) {
    setState(() {
      for (int i = 0; i < _notes.length; i++) {
        if (_notes[i].folder == folderName) {
          _notes[i] = _notes[i].copyWith(
            folder: 'Cá nhân',
            updatedAt: DateTime.now(),
          );
        }
      }
    });
    _queueSave();
  }

  void _deleteSelected() {
    final current = _selectedNote;
    if (current == null) return;
    final index = _notes.indexWhere((note) => note.id == current.id);
    if (index == -1) return;

    final removed = _notes.removeAt(index);
    _deletedNotes.insert(0, removed);
    final next = _notes.isEmpty ? null : _notes[index.clamp(0, _notes.length - 1)];
    setState(() => _selectedId = next?.id);
    _setControllers(next);
    _queueSave();

    _showAppSnackBar(
      'Đã chuyển "${removed.title.isEmpty ? 'Ghi chú' : removed.title}" vào Thùng rác',
      actionLabel: 'Hoàn tác',
      onAction: () => _restoreNote(removed),
    );
  }

  void _restoreNote(Note note) {
    setState(() {
      _deletedNotes.removeWhere((n) => n.id == note.id);
      _notes.insert(0, note);
      _selectedId = note.id;
    });
    _setControllers(note);
    _queueSave();
    _showAppSnackBar('✅ Đã khôi phục "${note.title}"');
  }

  void _permanentDelete(Note note) {
    setState(() {
      _deletedNotes.removeWhere((n) => n.id == note.id);
    });
    _storage.deleteNote(note.id);
    _showAppSnackBar('Đã xóa vĩnh viễn "${note.title}"');
  }

  void _emptyTrash() {
    for (final n in _deletedNotes) {
      _storage.deleteNote(n.id);
    }
    setState(() => _deletedNotes.clear());
    _showAppSnackBar('Đã dọn sạch thùng rác.');
  }

  void _toggleTaskContent(String noteId, String oldText, String newText) {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index == -1) return;
    final note = _notes[index];
    final updatedContent = note.content.replaceFirst(oldText, newText);
    _editSelected(content: updatedContent);
    if (_selectedId == noteId) {
      _contentController.text = updatedContent;
    }
  }

  void _addNewTask(String text) {
    final existingIdx = _notes.indexWhere((n) =>
        n.title.toLowerCase().contains('việc cần làm') ||
        n.title.toLowerCase().contains('checklist'));
    if (existingIdx != -1) {
      final existingNote = _notes[existingIdx];
      final newContent = '${existingNote.content}\n- [ ] $text';
      final updated = existingNote.copyWith(
        content: newContent,
        updatedAt: DateTime.now(),
      );
      _notes[existingIdx] = updated;
      if (_selectedId == existingNote.id) {
        _setControllers(updated);
      }
    } else {
      final newNote = Note(
        id: 'tasks_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Danh sách việc cần làm (Checklist)',
        content: '# Danh sách việc cần làm\n\n- [ ] $text',
        folder: 'Công việc',
        tags: const ['todo', 'checklist'],
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      _notes.insert(0, newNote);
    }
    setState(() {});
    _queueSave();
    _showAppSnackBar('✅ Đã thêm việc: "$text"');
  }

  void _editSelected({String? title, String? content}) {
    final current = _selectedNote;
    if (current == null) return;
    final index = _notes.indexWhere((note) => note.id == current.id);
    if (index == -1) return;

    final updated = current.copyWith(
      title: title ?? current.title,
      content: content ?? current.content,
      updatedAt: DateTime.now(),
    );
    setState(() => _notes[index] = updated);
    _queueSave();
  }

  void _applyTags(List<String> tags) {
    final current = _selectedNote;
    if (current == null) return;
    final index = _notes.indexWhere((note) => note.id == current.id);
    if (index == -1) return;

    final updated = current.copyWith(
      tags: tags,
      updatedAt: DateTime.now(),
    );
    setState(() => _notes[index] = updated);
    _queueSave();
  }

  void _togglePinSelected() {
    final current = _selectedNote;
    if (current == null) return;
    final index = _notes.indexWhere((note) => note.id == current.id);
    if (index == -1) return;

    final updated = current.copyWith(
      isPinned: !current.isPinned,
      updatedAt: DateTime.now(),
    );
    setState(() => _notes[index] = updated);
    _queueSave();
  }

  void _changeFolderSelected(String folder) {
    final current = _selectedNote;
    if (current == null) return;
    final index = _notes.indexWhere((note) => note.id == current.id);
    if (index == -1) return;

    final updated = current.copyWith(
      folder: folder,
      updatedAt: DateTime.now(),
    );
    setState(() => _notes[index] = updated);
    _queueSave();
  }

  void _openKnowledgeGraph() {
    ScaffoldMessenger.of(context).clearSnackBars();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KnowledgeGraphScreen(
          notes: _notes,
          onSelectNote: (noteId) {
            final n = _notes.firstWhere((item) => item.id == noteId, orElse: () => _notes.first);
            _selectNote(n);
          },
        ),
      ),
    );
  }

  void _openIngestDialog() {
    ScaffoldMessenger.of(context).clearSnackBars();
    showDialog(
      context: context,
      builder: (_) => DataIngestionDialog(
        authService: widget.authService,
        onIngestSuccess: _loadNotes,
      ),
    );
  }

  void _openFlashcards() {
    final current = _selectedNote;
    if (current == null) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardScreen(
          note: current,
          aiService: _aiApiService,
        ),
      ),
    );
  }

  void _openAi() {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) {
      setState(() => _showAiPanel = !_showAiPanel);
      return;
    }
    final note = _selectedNote ??
        Note(
          id: '0',
          title: 'Tri thức chung',
          content: 'Tra cứu trên toàn bộ kho ghi chú',
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(14),
        clipBehavior: Clip.antiAlias,
        backgroundColor: AppColors.sidebar,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: SizedBox(
          width: 440,
          height: MediaQuery.sizeOf(dialogContext).height * 0.88,
          child: AiAssistantPanel(
            note: note,
            aiApiService: _aiApiService,
            onClose: () => Navigator.of(dialogContext).pop(),
            onApplyTags: (tags) {
              _applyTags(tags);
              Navigator.of(dialogContext).pop();
            },
            onInsertText: (txt) {
              final newContent = '${_contentController.text}\n\n$txt';
              _editSelected(content: newContent);
              _contentController.text = newContent;
            },
            onCreateNoteWithData: _createNoteWithData,
            onOpenFlashcards: _openFlashcards,
          ),
        ),
      ),
    );
  }

  void _editTags() {
    final current = _selectedNote;
    if (current == null) return;
    final controller = TextEditingController(text: current.tags.join(', '));
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chỉnh sửa thẻ'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nhập các thẻ, cách nhau bằng dấu phẩy',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final tags = controller.text
                  .split(',')
                  .map((t) => t.trim().toLowerCase())
                  .where((t) => t.isNotEmpty)
                  .toSet()
                  .toList();
              _applyTags(tags);
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _snackBarTimer?.cancel();
    _saveDebounce?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 760;
    final showDockedAi = width >= 1200 && _showAiPanel && _selectedNote != null;

    final sidebar = NotesSidebar(
      width: isMobile ? 310 : (width < 1050 ? 250 : 292),
      notes: _notes,
      selectedNoteId: _selectedId,
      selectedTag: _selectedTag,
      searchQuery: _searchQuery,
      searchController: _searchController,
      authService: widget.authService,
      currentView: _currentView,
      onViewChanged: (view) => setState(() => _currentView = view),
      onOpenKnowledgeGraph: _openKnowledgeGraph,
      onOpenIngestDialog: _openIngestDialog,
      onOpenAuth: () => GuestSession().exitGuestSession(),
      onSearchChanged: (query) => setState(() => _searchQuery = query),
      onSelectTag: (tag) {
        setState(() {
          _selectedTag = tag;
          _currentView = 'notes';
        });
        _closeDrawerIfOpen();
      },
      onSelectNote: _selectNote,
      onNewNote: _createNote,
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile
          ? Drawer(
              width: 310,
              backgroundColor: AppColors.sidebar,
              child: sidebar,
            )
          : null,
      endDrawer: Drawer(
        width: 290,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: RightActionPanel(
          authService: widget.authService,
          notes: _notes,
          onNewNote: _createNote,
          onSelectNote: _selectNote,
          onViewChanged: (view) => setState(() => _currentView = view),
          onOpenAuth: () => GuestSession().exitGuestSession(),
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                if (!isMobile) sidebar,
                Expanded(
                  child: () {
                    if (_currentView == 'dashboard') {
                      return RefinedDashboardView(
                        notes: _notes,
                        authService: widget.authService,
                        onSelectNote: _selectNote,
                        onNewNote: _createNote,
                        onOpenKnowledgeGraph: _openKnowledgeGraph,
                        onOpenIngest: _openIngestDialog,
                        onOpenFlashcards: _openFlashcards,
                        onOpenAi: _openAi,
                        onViewChanged: (view) => setState(() => _currentView = view),
                        onOpenMenu: isMobile ? () => _scaffoldKey.currentState?.openDrawer() : null,
                        onOpenRightPanel: () => _scaffoldKey.currentState?.openEndDrawer(),
                        onQuickCreate: (text) => _createNoteWithData(
                          title: 'Ghi nhanh ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                          content: text,
                        ),
                        onOpenAuth: () => GuestSession().exitGuestSession(),
                      );
                    } else if (_currentView == 'folders' || _currentView == 'gallery' || _currentView == 'favorites') {
                      return AppleNotesGalleryView(
                        notes: _notes,
                        onSelectNote: _selectNote,
                        onNewNote: _createNote,
                        onNewNoteWithFolder: ({required title, required content, folder}) => _createNoteWithData(
                          title: title.isEmpty ? 'Ghi chú mới' : title,
                          content: content,
                          folder: folder,
                        ),
                        onBackToDashboard: () => setState(() => _currentView = 'dashboard'),
                        onOpenMenu: isMobile ? () => _scaffoldKey.currentState?.openDrawer() : null,
                        onRenameFolder: _renameFolder,
                        onDeleteFolder: _deleteFolder,
                      );
                    } else if (_currentView == 'tasks') {
                      return TasksView(
                        notes: _notes,
                        onToggleTask: _toggleTaskContent,
                        onOpenMenu: isMobile ? () => _scaffoldKey.currentState?.openDrawer() : null,
                        onBackToDashboard: () => setState(() => _currentView = 'dashboard'),
                        onAddNewTask: _addNewTask,
                      );
                    } else if (_currentView == 'trash') {
                      return TrashView(
                        deletedNotes: _deletedNotes,
                        onRestoreNote: _restoreNote,
                        onPermanentDelete: _permanentDelete,
                        onEmptyTrash: _emptyTrash,
                        onOpenMenu: isMobile ? () => _scaffoldKey.currentState?.openDrawer() : null,
                        onBackToDashboard: () => setState(() => _currentView = 'dashboard'),
                      );
                    }
                          return NoteEditor(
                            note: _selectedNote,
                            titleController: _titleController,
                            contentController: _contentController,
                            onTitleChanged: (value) => _editSelected(title: value),
                            onContentChanged: (value) => _editSelected(content: value),
                            onDelete: _deleteSelected,
                            onOpenAi: _openAi,
                            onEditTags: _editTags,
                            onCreateNote: _createNote,
                            onOpenFlashcards: _openFlashcards,
                            onTogglePin: _togglePinSelected,
                            onFolderChanged: (f) => _changeFolderSelected(f),
                            savingStatus: _savingStatus,
                            onOpenMenu: isMobile ? () => _scaffoldKey.currentState?.openDrawer() : null,
                            onBack: () => setState(() => _currentView = 'dashboard'),
                            aiPanelOpen: showDockedAi,
                          );
                        }(),
                      ),
                      if (showDockedAi)
                        Container(
                          width: 360,
                          decoration: const BoxDecoration(
                            border: Border(left: BorderSide(color: AppColors.border)),
                          ),
                          child: AiAssistantPanel(
                            note: _selectedNote!,
                            aiApiService: _aiApiService,
                            onClose: () => setState(() => _showAiPanel = false),
                            onApplyTags: _applyTags,
                            onInsertText: (txt) {
                              final newContent = '${_contentController.text}\n\n$txt';
                              _editSelected(content: newContent);
                              _contentController.text = newContent;
                            },
                            onCreateNoteWithData: _createNoteWithData,
                            onOpenFlashcards: _openFlashcards,
                          ),
                        ),
                    ],
                  ),
    );
  }

  List<Note> _sampleNotes() {
    return const [];
  }
}
