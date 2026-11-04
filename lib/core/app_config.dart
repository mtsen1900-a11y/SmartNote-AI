/// Nguồn cấu hình tập trung cho toàn bộ ứng dụng SmartNoteAI
class AppConfig {
  static const String _defaultDevBaseUrl = 'http://127.0.0.1:8000';

  /// Lấy Base URL từ biến môi trường (khi build với --dart-define=API_BASE_URL=...)
  /// hoặc fallback an toàn về `http://127.0.0.1:8000` trong môi trường local development.
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    return _defaultDevBaseUrl;
  }
}
