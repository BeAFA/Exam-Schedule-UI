import 'package:flutter/material.dart';

import '../../../features/auth/api.dart';
import '../../../core/models/exam_model.dart';
import '../../../core/models/subject_class_model.dart';
import '../../../core/models/room_model.dart';
import '../../../core/models/enum_model.dart';
import 'create_exam_screen.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ScreenData {
  final List<Exam> exams;
  final Map<int, SubjectClass> classesById;
  final Map<int, Room> roomsById;

  _ScreenData({
    required this.exams,
    required this.classesById,
    required this.roomsById,
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
    // API mock name based on typical implementation, update with exact API names
    final results = await Future.wait([
      ApiService.getExams(), // Giả sử bạn có hàm lấy danh sách Exam
      ApiService.getSubjectClass(),
      ApiService.getRooms(),
    ]);

    final exams = results[0] as List<Exam>;
    final classes = results[1] as List<SubjectClass>;
    final rooms = results[2] as List<Room>;

    return _ScreenData(
      exams: exams,
      classesById: {for (final c in classes) c.id: c},
      roomsById: {for (final r in rooms) r.id: r},
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _dataFuture = _loadAll();
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // Nền xám nhạt nhẹ nhàng
      body: SafeArea(
        child: FutureBuilder<_ScreenData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF6E8CF0)));
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
                    Center(child: Text('Chưa có lịch thi nào được xếp.', style: TextStyle(color: Colors.grey))),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: data.exams.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final exam = data.exams[index];
                  final subjectClass = data.classesById[exam.subjectClassId];
                  final room = data.roomsById[exam.roomId];

                  return _buildExamCard(exam, subjectClass, room);
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

  Widget _buildExamCard(Exam exam, SubjectClass? subjectClass, Room? room) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E1F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subjectClass?.subjectClassName ?? 'Lớp không xác định',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusBadge(exam.status),
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
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ExamStatus status) {
    // Tùy chỉnh màu theo enum ExamStatus (ví dụ)
    final color = status == ExamStatus.scheduled ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}