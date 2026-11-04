import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_config.dart';

class UserProfile {
  final int id;
  final String email;
  final String fullName;
  final String username;
  final String workspaceSlug;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.username,
    required this.workspaceSlug,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final email = json['email'] as String? ?? '';
    final username = json['username'] as String? ?? (email.isNotEmpty ? email.split('@')[0] : 'user');
    return UserProfile(
      id: json['id'] is int ? json['id'] as int : 0,
      email: email,
      fullName: json['full_name'] as String? ?? '',
      username: username,
      workspaceSlug: json['workspace_slug'] as String? ?? 'u/$username',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'username': username,
    'workspace_slug': workspaceSlug,
  };
}

class AuthService extends ChangeNotifier {
  static const String _tokenKey = 'smartnote_access_token';
  static const String _refreshTokenKey = 'smartnote_refresh_token';
  static const String _userKey = 'smartnote_user_profile';
  static String get defaultBaseUrl => AppConfig.baseUrl;

  final String baseUrl;
  final http.Client _client;

  String? _accessToken;
  String? _refreshToken;
  UserProfile? _currentUser;
  bool _isLoading = true;

  AuthService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? AppConfig.baseUrl,
        _client = client ?? http.Client();

  bool get isAuthenticated => _accessToken != null && _currentUser != null;
  bool get isLoading => _isLoading;
  UserProfile? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  /// Khởi tạo và kiểm tra phiên làm việc lưu trong SharedPreferences
  Future<void> initSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_tokenKey);
      _refreshToken = prefs.getString(_refreshTokenKey);
      final userRaw = prefs.getString(_userKey);

      if (_accessToken != null && userRaw != null) {
        _currentUser = UserProfile.fromJson(jsonDecode(userRaw) as Map<String, dynamic>);
        // Kiểm tra tính hợp lệ của token nền với /api/auth/me
        _verifyCurrentSession();
      }
    } catch (e) {
      debugPrint('Lỗi khởi tạo session: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kiểm tra ngầm xem phiên làm việc còn hiệu lực hay không
  Future<void> _verifyCurrentSession() async {
    if (_accessToken == null) return;
    try {
      final res = await _client.get(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _currentUser = UserProfile.fromJson(data);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
        notifyListeners();
      } else if (res.statusCode == 401 && _refreshToken != null) {
        // Access token hết hạn -> thử refresh
        await refreshSession();
      }
    } catch (_) {
      // Khi offline, giữ nguyên cache local
    }
  }

  /// Đăng nhập bằng Email và Mật khẩu
  Future<String?> login(String email, String password) async {
    try {
      final res = await _client.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'password': password}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        await _saveAuthData(data);
        notifyListeners();
        return null; // Thành công
      } else {
        return _parseHttpError(res);
      }
    } catch (e) {
      return 'Không thể kết nối máy chủ. Vui lòng kiểm tra kết nối mạng và thử lại.';
    }
  }

  /// Đăng ký tài khoản mới
  Future<String?> register(String email, String password, String fullName) async {
    try {
      final res = await _client.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'full_name': fullName.trim(),
        }),
      );

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        await _saveAuthData(data);
        notifyListeners();
        return null; // Thành công
      } else {
        return _parseHttpError(res);
      }
    } catch (e) {
      return 'Không thể kết nối máy chủ. Vui lòng kiểm tra kết nối mạng và thử lại.';
    }
  }

  /// Tải thông tin người dùng từ server
  Future<UserProfile?> fetchCurrentUser() async {
    if (_accessToken == null) return null;
    try {
      final res = await _client.get(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _currentUser = UserProfile.fromJson(data);
        notifyListeners();
        return _currentUser;
      }
    } catch (_) {}
    return null;
  }

  /// Cấp mới Access Token bằng Refresh Token
  Future<bool> refreshSession() async {
    if (_refreshToken == null) return false;
    try {
      final res = await _client.post(
        Uri.parse('$baseUrl/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': _refreshToken}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        await _saveAuthData(data);
        notifyListeners();
        return true;
      } else {
        // Refresh token không hợp lệ hoặc hết hạn -> buộc đăng xuất
        await logout();
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  /// Đăng xuất và xóa an toàn token
  Future<void> logout() async {
    if (_refreshToken != null) {
      try {
        await _client.post(
          Uri.parse('$baseUrl/api/auth/logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': _refreshToken}),
        );
      } catch (_) {}
    }

    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);

    notifyListeners();
  }

  String _parseHttpError(http.Response res) {
    if (res.statusCode == 401) {
      return 'Email hoặc mật khẩu không chính xác.';
    } else if (res.statusCode == 404) {
      return 'Tài khoản không tồn tại. Vui lòng kiểm tra lại hoặc đăng ký mới.';
    } else if (res.statusCode == 409) {
      return 'Email này đã được sử dụng. Vui lòng đăng nhập hoặc chọn email khác.';
    } else if (res.statusCode == 422) {
      return 'Dữ liệu nhập không hợp lệ. Vui lòng kiểm tra lại định dạng email và độ dài mật khẩu.';
    } else if (res.statusCode == 429) {
      return 'Bạn đã thử quá nhiều lần. Vui lòng chờ trước khi thử lại.';
    } else if (res.statusCode >= 500) {
      return 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.';
    }
    try {
      final err = jsonDecode(res.body);
      if (err is Map && err['detail'] != null) {
        return err['detail'].toString();
      }
    } catch (_) {}
    return 'Thao tác không thành công (Mã lỗi: ${res.statusCode}).';
  }

  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    _accessToken = data['access_token'] as String?;
    _refreshToken = data['refresh_token'] as String?;

    if (data['user'] != null) {
      _currentUser = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
    }

    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) await prefs.setString(_tokenKey, _accessToken!);
    if (_refreshToken != null) await prefs.setString(_refreshTokenKey, _refreshToken!);
    if (_currentUser != null) await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
  }
}
