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
  final Map<int, Profile> teachersById;
  final List<Profile> teachers;
  final Map<int, List<ExamInvigilator>> invigilatorsByExamId;

  _ScreenData({
    required this.exams,
    required this.classesById,
    required this.roomsById,
    required this.teachersById,
    required this.teachers,
    required this.invigilatorsByExamId,
  });
}

class _ExamScreenState extends State<ExamScreen> {
  late Future<_ScreenData> _dataFuture;
  final Set<int> _selectedIds = {};

  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  TypeOfExam? _filterType;
  TimeFrame? _filterTimeFrame;
  ExamStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadAll();
  }

  Future<_ScreenData> _loadAll() async {
    final exams = await ApiService.getExams();
    final classes = await ApiService.getSubjectClasses();
    final rooms = await ApiService.getRooms();
    final teachers = await ApiService.getTeachers();

    final classesById = {for (final c in classes) c.id: c};
    final roomsById = {for (final r in rooms) r.id: r};
    final teachersById = {for (final t in teachers) t.id: t};

    final invigilatorEntries = await Future.wait(
      exams.map((e) async {
        try {
          final list = await ApiService.getExamInvigilators(e.id);
          return MapEntry(e.id, list);
        } catch (_) {
          return MapEntry(e.id, <ExamInvigilator>[]);
        }
      }),
    );

    return _ScreenData(
      exams: exams,
      classesById: classesById,
      roomsById: roomsById,
      teachersById: teachersById,
      teachers: teachers,
      invigilatorsByExamId: Map.fromEntries(invigilatorEntries),
    );
  }

  Future<void> _refresh() async {
    final future = _loadAll();
    setState(() {
      _selectedIds.clear();
      _dataFuture = future;
    });
    try {
      await future;
    } catch (_) {}
  }

  Future<void> _handleBulkActiveChange(bool isActive) async {
    if (_selectedIds.isEmpty) return;
    final actionText = isActive ? 'mở' : 'đóng';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xác nhận $actionText'),
        content: Text(
          'Bạn có chắc muốn $actionText ${_selectedIds.length} lịch thi đã chọn?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.changeExamActive(
          ids: _selectedIds.toList(),
          isActive: isActive,
        );
        await _refresh();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _openCreateExamSheet({Exam? existing, SubjectClass? existingClass, Room? existingRoom}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateExamSheet(
        existing: existing,
        existingClass: existingClass,
        existingRoom: existingRoom,
      ),
    );
    if (result == true) {
      await _refresh();
    }
  }

  Future<void> _openAssignInvigilatorSheet(
    Exam exam,
    List<Profile> teachers,
    List<ExamInvigilator> currentInvigilators,
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bộ lọc Lịch thi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setSheetState(() {
                            _startDate = picked;
                            _endDate = picked;
                          });
                        }
                      },
                      child: Text(
                        _startDate == null
                            ? 'Từ ngày'
                            : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setSheetState(() => _endDate = picked);
                        }
                      },
                      child: Text(
                        _endDate == null
                            ? 'Đến ngày'
                            : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<TypeOfExam>(
                initialValue: _filterType,
                decoration: const InputDecoration(labelText: 'Loại hình thi'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tất cả')),
                  ...TypeOfExam.values.map(
                    (t) => DropdownMenuItem(value: t, child: Text(t.value)),
                  ),
                ],
                onChanged: (val) => setSheetState(() => _filterType = val),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<TimeFrame>(
                initialValue: _filterTimeFrame,
                decoration: const InputDecoration(labelText: 'Khung giờ'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tất cả')),
                  ...TimeFrame.values.map(
                    (tf) => DropdownMenuItem(value: tf, child: Text(tf.value)),
                  ),
                ],
                onChanged: (val) => setSheetState(() => _filterTimeFrame = val),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ExamStatus>(
                initialValue: _filterStatus,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tất cả')),
                  ...ExamStatus.values.map(
                    (st) => DropdownMenuItem(value: st, child: Text(st.name)),
                  ),
                ],
                onChanged: (val) => setSheetState(() => _filterStatus = val),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                  Navigator.pop(ctx);
                },
                child: const Text('Áp dụng'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<_ScreenData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final filteredExams = data.exams.where((exam) {
            final subjectClass = data.classesById[exam.subjectClassId];
            final className = subjectClass?.subjectClassName.toLowerCase() ?? '';
            final matchName = className.contains(_searchQuery.toLowerCase());
            final matchStart = _startDate == null ||
                exam.examDate.isAfter(_startDate!.subtract(const Duration(days: 1)));
            final matchEnd = _endDate == null ||
                exam.examDate.isBefore(_endDate!.add(const Duration(days: 1)));
            final matchType = _filterType == null || exam.type == _filterType;
            final matchTF = _filterTimeFrame == null || exam.timeFrame == _filterTimeFrame;
            final matchStatus = _filterStatus == null || exam.status == _filterStatus;

            return matchName && matchStart && matchEnd && matchType && matchTF && matchStatus;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Tìm theo tên lớp học...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _openFilterSheet,
                    ),
                  ],
                ),
              ),
              if (_selectedIds.isNotEmpty)
                Container(
                  color: Colors.blue.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text('Đã chọn ${_selectedIds.length} lịch thi'),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => _handleBulkActiveChange(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Mở'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _handleBulkActiveChange(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Đóng'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: filteredExams.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 160),
                            Center(
                              child: Text(
                                'Chưa có lịch thi nào được xếp.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: filteredExams.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final exam = filteredExams[index];
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
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateExamSheet(),
        label: const Text('Xếp lịch thi'),
        icon: const Icon(Icons.add),
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
    final isSelected = _selectedIds.contains(exam.id);
    final isActive = (exam as dynamic).isActive ?? true;

    // [KHÔI PHỤC] Danh sách tên CBCT
    final invigilatorNames = invigilators.map((inv) {
      final t = teachersById[inv.teacherId];
      return t != null ? '${t.firstName} ${t.lastName}' : 'Không rõ';
    }).join(', ');

    return Opacity(
      opacity: isActive ? 1.0 : 0.5,
      child: Container(
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
                Checkbox(
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedIds.add(exam.id);
                      } else {
                        _selectedIds.remove(exam.id);
                      }
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    subjectClass?.subjectClassName ?? 'Lớp không xác định',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Đã đóng',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                _buildStatusBadge(exam.status),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Sửa lịch thi',
                  onPressed: () => _openCreateExamSheet(
                    existing: exam,
                    existingClass: subjectClass,
                    existingRoom: room,
                  ),
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
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}