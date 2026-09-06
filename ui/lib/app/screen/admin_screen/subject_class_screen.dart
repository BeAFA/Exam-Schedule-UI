import 'package:flutter/material.dart';

import '../../../features/auth/api.dart';
import '../../../core/models/subject_class_model.dart';
import '../../../core/models/subject_model.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/models/teaching_assignment_model.dart';
import '../../../core/models/schedule_model.dart';
import '../../../core/models/enum_model.dart';
import 'create_subject_class_screen.dart';
import 'assign_teacher_screen.dart';

class SubjectClassScreen extends StatefulWidget {
  const SubjectClassScreen({super.key});

  @override
  State<SubjectClassScreen> createState() => _SubjectClassScreenState();
}

class _ScreenData {
  final List<SubjectClass> classes;
  final Map<int, Subject> subjectsById;
  final Map<int, Profile> teachersById;
  final List<Profile> teachers;
  final Map<int, TeachingAssignment?> assignmentsByClassId;
  final Map<int, Schedule?> schedulesByClassId;

  _ScreenData({
    required this.classes,
    required this.subjectsById,
    required this.teachersById,
    required this.teachers,
    required this.assignmentsByClassId,
    required this.schedulesByClassId,
  });
}

class _SubjectClassScreenState extends State<SubjectClassScreen> {
  late Future<_ScreenData> _dataFuture;

  final Set<int> _selectedIds = {};
  String _searchQuery = '';
  Semester? _filterSemester;
  String? _filterAcademicYear;
  ClassStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadAll();
  }

  Future<_ScreenData> _loadAll() async {
    final classes = await ApiService.getSubjectClasses();
    final subjects = await ApiService.getSubjects();
    final teachers = await ApiService.getTeachers();
    final schedules = await ApiService.getSchedules();

    final subjectsById = {for (final s in subjects) s.id: s};
    final teachersById = {for (final t in teachers) t.id: t};

    final assignmentEntries = await Future.wait(
      classes.map((c) async {
        try {
          final assignment = await ApiService.getTeachingAssignment(c.id);
          return MapEntry(c.id, assignment);
        } catch (_) {
          return MapEntry(c.id, null);
        }
      }),
    );

    final schedulesByClassId = <int, Schedule?>{
      for (final schedule in schedules) schedule.subjectClassId: schedule,
    };

    return _ScreenData(
      classes: classes,
      subjectsById: subjectsById,
      teachersById: teachersById,
      teachers: teachers,
      assignmentsByClassId: Map.fromEntries(assignmentEntries),
      schedulesByClassId: schedulesByClassId,
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
          'Bạn có chắc muốn $actionText ${_selectedIds.length} lớp học phần đã chọn?',
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
        await ApiService.changeSubjectClassActive(
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
    final result = await showModalBottomSheet<bool>(
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

  void _openFilterSheet(List<String> availableYears) {
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
                'Bộ lọc Lớp học phần',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Semester>(
                initialValue: _filterSemester,
                decoration: const InputDecoration(labelText: 'Học kỳ'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tất cả')),
                  ...Semester.values.map(
                    (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                  ),
                ],
                onChanged: (val) => setSheetState(() => _filterSemester = val),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _filterAcademicYear,
                decoration: const InputDecoration(labelText: 'Năm học'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tất cả')),
                  ...availableYears.map(
                    (y) => DropdownMenuItem(value: y, child: Text(y)),
                  ),
                ],
                onChanged: (val) =>
                    setSheetState(() => _filterAcademicYear = val),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ClassStatus>(
                initialValue: _filterStatus,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tất cả')),
                  ...ClassStatus.values.map(
                    (st) => DropdownMenuItem(value: st, child: Text(st.label)),
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
          final academicYears =
              data.classes.map((c) => c.academicYear).toSet().toList();

          final filteredClasses = data.classes.where((item) {
            final matchName = item.subjectClassName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
            final matchSem =
                _filterSemester == null || item.semester == _filterSemester;
            final matchYear = _filterAcademicYear == null ||
                item.academicYear == _filterAcademicYear;
            final matchStatus =
                _filterStatus == null || item.status == _filterStatus;
            return matchName && matchSem && matchYear && matchStatus;
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
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () => _openFilterSheet(academicYears),
                    ),
                  ],
                ),
              ),
              if (_selectedIds.isNotEmpty)
                Container(
                  color: Colors.blue.shade50,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text('Đã chọn ${_selectedIds.length} lớp'),
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
                  child: filteredClasses.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 160),
                            Center(
                              child: Text(
                                'Hiện không có lớp nào phù hợp!',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: filteredClasses.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = filteredClasses[index];
                            final subjectName =
                                data.subjectsById[item.subjectId]?.name;
                            final assignment =
                                data.assignmentsByClassId[item.id];
                            final teacher = assignment == null
                                ? null
                                : data.teachersById[assignment.teacherId];
                            final schedule = data.schedulesByClassId[item.id];

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
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddClassSheet,
        label: const Text('Thêm lớp'),
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
    final isSelected = _selectedIds.contains(item.id);
    final isActive = (item as dynamic).isActive ?? true;

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
                        _selectedIds.add(item.id);
                      } else {
                        _selectedIds.remove(item.id);
                      }
                    });
                  },
                ),
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
                if (!isActive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                _buildStatusBadge(item.status),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Sửa lớp',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () =>
                      _openEditClassSheet(item, subjectName, schedule),
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
                'Lịch: ${schedule.weekday.label} • ${schedule.session.label} • ${schedule.room.name}',
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
                        ? '${teacher.firstName} ${teacher.lastName}'
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