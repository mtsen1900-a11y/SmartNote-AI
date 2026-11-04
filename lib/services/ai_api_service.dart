import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';

class AiAskResult {
  final String answer;
  final List<String> sourceTitles;
  final String intent;
  final Map<String, dynamic>? toolAction;
  final Map<String, dynamic>? resultData;

  AiAskResult({
    required this.answer,
    this.sourceTitles = const [],
    this.intent = 'knowledge_rag',
    this.toolAction,
    this.resultData,
  });
}

class AiApiService {
  final String baseUrl;
  final String? Function() getAuthToken;
  final http.Client _client;

  AiApiService({
    String? baseUrl,
    required this.getAuthToken,
    http.Client? client,
  })  : baseUrl = baseUrl ?? AppConfig.baseUrl,
        _client = client ?? http.Client();

  /// Alias cho askAi
  Future<AiAskResult> askQuestion(String question, {dynamic noteId}) =>
      askAi(question, noteId: noteId);

  /// Chỉ mục ghi chú vào cơ sở dữ liệu Vector ChromaDB cho RAG
  Future<bool> indexNote({
    required dynamic noteId,
    required String title,
    required String content,
  }) async {
    final token = getAuthToken();
    try {
      final res = await _client.post(
        Uri.parse('$baseUrl/api/ai/index'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'note_id': noteId.toString(),
          'title': title,
          'content': content,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Lỗi chỉ mục vector ghi chú: $e');
      return false;
    }
  }

  /// Hỏi đáp RAG thông minh & NLU tự nhiên dựa trên kho ghi chú cá nhân
  Future<AiAskResult> askAi(String question, {dynamic noteId}) async {
    final token = getAuthToken();
    try {
      // 1. Ưu tiên gửi sang NLU Endpoint để nhận diện Intent, RAG & Tool Calling
      final res = await _client.post(
        Uri.parse('$baseUrl/api/ai/nlu'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'query': question,
          'context_note_id': noteId,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final answer = data['summary_message'] as String? ?? '';
        final sourcesRaw = (data['sources'] as List<dynamic>? ?? []);
        final sources = sourcesRaw
            .map((s) => s['title']?.toString() ?? 'Ghi chú tham chiếu')
            .toList();
        return AiAskResult(
          answer: answer,
          sourceTitles: sources,
          intent: data['intent'] as String? ?? 'knowledge_rag',
          toolAction: data['tool_action'] as Map<String, dynamic>?,
          resultData: data['result_data'] as Map<String, dynamic>?,
        );
      } else {
        // 2. Fallback sang endpoint /api/ai/ask truyền thống nếu nlu trả về lỗi
        final askRes = await _client.post(
          Uri.parse('$baseUrl/api/ai/ask'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'question': question,
            'note_id': noteId,
          }),
        );
        if (askRes.statusCode == 200) {
          final data = jsonDecode(utf8.decode(askRes.bodyBytes)) as Map<String, dynamic>;
          final answer = data['answer'] as String? ?? '';
          final sourcesRaw = (data['sources'] as List<dynamic>? ?? []);
          final sources = sourcesRaw
              .map((s) => s['title']?.toString() ?? 'Ghi chú tham chiếu')
              .toList();
          return AiAskResult(answer: answer, sourceTitles: sources);
        } else {
          // Báo lỗi cụ thể từ response của backend
          String errorDetail = 'Lỗi HTTP ${askRes.statusCode}';
          try {
            final errBody = jsonDecode(utf8.decode(askRes.bodyBytes));
            if (errBody is Map && errBody['detail'] != null) {
              errorDetail = errBody['detail'].toString();
            }
          } catch (_) {}

          if (askRes.statusCode == 503) {
            return AiAskResult(
              answer: 'Dịch vụ AI Backend chưa sẵn sàng: $errorDetail\n(Vui lòng kiểm tra Ollama tại cổng 11434 và ChromaDB tại cổng 8002).',
              sourceTitles: const ['Dịch vụ AI tạm gián đoạn'],
            );
          } else if (askRes.statusCode == 401) {
            return AiAskResult(
              answer: 'Phiên làm việc đã hết hạn hoặc chưa được cấp quyền. Vui lòng đăng nhập để tiếp tục truy vấn AI.',
              sourceTitles: const ['Yêu cầu đăng nhập'],
            );
          } else {
            return AiAskResult(
              answer: 'Không thể xử lý yêu cầu AI: $errorDetail',
              sourceTitles: const ['Lỗi xử lý'],
            );
          }
        }
      }
    } catch (e) {
      debugPrint('AI live service connection error: $e');
      return AiAskResult(
        answer:
            'Không thể kết nối đến máy chủ Backend FastAPI tại $baseUrl (Lỗi kết nối: $e).\n'
            'Vui lòng khởi động Backend FastAPI (cổng 8000), Ollama (cổng 11434) và ChromaDB (cổng 8002).',
        sourceTitles: const ['Mất kết nối Backend'],
      );
    }
  }

  /// Tóm tắt ghi chú
  Future<String> summarize(String content, {int maxSentences = 3}) async {
    final token = getAuthToken();
    try {
      final res = await _client.post(
        Uri.parse('$baseUrl/api/ai/summarize'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'content': content,
          'max_sentences': maxSentences,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        return data['summary'] as String? ?? '';
      }
    } catch (e) {
      debugPrint('Summarize fallback: $e');
    }

    final sentences = content
        .replaceAll('\n', ' ')
        .split(RegExp(r'[.!?]+\s*'))
        .where((s) => s.trim().isNotEmpty)
        .take(maxSentences)
        .join('. ');
    return sentences.isNotEmpty ? '$sentences.' : content;
  }

  /// Trợ lý viết (Writing Assistant: trau chuốt, sửa chính tả, checklist, action plan)
  Future<String> writingAssist(String content, String action) async {
    final token = getAuthToken();
    try {
      final res = await _client.post(
        Uri.parse('$baseUrl/api/ai/writing-assist'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'content': content,
          'action': action,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        return data['result'] as String? ?? '';
      }
    } catch (e) {
      debugPrint('Writing assist fallback: $e');
    }

    // Fallback nếu ngoại tuyến
    if (action == 'checklist') {
      final lines = content.split('\n').where((l) => l.trim().isNotEmpty);
      return lines.map((l) => '- [ ] $l').join('\n');
    }
    return content;
  }
}
