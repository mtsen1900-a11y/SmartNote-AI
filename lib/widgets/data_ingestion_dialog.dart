import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';

class DataIngestionDialog extends StatefulWidget {
  final AuthService? authService;
  final VoidCallback onIngestSuccess;

  const DataIngestionDialog({
    super.key,
    this.authService,
    required this.onIngestSuccess,
  });

  @override
  State<DataIngestionDialog> createState() => _DataIngestionDialogState();
}

class _DataIngestionDialogState extends State<DataIngestionDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _textTitleController = TextEditingController();
  final _textContentController = TextEditingController();
  final _urlController = TextEditingController();
  final _folderController = TextEditingController(text: 'Tài liệu nhập');
  final _tagsController = TextEditingController(text: 'imported, ai');

  bool _isSubmitting = false;
  String? _statusMessage;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textTitleController.dispose();
    _textContentController.dispose();
    _urlController.dispose();
    _folderController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _submitText() async {
    final title = _textTitleController.text.trim();
    final content = _textContentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      setState(() {
        _isError = true;
        _statusMessage = 'Vui lòng nhập đầy đủ tiêu đề và nội dung.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusMessage = 'Đang xử lý, tách đoạn và lập chỉ mục Vector...';
      _isError = false;
    });

    final token = widget.authService?.accessToken;
    final tags = _tagsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    try {
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/ingest/text'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
          'content': content,
          'folder': _folderController.text.trim(),
          'tags': tags,
          'source_type': 'direct',
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _isSubmitting = false;
          _statusMessage = '✅ ${data['message']}';
        });
        widget.onIngestSuccess();
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        final err = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _isSubmitting = false;
          _isError = true;
          _statusMessage = 'Lỗi (${res.statusCode}): ${err['detail'] ?? 'Không thể nhập dữ liệu'}';
        });
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _isError = true;
        _statusMessage = 'Không thể kết nối Backend Ingestion: $e';
      });
    }
  }

  Future<void> _submitUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty || !url.startsWith('http')) {
      setState(() {
        _isError = true;
        _statusMessage = 'Vui lòng nhập đường dẫn hợp lệ (bắt đầu bằng http:// hoặc https://).';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusMessage = 'Đang crawl dữ liệu web, lọc mã độc hại và tạo Vector...';
      _isError = false;
    });

    final token = widget.authService?.accessToken;
    final tags = _tagsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    try {
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/ingest/url'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'url': url,
          'folder': _folderController.text.trim(),
          'tags': tags,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _isSubmitting = false;
          _statusMessage = '✅ ${data['message']}';
        });
        widget.onIngestSuccess();
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        final err = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _isSubmitting = false;
          _isError = true;
          _statusMessage = 'Lỗi (${res.statusCode}): ${err['detail'] ?? 'Crawl URL thất bại'}';
        });
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _isError = true;
        _statusMessage = 'Lỗi kết nối Backend: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Thu Thập Dữ Liệu Đa Nguồn (Ingestion)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(icon: Icon(Icons.article_outlined, size: 18), text: 'Văn bản / MD'),
                Tab(icon: Icon(Icons.link_outlined, size: 18), text: 'Web URL'),
              ],
            ),
            const SizedBox(height: 14),

            SizedBox(
              height: 220,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Text / Markdown
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          controller: _textTitleController,
                          decoration: const InputDecoration(
                            labelText: 'Tiêu đề tài liệu',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _textContentController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Dán nội dung văn bản thô hoặc Markdown...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(10),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab 2: Web URL
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nhập đường dẫn trang web hoặc tài liệu online cần đưa vào kho tri thức:',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'https://example.com/bai-viet-hay',
                          prefixIcon: Icon(Icons.language, size: 18),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '🛡️ Hệ thống tự động kiểm tra an toàn (SSRF Safe) và bóc tách nội dung chính.',
                        style: TextStyle(fontSize: 11, color: AppColors.accentEmerald),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _folderController,
                    decoration: const InputDecoration(
                      labelText: 'Thư mục đích',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Thẻ Tags (cách nhau dấu phẩy)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ),
              ],
            ),

            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _statusMessage!,
                style: TextStyle(
                  fontSize: 12,
                  color: _isError ? AppColors.danger : AppColors.accentEmerald,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          if (_tabController.index == 0) {
                            _submitText();
                          } else {
                            _submitUrl();
                          }
                        },
                  icon: _isSubmitting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.bolt, size: 16),
                  label: Text(_isSubmitting ? 'Đang xử lý...' : 'Bắt đầu nạp dữ liệu'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
