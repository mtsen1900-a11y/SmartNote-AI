import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_note_ai/screens/auth_screen.dart';
import 'package:smart_note_ai/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService Comprehensive Unit Tests', () {
    test('1. Đăng nhập thành công trả về null error và lưu UserProfile', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return http.Response(
            jsonEncode({
              'access_token': 'mock_access_token_123',
              'refresh_token': 'mock_refresh_token_456',
              'token_type': 'bearer',
              'expires_in': 1800,
              'user': {
                'id': 10,
                'email': 'user@smartnote.ai',
                'full_name': 'Nguyễn Văn Minh',
                'is_active': true,
                'username': 'minh',
                'workspace_slug': 'u/minh',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final auth = AuthService(client: mockClient);
      final error = await auth.login('user@smartnote.ai', 'password123');

      expect(error, isNull);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.accessToken, 'mock_access_token_123');
      expect(auth.refreshToken, 'mock_refresh_token_456');
      expect(auth.currentUser?.email, 'user@smartnote.ai');
      expect(auth.currentUser?.workspaceSlug, 'u/minh');
    });

    test('2. Đăng nhập sai mật khẩu (401) trả về thông báo tiếng Việt thân thiện', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Email/Tên người dùng hoặc mật khẩu không chính xác'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final auth = AuthService(client: mockClient);
      final error = await auth.login('user@smartnote.ai', 'wrongpassword');

      expect(error, 'Email hoặc mật khẩu không chính xác.');
      expect(auth.isAuthenticated, isFalse);
    });

    test('3. Đăng nhập khi mạng lỗi (ClientException) trả về thông báo lỗi mạng', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Failed to fetch', request.url);
      });

      final auth = AuthService(client: mockClient);
      final error = await auth.login('user@smartnote.ai', 'password123');

      expect(error, 'Không thể kết nối máy chủ. Vui lòng kiểm tra kết nối mạng và thử lại.');
      expect(auth.isAuthenticated, isFalse);
    });

    test('4. Đăng ký trùng email (409) trả về thông báo tiếng Việt', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Email này đã được sử dụng'}),
          409,
          headers: {'content-type': 'application/json'},
        );
      });

      final auth = AuthService(client: mockClient);
      final error = await auth.register('existing@smartnote.ai', 'password123', 'Tên');

      expect(error, 'Email này đã được sử dụng. Vui lòng đăng nhập hoặc chọn email khác.');
      expect(auth.isAuthenticated, isFalse);
    });

    test('5. Đăng xuất xóa toàn bộ state và tokens', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'OK'}), 200);
      });

      final auth = AuthService(client: mockClient);
      await auth.logout();

      expect(auth.isAuthenticated, isFalse);
      expect(auth.accessToken, isNull);
      expect(auth.currentUser, isNull);
    });
  });

  group('AuthScreen UI & Form Validation Widget Tests', () {
    testWidgets('1. Hiển thị form đăng nhập và kiểm tra validation email & mật khẩu', (tester) async {
      final auth = AuthService();
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(
            authService: auth,
            onAuthenticated: () {},
          ),
        ),
      );

      // Verify UI elements
      expect(find.text('SmartNoteAI'), findsOneWidget);
      expect(find.text('Đăng nhập vào Workspace'), findsOneWidget);
      expect(find.text('Địa chỉ Email'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(find.text('Điền tài khoản mẫu thử nghiệm'), findsOneWidget);

      // Bấm đăng nhập khi form rỗng
      await tester.tap(find.text('Đăng nhập vào Workspace'));
      await tester.pumpAndSettle();

      // Phải báo lỗi validation
      expect(find.text('Vui lòng nhập địa chỉ email'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    });

    testWidgets('2. Chuyển sang chế độ Đăng ký hiển thị Họ tên và Xác nhận mật khẩu', (tester) async {
      final auth = AuthService();
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(
            authService: auth,
            onAuthenticated: () {},
          ),
        ),
      );

      // Nhấn Đăng ký ngay
      await tester.ensureVisible(find.text('Đăng ký ngay'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đăng ký ngay'));
      await tester.pumpAndSettle();

      expect(find.text('Họ và tên'), findsOneWidget);
      expect(find.text('Xác nhận mật khẩu'), findsOneWidget);
      expect(find.text('Đăng ký tài khoản'), findsOneWidget);
    });

    testWidgets('3. Nút điền tài khoản mẫu điền dữ liệu an toàn vào trường', (tester) async {
      final auth = AuthService();
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(
            authService: auth,
            onAuthenticated: () {},
          ),
        ),
      );

      await tester.tap(find.text('Điền tài khoản mẫu thử nghiệm'));
      await tester.pumpAndSettle();

      expect(find.text('demo@smartnote.ai'), findsOneWidget);
      expect(find.text('Đã điền thông tin mẫu. Nhấn Đăng nhập để tiếp tục.'), findsOneWidget);
    });
  });
}
