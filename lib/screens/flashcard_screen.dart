import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/note.dart';
import '../services/ai_api_service.dart';

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

class FlashcardItem {
  final String id;
  final String question;
  final String answer;
  final String? hint;

  FlashcardItem({
    required this.id,
    required this.question,
    required this.answer,
    this.hint,
  });
}

class FlashcardScreen extends StatefulWidget {
  final Note note;
  final AiApiService? aiService;

  const FlashcardScreen({
    super.key,
    required this.note,
    this.aiService,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<FlashcardItem> _cards = [];
  final List<QuizQuestion> _quizQuestions = [];
  final Map<int, int> _userAnswers = {};
  bool _isSubmitted = false;
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _showAnswer = false;
  int _rememberedCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _showAnswer = false;
      _isSubmitted = false;
      _userAnswers.clear();
    });

    try {
      if (widget.aiService != null) {
        await widget.aiService!.askQuestion(
          'Tạo quiz câu hỏi trắc nghiệm và flashcard từ ghi chú này',
          noteId: int.tryParse(widget.note.id),
        );
      }
    } catch (_) {}

    final sentences = widget.note.content
        .split(RegExp(r'\n+|(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.length > 15)
        .toList();

    _cards.clear();
    _quizQuestions.clear();

    if (sentences.isNotEmpty) {
      for (int i = 0; i < sentences.length && i < 5; i++) {
        final s = sentences[i];
        final parts = s.split(':');
        final questionText = parts.length >= 2
            ? 'Khái niệm hoặc câu hỏi: "${parts[0].trim()}" là gì?'
            : 'Ý chính của điểm số ${i + 1} trong "${widget.note.title}" là gì?';
        final answerText = parts.length >= 2 ? parts.sublist(1).join(':').trim() : s;

        _cards.add(FlashcardItem(
          id: 'fc-$i',
          question: questionText,
          answer: answerText,
          hint: 'Dựa trên nội dung ghi chú',
        ));

        _quizQuestions.add(QuizQuestion(
          id: 'quiz-$i',
          question: 'Câu ${i + 1}: $questionText',
          options: [
            answerText,
            'Nội dung đối lập hoặc không liên quan đến bài viết',
            'Một khái niệm độc lập chưa được đề cập',
            'Không có thông tin xác thực',
          ]..shuffle(),
          correctIndex: 0,
          explanation: 'Dựa trên văn bản ghi chú: "$answerText"',
        ));
      }
    }

    if (_cards.isEmpty) {
      _cards.add(FlashcardItem(
        id: 'fc-default',
        question: 'Ghi chú "${widget.note.title}" tập trung vào chủ đề gì?',
        answer: widget.note.content.isNotEmpty ? widget.note.content : 'Chưa có nội dung chi tiết.',
        hint: 'Xem toàn bộ ghi chú',
      ));

      _quizQuestions.add(QuizQuestion(
        id: 'quiz-default',
        question: 'Nội dung cốt lõi của ghi chú "${widget.note.title}" là gì?',
        options: [
          widget.note.content.isNotEmpty ? widget.note.content : 'Quản lý ghi chú thông minh',
          'Một chủ đề hoàn toàn khác',
          'Không có nội dung',
        ],
        correctIndex: 0,
        explanation: 'Trích xuất từ nội dung ghi chú hiện tại.',
      ));
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _submitQuiz() {
    setState(() => _isSubmitted = true);

    int score = 0;
    for (int i = 0; i < _quizQuestions.length; i++) {
      if (_userAnswers[i] == _quizQuestions[i].correctIndex) {
        score++;
      }
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: Color(0xFFD97706), size: 24),
            SizedBox(width: 8),
            Text('Kết quả Nộp bài Quiz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn đã hoàn thành bài kiểm tra với số điểm: $score / ${_quizQuestions.length} câu đúng.', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              score == _quizQuestions.length
                  ? '🎉 Xuất sắc! Bạn đã nắm vững 100% kiến thức của ghi chú này.'
                  : '💡 Bạn có thể xem lại lời giải chi tiết bên dưới để ôn tập tốt hơn.',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Xem lời giải'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quiz & Ôn tập: ${widget.note.title}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.quiz_rounded, size: 18), text: 'Làm bài Quiz & Nộp bài'),
            Tab(icon: Icon(Icons.flip_to_back_rounded, size: 18), text: 'Thẻ lật Flashcard'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tạo lại bộ câu hỏi',
            onPressed: _loadContent,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildQuizView(),
                _buildFlashcardView(),
              ],
            ),
    );
  }

  /// Giao diện Làm bài Quiz & Nộp bài
  Widget _buildQuizView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.help_center_outlined, color: Color(0xFFD97706), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bài Kiểm tra Trắc nghiệm Tự động (Quiz)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Bộ ${_quizQuestions.length} câu hỏi được sinh từ nội dung ghi chú. Chọn đáp án và nhấn Nộp bài.', style: const TextStyle(fontSize: 12, color: Color(0xFF78350F))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              for (int qIdx = 0; qIdx < _quizQuestions.length; qIdx++) ...[
                _buildQuizQuestionCard(qIdx, _quizQuestions[qIdx]),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isSubmitted ? null : _submitQuiz,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(_isSubmitted ? 'Đã nộp bài thành công' : 'Nộp bài kiểm tra', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizQuestionCard(int index, QuizQuestion q) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q.question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
          const SizedBox(height: 12),
          for (int optIdx = 0; optIdx < q.options.length; optIdx++) ...[
            InkWell(
              onTap: _isSubmitted
                  ? null
                  : () {
                      setState(() {
                        _userAnswers[index] = optIdx;
                      });
                    },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _getOptionBgColor(index, optIdx, q),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getOptionBorderColor(index, optIdx, q)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: _userAnswers[index] == optIdx ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                      child: Text(
                        String.fromCharCode(65 + optIdx),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _userAnswers[index] == optIdx ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        q.options[optIdx],
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_isSubmitted) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '💡 Giải thích: ${q.explanation}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getOptionBgColor(int qIdx, int optIdx, QuizQuestion q) {
    if (!_isSubmitted) {
      return _userAnswers[qIdx] == optIdx ? const Color(0xFFEEF2FF) : Colors.transparent;
    }
    if (optIdx == q.correctIndex) {
      return const Color(0xFFD1FAE5); // Xanh lá nếu đúng
    }
    if (_userAnswers[qIdx] == optIdx) {
      return const Color(0xFFFEE2E2); // Đỏ nếu người dùng chọn sai
    }
    return Colors.transparent;
  }

  Color _getOptionBorderColor(int qIdx, int optIdx, QuizQuestion q) {
    if (!_isSubmitted) {
      return _userAnswers[qIdx] == optIdx ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1);
    }
    if (optIdx == q.correctIndex) {
      return const Color(0xFF10B981);
    }
    if (_userAnswers[qIdx] == optIdx) {
      return const Color(0xFFEF4444);
    }
    return const Color(0xFFE2E8F0);
  }

  /// Giao diện Thẻ lật Flashcard
  Widget _buildFlashcardView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _cards.length,
            backgroundColor: AppColors.border,
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Thẻ ${_currentIndex + 1} / ${_cards.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.muted, fontSize: 12)),
              Text('Đã thuộc: $_rememberedCount', style: const TextStyle(color: AppColors.accentEmerald, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _showAnswer = !_showAnswer),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 280,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _showAnswer ? AppColors.primaryLight : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _showAnswer ? AppColors.primary : AppColors.border, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_showAnswer ? Icons.lightbulb : Icons.help_outline, color: _showAnswer ? AppColors.primary : AppColors.muted, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        _showAnswer ? 'CÂU TRẢ LỜI' : 'CÂU HỎI (BẤM ĐỂ LẬT)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _showAnswer ? AppColors.primary : AppColors.muted, letterSpacing: 1.1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Text(
                          _showAnswer ? _cards[_currentIndex].answer : _cards[_currentIndex].question,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: _showAnswer ? 15 : 17, fontWeight: _showAnswer ? FontWeight.w500 : FontWeight.bold, color: AppColors.text, height: 1.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (_currentIndex < _cards.length - 1) {
                      setState(() {
                        _currentIndex++;
                        _showAnswer = false;
                      });
                    }
                  },
                  icon: const Icon(Icons.close, color: AppColors.danger),
                  label: const Text('Cần xem lại', style: TextStyle(color: AppColors.danger)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    _rememberedCount++;
                    if (_currentIndex < _cards.length - 1) {
                      setState(() {
                        _currentIndex++;
                        _showAnswer = false;
                      });
                    }
                  },
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Đã thuộc'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.accentEmerald),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
