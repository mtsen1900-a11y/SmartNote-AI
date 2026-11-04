import 'package:flutter/foundation.dart';
import '../../models/note.dart';

/// Enum phân loại tính năng để kiểm tra quyền truy cập của Guest
enum FeatureAccess {
  viewDashboard,
  exploreUI,
  createNote,
  editNote,
  searchNotes,
  createFolder,
  createTag,
  basicAiChat,
  aiSummarize,
  aiDeepAnalysis,
  ragPersonalKnowledge,
  cloudSync,
  persistentAiHistory,
  multiDeviceSync,
}

/// Quản lý phiên làm việc ở chế độ Khách (Guest Session)
/// - Không sinh JWT giả
/// - Không gửi dữ liệu lên máy chủ
/// - Không truy cập dữ liệu của tài khoản khác
/// - Lưu trữ tạm cục bộ trong bộ nhớ máy khách
class GuestSession extends ChangeNotifier {
  static final GuestSession _instance = GuestSession._internal();
  factory GuestSession() => _instance;
  GuestSession._internal();

  bool _isGuestMode = false;
  final List<Note> _guestNotes = [];
  static const int maxGuestNotes = 5;

  bool get isGuestMode => _isGuestMode;
  List<Note> get guestNotes => List.unmodifiable(_guestNotes);
  int get remainingNoteQuota => maxGuestNotes - _guestNotes.length;

  /// Bắt đầu phiên làm việc Khách
  void startGuestSession() {
    _isGuestMode = true;
    if (_guestNotes.isEmpty) {
      _guestNotes.addAll([
        Note(
          id: 'guest_welcome',
          title: 'Chào mừng bạn đến với SmartNoteAI (Chế độ Khách)',
          content: '# Trải nghiệm SmartNoteAI\n\n'
              'Bạn đang sử dụng ứng dụng với tư cách **Khách**.\n\n'
              '- [x] Khám phá giao diện Dashboard tinh gọn\n'
              '- [ ] Tạo ghi chú thử nghiệm tại máy của bạn\n'
              '- [ ] Trải nghiệm trình soạn thảo Markdown\n\n'
              '> **Lưu ý:** Đăng nhập tài khoản để mở khóa đầy đủ Trợ lý AI, RAG và Đồng bộ đám mây đa thiết bị.',
          folder: 'Khám phá',
          tags: const ['welcome', 'guest'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);
    }
    notifyListeners();
  }

  /// Thoát chế độ Khách (để đăng nhập hoặc đăng ký)
  void exitGuestSession() {
    _isGuestMode = false;
    notifyListeners();
  }

  /// Kiểm tra quyền truy cập cho một tính năng cụ thể
  bool canAccess(FeatureAccess feature) {
    if (!_isGuestMode) return true; // Tài khoản đăng nhập có toàn quyền

    switch (feature) {
      case FeatureAccess.viewDashboard:
      case FeatureAccess.exploreUI:
      case FeatureAccess.searchNotes:
        return true;
      case FeatureAccess.createNote:
        return _guestNotes.length < maxGuestNotes;
      case FeatureAccess.editNote:
      case FeatureAccess.createFolder:
      case FeatureAccess.createTag:
      case FeatureAccess.basicAiChat:
        return true;
      case FeatureAccess.aiSummarize:
      case FeatureAccess.aiDeepAnalysis:
      case FeatureAccess.ragPersonalKnowledge:
      case FeatureAccess.cloudSync:
      case FeatureAccess.persistentAiHistory:
      case FeatureAccess.multiDeviceSync:
        return false;
    }
  }

  /// Thêm ghi chú mới trong chế độ Khách
  bool addGuestNote(Note note) {
    if (_guestNotes.length >= maxGuestNotes) return false;
    _guestNotes.insert(0, note);
    notifyListeners();
    return true;
  }

  /// Cập nhật ghi chú của Khách
  void updateGuestNote(Note updatedNote) {
    final idx = _guestNotes.indexWhere((n) => n.id == updatedNote.id);
    if (idx != -1) {
      _guestNotes[idx] = updatedNote;
      notifyListeners();
    }
  }

  /// Xóa ghi chú của Khách
  void deleteGuestNote(String noteId) {
    _guestNotes.removeWhere((n) => n.id == noteId);
    notifyListeners();
  }

  /// Lấy thông báo giải thích ngắn gọn khi bị giới hạn
  String getRestrictionReason(FeatureAccess feature) {
    switch (feature) {
      case FeatureAccess.aiSummarize:
        return 'Tính năng Tóm tắt tài liệu bằng AI yêu cầu đăng nhập tài khoản.';
      case FeatureAccess.aiDeepAnalysis:
        return 'Phân tích tài liệu chuyên sâu chỉ dành cho tài khoản đã xác thực.';
      case FeatureAccess.ragPersonalKnowledge:
        return 'Hỏi đáp RAG trên kho tài liệu cá nhân chỉ kích hoạt khi đã đăng nhập.';
      case FeatureAccess.cloudSync:
      case FeatureAccess.multiDeviceSync:
        return 'Đồng bộ hóa đám mây đa thiết bị yêu cầu tài khoản cá nhân an toàn.';
      case FeatureAccess.createNote:
        return 'Chế độ Khách được tạo tối đa $maxGuestNotes ghi chú thử nghiệm. Hãy đăng nhập để lưu trữ không giới hạn.';
      default:
        return 'Tính năng này yêu cầu tài khoản để sử dụng đầy đủ.';
    }
  }
}
