import 'package:flutter/material.dart';

import '../../../features/auth/api.dart';
import '../../../core/models/schedule_model.dart';
import '../../../core/models/exam_model.dart';
import '../../../core/models/subject_class_model.dart';
import '../../../core/models/subject_model.dart'; // Thêm SubjectModel
import '../../../core/models/room_model.dart';
import '../../../core/models/enum_model.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/models/teaching_assignment_model.dart';
import '../../../core/models/exam_invigilator_model.dart';
import '../../../core/models/calendar_event.dart';
import 'daily_view.dart';
import 'weekly_view.dart';
import 'create_subject_class_screen.dart';
import 'create_exam_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late Future<Map<String, dynamic>> _fetchDataFuture;

  bool _isWeeklyView = false;
  DateTime _currentDate = DateTime.now();

  // Bộ lọc hiển thị cho chế độ Tuần: cho phép chọn xem Học phần, Lịch thi, hoặc cả hai
  bool _showClasses = true;
  bool _showExams = true;

  @override
  void initState() {
    super.initState();
    _fetchDataFuture = _loadAllData();
  }

  Future<Map<String, dynamic>> _loadAllData() async {
    // Tải thêm thông tin Môn học (Subjects) để hiển thị tên môn
    final results = await Future.wait([
      ApiService.getSubjectClass(),
      ApiService.getSchedules(),
      ApiService.getExams(),
      ApiService.getRooms(),
      ApiService.getTeachers(),
      ApiService.getSubjects(), // Gọi API Môn học
    ]);

    final classes = results[0] as List<SubjectClass>;
    final schedules = results[1] as List<Schedule>;
    final exams = results[2] as List<Exam>;
    final rooms = results[3] as List<Room>;
    final teachers = results[4] as List<Profile>;
    final subjects = results[5] as List<Subject>;

    final classesById = {for (var c in classes) c.id: c};
    final roomsById = {for (var r in rooms) r.id: r};
    final teachersById = {for (var t in teachers) t.id: t};
    final subjectsById = {for (var s in subjects) s.id: s};

    final assignmentsData = await Future.wait(
      classes.map((c) async {
        try {
          final assign = await ApiService.getTeachingAssignment(c.id);
          return MapEntry(c.id, assign);
        } catch (_) {
          return MapEntry(c.id, null);
        }
      }),
    );
    final assignmentsMap = Map.fromEntries(assignmentsData);

    final invigilatorsData = await Future.wait(
      exams.map((e) async {
        try {
          final invs = await ApiService.getExamInvigilators(e.id);
          return MapEntry(e.id, invs);
        } catch (_) {
          return MapEntry(e.id, <ExamInvigilator>[]);
        }
      }),
    );
    final invigilatorsMap = Map.fromEntries(invigilatorsData);

    return {
      'classes': classesById,
      'schedules': schedules,
      'exams': exams,
      'rooms': roomsById,
      'teachers': teachersById,
      'subjects': subjectsById, // Đưa subjectsById vào map
      'assignments': assignmentsMap,
      'invigilators': invigilatorsMap,
    };
  }

  Future<void> _refresh() async {
    final future = _loadAllData();
    setState(() {
      _fetchDataFuture = future;
    });
    try {
      // FutureBuilder ở build() sẽ tự hiển thị lỗi qua snapshot.hasError,
      // ở đây chỉ cần "chờ" để biết khi nào dữ liệu mới đã sẵn sàng.
      await future;
    } catch (_) {
      // Lỗi đã được xử lý hiển thị ở FutureBuilder.
    }
  }

  // Mở form Tạo lớp học phần (giống subject_class_screen.dart)
  Future<void> _openAddClassSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SubjectClassFormSheet(),
    );

    if (created == true) {
      await _refresh();
    }
  }

  // Mở form Tạo lịch thi (giống exam_screen.dart)
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

  DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _getMonday(DateTime date) {
    int day = date.weekday;
    return date.subtract(Duration(days: day - 1));
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
  String _formatDate(DateTime d) => '${_pad(d.day)}/${_pad(d.month)}/${d.year}';

  int _getDartWeekday(Weekday w) {
    switch (w) {
      case Weekday.mon: return 1;
      case Weekday.tue: return 2;
      case Weekday.wed: return 3;
      case Weekday.thu: return 4;
      case Weekday.fri: return 5;
      case Weekday.sat: return 6;
      case Weekday.sun: return 7;
    }
  }

  void _toggleShowClasses() {
    // Không cho phép tắt nếu đây là lựa chọn duy nhất đang bật
    if (_showClasses && !_showExams) return;
    setState(() => _showClasses = !_showClasses);
  }

  void _toggleShowExams() {
    if (_showExams && !_showClasses) return;
    setState(() => _showExams = !_showExams);
  }

  void _changeDate(int offset) {
    setState(() {
      if (_isWeeklyView) {
        _currentDate = _currentDate.add(Duration(days: 7 * offset));
      } else {
        _currentDate = _currentDate.add(Duration(days: offset));
      }
    });
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6E8CF0),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _currentDate) {
      setState(() {
        _currentDate = picked;
      });
    }
  }

  List<CalendarEvent> _getEventsForDate(DateTime targetDate, Map<String, dynamic> data) {
    final classesById = data['classes'] as Map<int, SubjectClass>;
    final schedules = data['schedules'] as List<Schedule>;
    final exams = data['exams'] as List<Exam>;
    final roomsById = data['rooms'] as Map<int, Room>;
    final teachersById = data['teachers'] as Map<int, Profile>;
    final subjectsById = data['subjects'] as Map<int, Subject>;
    final assignmentsMap = data['assignments'] as Map<int, TeachingAssignment?>;
    final invigilatorsMap = data['invigilators'] as Map<int, List<ExamInvigilator>>;

    List<CalendarEvent> events = [];
    final target = _stripTime(targetDate);

    // Lọc sự kiện Lớp học phần
    for (var sch in schedules) {
      final cls = classesById[sch.subjectClassId];
      if (cls == null || cls.startDate == null) continue;

      final start = _stripTime(cls.startDate!);
      if (target.isBefore(start)) continue;

      final daysDiff = target.difference(start).inDays;
      final weeksElapsed = daysDiff ~/ 7;
      
      if (weeksElapsed < (cls.numberOfSessions ?? 0) &&
          target.weekday == _getDartWeekday(sch.weekday)) {
        
        final room = roomsById[sch.roomId];
        final assign = assignmentsMap[cls.id];
        String teacherName = 'Chưa phân công';
        if (assign != null && teachersById.containsKey(assign.teacherId)) {
          final t = teachersById[assign.teacherId]!;
          teacherName = '${t.firstName} ${t.lastName}';
        }

        final subjectName = subjectsById[cls.subjectId]?.name;

        events.add(CalendarEvent(
          title: cls.subjectClassName,
          roomName: room?.name ?? 'Không rõ',
          teacherName: teacherName,
          isExam: false,
          session: sch.session.value.toUpperCase(),
          subjectName: subjectName,
          academicYear: cls.academicYear,
          semesterLabel: cls.semester.label,
          maxStudents: cls.maxStudents,
          numberOfSessions: cls.numberOfSessions,
          startDate: cls.startDate,
          classStatus: cls.status,
        ));
      }
    }

    // Lọc sự kiện Lịch thi
    for (var ex in exams) {
      final examDate = _stripTime(ex.examDate);
      if (examDate.isAtSameMomentAs(target)) {
        final cls = classesById[ex.subjectClassId];
        final room = roomsById[ex.roomId];
        
        final invs = invigilatorsMap[ex.id] ?? [];
        String teacherName = 'Chưa phân công';
        if (invs.isNotEmpty) {
          teacherName = invs.map((i) {
            final t = teachersById[i.teacherId];
            return t != null ? '${t.firstName} ${t.lastName}' : 'Không rõ';
          }).join(', ');
        }

        String session = 'MORNING';
        if (ex.timeFrame.value.contains('13:') || ex.timeFrame.value.contains('15:')) {
          session = 'AFTERNOON';
        } else if (ex.timeFrame.value.contains('18:')) {
          session = 'EVENING';
        }

        String typeLabel = ex.type.name == 'midterm' ? 'Giữa kỳ' : 'Cuối kỳ';

        events.add(CalendarEvent(
          title: '${cls?.subjectClassName ?? 'Môn thi'} (Thi)',
          roomName: room?.name ?? 'Không rõ',
          teacherName: teacherName,
          isExam: true,
          session: session,
          examTime: ex.timeFrame.value,
          duration: ex.duration,
          examTypeLabel: typeLabel,
          examStatus: ex.status,
          examDate: ex.examDate,
        ));
      }
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Trong suốt để không che layout/màu nền vốn có của trang này —
      // chỉ mượn Scaffold để có chỗ gắn floatingActionButton.
      backgroundColor: Colors.transparent,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6E8CF0)));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
          }

          final mapData = snapshot.data!;

          return Column(
            children: [
              _buildControlHeader(),
              Expanded(
                child: _isWeeklyView 
                    ? WeeklyView(
                        currentDate: _currentDate, 
                        getEventsForDate: (d) => _getEventsForDate(d, mapData),
                        showClasses: _showClasses,
                        showExams: _showExams,
                      ) 
                    : DailyView(
                        currentDate: _currentDate,
                        getEventsForDate: (d) => _getEventsForDate(d, mapData),
                        showClasses: _showClasses,
                        showExams: _showExams,
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'schedule_add_class_fab',
            backgroundColor: const Color(0xFF6E8CF0),
            onPressed: _openAddClassSheet,
            label: const Text('Thêm lớp', style: TextStyle(color: Colors.white)),
            icon: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'schedule_add_exam_fab',
            backgroundColor: Colors.orange,
            onPressed: _openCreateExamSheet,
            label: const Text('Xếp lịch thi', style: TextStyle(color: Colors.white)),
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildControlHeader() {
    String dateRangeStr = '';
    if (_isWeeklyView) {
      DateTime monday = _getMonday(_currentDate);
      DateTime sunday = monday.add(const Duration(days: 6));
      dateRangeStr = '${_formatDate(monday)} - ${_formatDate(sunday)}';
    } else {
      dateRangeStr = _formatDate(_currentDate);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          ToggleButtons(
            isSelected: [!_isWeeklyView, _isWeeklyView],
            onPressed: (index) {
              setState(() => _isWeeklyView = index == 1);
            },
            borderRadius: BorderRadius.circular(8),
            selectedColor: Colors.white,
            fillColor: const Color(0xFF6E8CF0),
            color: const Color(0xFF6E8CF0),
            constraints: const BoxConstraints(minHeight: 32, minWidth: 80),
            children: const [Text('Ngày'), Text('Tuần')],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Color(0xFF6E8CF0), size: 30),
                onPressed: () => _changeDate(-1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dateRangeStr,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_month, color: Color(0xFF6E8CF0), size: 22),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Color(0xFF6E8CF0), size: 30),
                onPressed: () => _changeDate(1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFilterToggle(
                color: const Color(0xFF6E8CF0),
                label: 'Học phần',
                selected: _showClasses,
                onTap: _toggleShowClasses,
              ),
              const SizedBox(width: 12),
              _buildFilterToggle(
                color: Colors.orange,
                label: 'Lịch thi',
                selected: _showExams,
                onTap: _toggleShowExams,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Nút bấm chọn lọc hiển thị: có thể chọn 1 trong 2, hoặc cả 2 (không cho chọn 0)
  Widget _buildFilterToggle({
    required Color color,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: selected ? color : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? color : Colors.grey.shade600,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check, size: 12, color: color),
            ],
          ],
        ),
      ),
    );
  }
}