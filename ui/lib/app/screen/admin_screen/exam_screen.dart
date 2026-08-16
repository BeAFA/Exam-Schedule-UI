import 'package:flutter/material.dart';

import '../../../features/auth/api.dart';
import '../../../core/models/exam_model.dart';
import '../../../core/models/subject_class_model.dart';
import '../../../core/models/room_model.dart';
import '../../../core/models/enum_model.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/models/exam_invigilator_model.dart'; 
import 'create_exam_screen.dart'; 
import 'assign_invigilator_screen.dart'; 

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ScreenData {
  final List<Exam> exams;
  final Map<int, SubjectClass> classesById;
  final Map<int, Room> roomsById;
  final List<Profile> teachers;
  final Map<int, Profile> teachersById;
  final Map<int, List<ExamInvigilator>> invigilatorsByExamId;

  _ScreenData({
    required this.exams,
    required this.classesById,
    required this.roomsById,
    required this.teachers,
    required this.teachersById,
    required this.invigilatorsByExamId,
  });
}

class _ExamScreenState extends State<ExamScreen> {
  late Future<_ScreenData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadAll();
  }

  Future<_ScreenData> _loadAll() async {
    final results = await Future.wait([
      ApiService.getExams(),
      ApiService.getSubjectClass(),
      ApiService.getRooms(),
      ApiService.getTeachers(),
    ]);

    final exams = results[0] as List<Exam>;
    final classes = results[1] as List<SubjectClass>;
    final rooms = results[2] as List<Room>;
    final teachers = results[3] as List<Profile>;

    final classesById = {for (final c in classes) c.id: c};
    final roomsById = {for (final r in rooms) r.id: r};
    final teachersById = {for (final t in teachers) t.id: t};

    // Tương tự _loadAll bên subject class, fetch giảng viên coi thi cho từng lịch thi[cite: 6, 8, 9]
    final invigilatorEntries = await Future.wait(
      exams.map((e) async {
        try {
          final invs = await ApiService.getExamInvigilators(e.id);
          return MapEntry(e.id, invs);
        } catch (_) {
          return MapEntry(e.id, <ExamInvigilator>[]);
        }
      }),
    );

    return _ScreenData(
      exams: exams,
      classesById: classesById,
      roomsById: roomsById,
      teachers: teachers,
      teachersById: teachersById,
      invigilatorsByExamId: Map.fromEntries(invigilatorEntries),
    );
  }

  Future<void> _refresh() async {
    final future = _loadAll();
    setState(() {
      _dataFuture = future;
    });
    try {
      await future;
    } catch (_) {}
  }

  // Mở form Tạo mới (existing: null)
  Future<void> _openCreateExamSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateExamSheet(), 
    );
    if (created == true) {
      await _refresh();
    }
  }

  // Mở form Chỉnh sửa (truyền existing model vào)
  Future<void> _openEditExamSheet(Exam exam, SubjectClass? subjectClass, Room? room) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Lưu ý: Sửa CreateExamSheet hỗ trợ nạp dữ liệu existing (giống SubjectClassFormSheet)[cite: 7]
      builder: (context) => CreateExamSheet(
        existing: exam,
        existingClass: subjectClass,
        existingRoom: room,
      ),
    );
    if (updated == true) {
      await _refresh();
    }
  }

  // Mở màn hình Thêm/Sửa CBCT
  Future<void> _openAssignInvigilatorSheet(
    Exam exam,
    List<Profile> teachers,
    List<ExamInvigilator> currentInvigilators,
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Tương tự AssignTeacherScreen bên lớp học phần[cite: 6]
      builder: (context) => AssignInvigilatorSheet(
        exam: exam,
        teachers: teachers,
        currentInvigilators: currentInvigilators,
      ),
    );
    if (result == true) {
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
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6E8CF0)));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
            }

            final data = snapshot.data!;
            if (data.exams.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 160),
                    Center(
                        child: Text('Chưa có lịch thi nào được xếp.',
                            style: TextStyle(color: Colors.grey))),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: data.exams.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final exam = data.exams[index];
                  final subjectClass = data.classesById[exam.subjectClassId];
                  final room = data.roomsById[exam.roomId];
                  final invigilators = data.invigilatorsByExamId[exam.id] ?? [];

                  return _buildExamCard(
                    exam: exam,
                    subjectClass: subjectClass,
                    room: room,
                    invigilators: invigilators,
                    teachersById: data.teachersById,
                    teachers: data.teachers,
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6E8CF0),
        onPressed: _openCreateExamSheet,
        label: const Text('Xếp lịch thi', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildExamCard({
    required Exam exam,
    required SubjectClass? subjectClass,
    required Room? room,
    required List<ExamInvigilator> invigilators,
    required Map<int, Profile> teachersById,
    required List<Profile> teachers,
  }) {
    // Convert list id CBCT ra chuỗi tên (đề phòng 1 lịch có >=1 cán bộ)[cite: 8, 9, 10]
    final invigilatorNames = invigilators.map((inv) {
      final t = teachersById[inv.teacherId];
      return t != null ? '${t.firstName} ${t.lastName}' : 'Không rõ';
    }).join(', ');

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
                  subjectClass?.subjectClassName ?? 'Lớp không xác định',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(exam.status),
              // NÚT CHỈNH SỬA (Giống card subject class)[cite: 6]
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Sửa lịch thi',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _openEditExamSheet(exam, subjectClass, room),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Ngày thi: ${exam.examDate.day}/${exam.examDate.month}/${exam.examDate.year}',
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Khung giờ: ${exam.timeFrame.value} (${exam.duration} phút)',
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.room, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Phòng: ${room?.name ?? 'Không xác định'}',
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          
          // DÒNG QUẢN LÝ CÁN BỘ COI THI (Tương tự giảng viên lớp học phần)[cite: 6]
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  invigilators.isNotEmpty ? invigilatorNames : 'Chưa phân công CBCT',
                  style: TextStyle(
                    color: invigilators.isNotEmpty ? Colors.black87 : Colors.grey,
                    fontSize: 13,
                    fontStyle: invigilators.isNotEmpty
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: () => _openAssignInvigilatorSheet(
                  exam,
                  teachers,
                  invigilators,
                ),
                icon: Icon(
                  invigilators.isNotEmpty ? Icons.edit : Icons.add,
                  size: 16,
                ),
                label: Text(invigilators.isNotEmpty ? 'Sửa CBCT' : 'Thêm CBCT'),
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

  Widget _buildStatusBadge(ExamStatus status) {
    final color = status == ExamStatus.scheduled ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}