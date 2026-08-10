import 'package:flutter/material.dart';

import '../../../features/auth/api.dart';
import '../../../core/models/subject_class_model.dart';
import 'create_subject_class_screen.dart';

// Đổi tên widget thành SubjectClassScreen (thay vì SubjectClass) để KHÔNG
// trùng tên với model dữ liệu `SubjectClass` / enum liên quan, tránh
// nhầm lẫn kiểu dữ liệu như lỗi trước đó.
class SubjectClassScreen extends StatefulWidget {
  const SubjectClassScreen({super.key});

  @override
  State<SubjectClassScreen> createState() => _SubjectClassScreenState();
}

class _SubjectClassScreenState extends State<SubjectClassScreen> {
  late Future<List<SubjectClass>> _classesFuture;

  @override
  void initState() {
    super.initState();
    _classesFuture = ApiService.getSubjectClass();
  }

  Future<void> _refresh() async {
    final future = ApiService.getSubjectClass();
    setState(() {
      _classesFuture = future;
    });
    try {
      // FutureBuilder ở build() sẽ tự hiển thị lỗi qua snapshot.hasError khi
      // _classesFuture rebuild, nên ở đây chỉ cần "chờ" để RefreshIndicator
      // biết khi nào dừng animation — KHÔNG được để lỗi thoát ra ngoài,
      // nếu không sẽ trở thành unhandled exception và làm crash app.
      await future;
    } catch (_) {
      // Lỗi đã được xử lý hiển thị ở FutureBuilder, không cần làm gì thêm ở đây.
    }
  }

  Future<void> _openAddClassSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true, // để sheet đẩy lên trên khi bàn phím hiện
      backgroundColor: Colors.transparent,
      builder: (context) => const AddSubjectClassSheet(),
    );

    // Nếu tạo thành công (sheet trả về true) thì tải lại danh sách.
    if (created == true) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<SubjectClass>>(
          future: _classesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Lỗi: ${snapshot.error}'));
            }

            final classes = snapshot.data ?? [];

            if (classes.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 160),
                    Center(child: Text('Hiện không có lớp nào cả!')),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: classes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _buildClassCard(classes[index]),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddClassSheet,
        label: const Text('Add'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildClassCard(SubjectClass item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E1F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.subjectClassName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(item.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${item.semester.label} • Năm học ${item.academicYear}',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          if (item.maxStudents != null) ...[
            const SizedBox(height: 4),
            Text(
              'Sĩ số tối đa: ${item.maxStudents}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ClassStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
