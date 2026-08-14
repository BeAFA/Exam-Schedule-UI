import 'package:flutter/material.dart';
import 'package:ui/core/models/schedule_model.dart';

import '../../../features/auth/api.dart';
import '../../../core/models/subject_class_model.dart';
import '../../../core/models/subject_model.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/models/teaching_assignment_model.dart';
import '../../../core/models/enum_model.dart';
import 'create_subject_class_screen.dart';
import 'assign_teacher_screen.dart';

// Đổi tên widget thành SubjectClassScreen (thay vì SubjectClass) để KHÔNG
// trùng tên với model dữ liệu `SubjectClass` / enum liên quan, tránh
// nhầm lẫn kiểu dữ liệu như lỗi trước đó.
class SubjectClassScreen extends StatefulWidget {
  const SubjectClassScreen({super.key});

  @override
  State<SubjectClassScreen> createState() => _SubjectClassScreenState();
}

/// Gói toàn bộ dữ liệu cần cho màn hình vào 1 chỗ để chỉ cần 1
/// FutureBuilder duy nhất (đơn giản hoá state, tránh nhiều future rời rạc
/// dễ lệch nhau khi refresh).
class _ScreenData {
  final List<SubjectClass> classes;
  final Map<int, Subject> subjectsById;
  final List<Profile> teachers;
  final Map<int, Profile> teachersById;
  final Map<int, TeachingAssignment?> assignmentsByClassId;
  final Map<int, Schedule?> schedulesByClassId;

  _ScreenData({
    required this.classes,
    required this.subjectsById,
    required this.teachers,
    required this.teachersById,
    required this.assignmentsByClassId,
    required this.schedulesByClassId,
  });
}

class _SubjectClassScreenState extends State<SubjectClassScreen> {
  late Future<_ScreenData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadAll();
  }

  Future<_ScreenData> _loadAll() async {
    final results = await Future.wait([
      ApiService.getSubjectClass(),
      ApiService.getSubjects(),
      ApiService.getTeachers(),
      ApiService.getSchedules(),
    ]);

    final classes = results[0] as List<SubjectClass>;
    final subjects = results[1] as List<Subject>;
    final teachers = results[2] as List<Profile>;
    final schedules = results[3] as List<Schedule>;

    final subjectsById = {for (final s in subjects) s.id: s};
    final teachersById = {for (final t in teachers) t.id: t};

    // GET /subject_class chỉ trả cột của SubjectClass, KHÔNG kèm giảng viên,
    // nên phải gọi riêng cho từng lớp (song song). Nếu 1 lớp lỗi khi lấy
    // phân công thì coi như "chưa có giảng viên" thay vì làm sập cả màn hình.
    final assignmentEntries = await Future.wait(
      classes.map((c) async {
        try {
          final a = await ApiService.getTeachingAssignment(c.id);
          return MapEntry(c.id, a);
        } catch (_) {
          return MapEntry(c.id, null);
        }
      }),
    );

    final schedulesByClassId = <int, Schedule?>{
      for (final schedule in schedules)
        schedule.subjectClassId: schedule,
    };

    return _ScreenData(
      classes: classes,
      subjectsById: subjectsById,
      teachers: teachers,
      teachersById: teachersById,
      assignmentsByClassId: Map.fromEntries(assignmentEntries),
      schedulesByClassId: schedulesByClassId,
    );
  }

  Future<void> _refresh() async {
    final future = _loadAll();
    setState(() {
      _dataFuture = future;
    });
    try {
      // FutureBuilder ở build() sẽ tự hiển thị lỗi qua snapshot.hasError khi
      // _dataFuture rebuild, nên ở đây chỉ cần "chờ" để RefreshIndicator
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
      builder: (context) => const SubjectClassFormSheet(),
    );

    if (created == true) {
      await _refresh();
    }
  }

  Future<void> _openEditClassSheet(
    SubjectClass item,
    String? subjectName,
    Schedule? schedule,
  ) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SubjectClassFormSheet(
        existing: item,
        existingSubjectName: subjectName,
        existingSchedule: schedule,
      ),
    );

    if (updated == true) {
      await _refresh();
    }
  }

  Future<void> _openAssignTeacherSheet(
    SubjectClass item,
    List<Profile> teachers,
    TeachingAssignment? existingAssignment,
    Profile? currentTeacher,
  ) async {
    final result = await showModalBottomSheet<TeachingAssignment>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssignTeacherScreen(
        subjectClass: item,
        teachers: teachers,
        existingAssignment: existingAssignment,
        currentTeacher: currentTeacher,
      ),
    );

    if (result != null) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<_ScreenData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Lỗi: ${snapshot.error}'));
            }

            final data = snapshot.data!;
            final classes = data.classes;

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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: classes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = classes[index];
                  final subjectName = data.subjectsById[item.subjectId]?.name;
                  final assignment = data.assignmentsByClassId[item.id];
                  final teacher = assignment == null
                      ? null
                      : data.teachersById[assignment.teacherId];
                  final schedule =
                      data.schedulesByClassId[item.id];

                  return _buildClassCard(
                    item: item,
                    subjectName: subjectName,
                    assignment: assignment,
                    teacher: teacher,
                    teachers: data.teachers,
                    schedule: schedule,
                  );
                },
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

  Widget _buildClassCard({
    required SubjectClass item,
    required String? subjectName,
    required TeachingAssignment? assignment,
    required Profile? teacher,
    required List<Profile> teachers,
    required Schedule? schedule,
  }) {
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
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Sửa lớp',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _openEditClassSheet(item, subjectName, schedule,),
              ),
            ],
          ),
          if (subjectName != null) ...[
            const SizedBox(height: 2),
            Text(
              subjectName,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
          ],
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

          if (schedule != null) ...[
            const SizedBox(height: 4),
            Text(
              'Lịch: ${schedule.weekday.label} • '
              '${schedule.session.label} • '
              '${schedule.room.name}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  teacher != null
                      ? teacher.fullName
                      : 'Chưa phân công giảng viên',
                  style: TextStyle(
                    color: teacher != null ? Colors.black87 : Colors.grey,
                    fontSize: 13,
                    fontStyle: teacher != null
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: () => _openAssignTeacherSheet(
                  item,
                  teachers,
                  assignment,
                  teacher,
                ),
                icon: Icon(
                  assignment != null ? Icons.edit : Icons.add,
                  size: 16,
                ),
                label: Text(assignment != null ? 'Sửa GV' : 'Thêm GV'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
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
