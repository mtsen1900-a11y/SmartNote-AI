import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note_ai/models/note.dart';
import 'package:smart_note_ai/ui_refinement/guest/guest_session.dart';
import 'package:smart_note_ai/ui_refinement/guest/guest_banner.dart';
import 'package:smart_note_ai/ui_refinement/navigation/back_navigation_bar.dart';
import 'package:smart_note_ai/ui_refinement/components/help_center_dialog.dart';
import 'package:smart_note_ai/ui_refinement/widgets/refined_note_editor_header.dart';
import 'package:smart_note_ai/ui_refinement/widgets/refined_dashboard_view.dart';
import 'package:smart_note_ai/widgets/right_action_panel.dart';
import 'package:smart_note_ai/screens/knowledge_graph_screen.dart';
import 'package:smart_note_ai/ui_refinement/widgets/apple_notes_gallery_view.dart';
import 'package:smart_note_ai/widgets/notes_sidebar.dart';

void main() {
  group('1. GuestSession Permission & Quota Tests', () {
    final guest = GuestSession();

    setUp(() {
      guest.exitGuestSession();
    });

    test('Chế độ Khách khởi tạo mặc định là false', () {
      expect(guest.isGuestMode, isFalse);
    });

    test('Bắt đầu Chế độ Khách nạp ghi chú mẫu và bật cờ isGuestMode', () {
      guest.startGuestSession();
      expect(guest.isGuestMode, isTrue);
      expect(guest.guestNotes.length, greaterThanOrEqualTo(1));
      expect(guest.guestNotes.first.title, contains('Chế độ Khách'));
    });

    test('Kiểm tra bảng phân quyền Guest: Chức năng miễn phí vs Chức năng giới hạn', () {
      guest.startGuestSession();

      // Cho phép
      expect(guest.canAccess(FeatureAccess.viewDashboard), isTrue);
      expect(guest.canAccess(FeatureAccess.exploreUI), isTrue);
      expect(guest.canAccess(FeatureAccess.searchNotes), isTrue);
      expect(guest.canAccess(FeatureAccess.createNote), isTrue);
      expect(guest.canAccess(FeatureAccess.editNote), isTrue);

      // Bị giới hạn đối với Guest
      expect(guest.canAccess(FeatureAccess.aiSummarize), isFalse);
      expect(guest.canAccess(FeatureAccess.aiDeepAnalysis), isFalse);
      expect(guest.canAccess(FeatureAccess.ragPersonalKnowledge), isFalse);
      expect(guest.canAccess(FeatureAccess.cloudSync), isFalse);
      expect(guest.canAccess(FeatureAccess.multiDeviceSync), isFalse);
    });

    test('Giải thích lý do giới hạn trả về chuỗi tiếng Việt rõ ràng', () {
      guest.startGuestSession();
      final reason = guest.getRestrictionReason(FeatureAccess.aiSummarize);
      expect(reason, contains('Tóm tắt tài liệu bằng AI yêu cầu đăng nhập'));
    });
  });

  group('2. UI Refinement Widget Tests', () {
    testWidgets('GuestBanner hiển thị thông tin và nút Đăng nhập', (tester) async {
      bool authOpened = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuestBanner(onOpenAuth: () => authOpened = true),
          ),
        ),
      );

      expect(find.text('Bạn đang trải nghiệm Chế độ Khách'), findsOneWidget);
      expect(find.text('Đăng nhập'), findsOneWidget);

      await tester.tap(find.text('Đăng nhập'));
      expect(authOpened, isTrue);
    });

    testWidgets('BackNavigationBar hiển thị nút quay lại và tiêu đề', (tester) async {
      bool backed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BackNavigationBar(
              title: 'Chi tiết ghi chú',
              onBack: () => backed = true,
            ),
          ),
        ),
      );

      expect(find.text('Chi tiết ghi chú'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      expect(backed, isTrue);
    });

    testWidgets('RefinedNoteEditorHeader không bị tràn pixel trên màn hình điện thoại nhỏ (360px)', (tester) async {
      // Giả lập màn hình điện thoại siêu nhỏ 360 x 640
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sampleNote = Note(
        id: 'test_1',
        title: 'Ghi chú thử nghiệm',
        content: 'Nội dung kiểm tra responsive',
        folder: 'Công việc',
        tags: const ['work', 'sprint', 'urgent', 'q4'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefinedNoteEditorHeader(
              note: sampleNote,
              savingStatus: 'Đã lưu',
              isPreviewMode: false,
              aiPanelOpen: false,
              onTogglePreview: () {},
              onOpenAi: () {},
              onEditTags: () {},
              onDelete: () {},
              onFolderChanged: (_) {},
              onTogglePin: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Kiểm tra các phần tử hiển thị đầy đủ không bị RenderFlex overflow
      expect(find.text('Công việc'), findsOneWidget);
      expect(find.text('Đã lưu'), findsOneWidget);
      expect(find.text('#work'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
      expect(tester.takeException(), isNull); // KHÔNG có ngoại lệ overflow!
    });

    testWidgets('HelpCenterDialog hiển thị đủ 10 tính năng cốt lõi', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HelpCenterDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Khám phá SmartNoteAI'), findsOneWidget);
      expect(find.text('1. Ghi chú và Chỉnh sửa'), findsOneWidget);
      expect(find.text('2. Quản lý Thư mục (Folders)'), findsOneWidget);
    });

    testWidgets('RefinedDashboardView không bị tràn pixel (zero overflow) trên màn hình 360px', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefinedDashboardView(
              notes: const [],
              onSelectNote: (_) {},
              onNewNote: () {},
              onOpenKnowledgeGraph: () {},
              onOpenIngest: () {},
              onOpenRightPanel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Trợ lý AI & Kho Tri thức'), findsOneWidget);
      expect(find.text('Bản đồ Tri thức'), findsOneWidget);
      expect(find.text('Quiz'), findsOneWidget);
      expect(find.text('Tác vụ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RightActionPanel hiển thị đầy đủ Đăng nhập, Tạo ghi chú mới và Chỉnh sửa nội dung', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RightActionPanel(
              notes: const [],
              onNewNote: () {},
              onSelectNote: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Thanh tác vụ'), findsOneWidget);
      expect(find.text('Tài khoản người dùng'), findsOneWidget);
      expect(find.text('Tạo ghi chú mới'), findsOneWidget);
      expect(find.text('Chỉnh sửa nội dung'), findsOneWidget);
      expect(find.text('Xin chào khách'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('KnowledgeGraphScreen không bị lỗi gạch vàng tràn pixel trên màn hình điện thoại 360px', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final sampleNotes = [
        Note(
          id: 'test_1',
          title: 'Ghi chú kiểm thử',
          content: 'Nội dung kiểm thử phân nhánh',
          folder: 'Cá nhân',
          tags: const ['test'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: KnowledgeGraphScreen(
            notes: sampleNotes,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sơ Đồ Cây Cấu Trúc & Bản Đồ Tri Thức'), findsOneWidget);
      expect(find.text('HẠ TẦNG DỊCH VỤ VẬN HÀNH (INFRASTRUCTURE)'), findsOneWidget);
      expect(find.text('CÂY PHÂN NHÁNH THƯ MỤC LƯU TRỮ (DIRECTORY HIERARCHY)'), findsOneWidget);
      expect(tester.takeException(), isNull); // ZERO OVERFLOW!
    });

    testWidgets('AppleNotesGalleryView không bị tràn pixel khi chưa có thư mục nào trên màn hình 360px (Ảnh 4)', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: AppleNotesGalleryView(
            notes: const [],
            onSelectNote: (_) {},
            onNewNote: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Thư mục tổng'), findsOneWidget);
      expect(find.text('Tất cả ghi chú'), findsOneWidget);
      expect(find.text('Chưa có thư mục nào. Nhấn [+] ở trên để tạo mới.'), findsOneWidget);
      expect(tester.takeException(), isNull); // ZERO OVERFLOW!
    });

    testWidgets('NotesSidebar không còn mục [Bảng ghi chú] theo yêu cầu người dùng (Ảnh 1)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotesSidebar(
              notes: const [],
              selectedNoteId: null,
              selectedTag: null,
              searchQuery: '',
              searchController: TextEditingController(),
              currentView: 'dashboard',
              onViewChanged: (_) {},
              onOpenKnowledgeGraph: () {},
              onOpenIngestDialog: () {},
              onSearchChanged: (_) {},
              onSelectTag: (_) {},
              onSelectNote: (_) {},
              onNewNote: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('SmartNoteAI'), findsOneWidget);
      expect(find.text('Bảng điều khiển'), findsOneWidget);
      expect(find.text('Thư mục tổng'), findsOneWidget);
      expect(find.text('Thùng rác'), findsOneWidget);
      expect(find.text('Hướng dẫn sử dụng'), findsOneWidget);
      expect(find.text('Bảng ghi chú'), findsNothing); // ĐÃ XÓA THEO YÊU CẦU!
      expect(tester.takeException(), isNull);
    });
  });
}
