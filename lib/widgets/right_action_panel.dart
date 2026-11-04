import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/auth_service.dart';
import '../ui_refinement/guest/guest_session.dart';

/// Thanh tác vụ bên phải (Right Action Panel / EndDrawer)
/// Đúng theo yêu cầu của người dùng:
/// 1. Biểu tượng Đăng nhập với các chức năng đăng nhập như cũ (Xóa bỏ chữ "Xin chào khách")
/// 2. Phần Tạo ghi chú (+ Tạo ghi chú mới)
/// 3. Phần Chỉnh sửa (Chỉnh sửa nội dung)
class RightActionPanel extends StatelessWidget {
  final AuthService? authService;
  final List<Note> notes;
  final VoidCallback onNewNote;
  final ValueChanged<Note> onSelectNote;
  final void Function(String route)? onViewChanged;
  final VoidCallback? onOpenAuth;
  final VoidCallback? onClose;
  final double width;

  const RightActionPanel({
    super.key,
    this.authService,
    required this.notes,
    required this.onNewNote,
    required this.onSelectNote,
    this.onViewChanged,
    this.onOpenAuth,
    this.onClose,
    this.width = 280,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = authService?.currentUser;
    final isLoggedIn = user != null && !GuestSession().isGuestMode;
    final username = user?.username ?? (user?.fullName.isNotEmpty == true ? user!.fullName : 'Khách');

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          left: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tiêu đề thanh tác vụ bên phải & Nút đóng
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune_rounded, size: 20, color: Color(0xFF6366F1)),
                      SizedBox(width: 8),
                      Text(
                        'Thanh tác vụ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (onClose != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onClose,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 18),

              // =========================================================
              // PHẦN 1: BIỂU TƯỢNG ĐĂNG NHẬP (Theo cách cũ, XÓA "Xin chào khách")
              // =========================================================
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isLoggedIn
                      ? (isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF2FF))
                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isLoggedIn
                        ? const Color(0xFF818CF8).withValues(alpha: 0.4)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: isLoggedIn ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
                      child: Icon(
                        isLoggedIn ? Icons.person_rounded : Icons.account_circle_outlined,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isLoggedIn ? username : 'Tài khoản người dùng',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoggedIn ? (user.email.isNotEmpty ? user.email : 'Đã đăng nhập') : 'Lưu trữ an toàn trên thiết bị',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: isLoggedIn ? const Color(0xFFEF4444) : const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () {
                          if (onClose != null) onClose!();
                          if (isLoggedIn) {
                            authService?.logout();
                          } else {
                            onOpenAuth?.call();
                          }
                        },
                        icon: Icon(
                          isLoggedIn ? Icons.logout_rounded : Icons.login_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          isLoggedIn ? 'Đăng xuất' : 'Đăng nhập ngay',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // =========================================================
              // PHẦN 2: TẠO GHI CHÚ
              // =========================================================
              const Text(
                'QUẢN LÝ TỆP & NỘI DUNG',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),

              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () {
                  if (onClose != null) onClose!();
                  onNewNote();
                },
                icon: const Icon(Icons.note_add_rounded, size: 20),
                label: const Text(
                  'Tạo ghi chú mới',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
              const SizedBox(height: 12),

              // =========================================================
              // PHẦN 3: CHỈNH SỬA LÀ CHỈNH SỬA NỘI DUNG
              // =========================================================
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
                  side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  if (onClose != null) onClose!();
                  if (notes.isNotEmpty) {
                    onSelectNote(notes.first);
                  } else {
                    onViewChanged?.call('notes');
                  }
                },
                icon: const Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF6366F1)),
                label: const Text(
                  'Chỉnh sửa nội dung',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Lối tắt chuyển trang nhanh
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.folder_copy_outlined, size: 20, color: Color(0xFFD97706)),
                title: const Text('Mở Thư mục tổng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                onTap: () {
                  if (onClose != null) onClose!();
                  onViewChanged?.call('folders');
                },
              ),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.checklist_rounded, size: 20, color: Color(0xFF10B981)),
                title: const Text('Việc cần làm (Checklist)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                onTap: () {
                  if (onClose != null) onClose!();
                  onViewChanged?.call('tasks');
                },
              ),

              const Spacer(),

              // Thông tin trạng thái dưới đáy thanh bên phải
              Text(
                'SmartNoteAI v2.0 • Offline-first',
                style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
