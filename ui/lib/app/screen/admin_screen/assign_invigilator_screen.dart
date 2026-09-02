import 'package:flutter/material.dart';
import '../../../features/auth/api.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/models/exam_model.dart';
import '../../../core/models/exam_invigilator_model.dart';

class AssignInvigilatorSheet extends StatefulWidget {
  final Exam exam;
  final List<Profile> teachers;
  final List<ExamInvigilator> currentInvigilators;

  const AssignInvigilatorSheet({
    super.key,
    required this.exam,
    required this.teachers,
    required this.currentInvigilators,
  });

  @override
  State<AssignInvigilatorSheet> createState() => _AssignInvigilatorSheetState();
}

class _AssignInvigilatorSheetState extends State<AssignInvigilatorSheet> {
  late List<int> _assignedTeacherIds;
  Profile? _selectedTeacher;
  bool _isSubmitting = false;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<Profile> _filteredTeachers = [];

  @override
  void initState() {
    super.initState();
    _assignedTeacherIds = widget.currentInvigilators
        .map((i) => i.teacherId)
        .toList();
    _refreshFilteredTeachers();

    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        if (query.isEmpty) {
          _refreshFilteredTeachers();
        } else {
          _filteredTeachers = _availableTeachers
              .where(
                (t) =>
                    t.firstName.toLowerCase().contains(query) ||
                    t.lastName.toLowerCase().contains(query) ||
                    t.userCode.toLowerCase().contains(query),
              )
              .toList();
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<Profile> get _availableTeachers {
    return widget.teachers
        .where((t) => !_assignedTeacherIds.contains(t.id))
        .toList();
  }

  void _refreshFilteredTeachers() {
    _filteredTeachers = _availableTeachers;
  }

  Future<void> _syncInvigilators(List<int> newTeacherIds) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ApiService.setExamInvigilators(
        examId: widget.exam.id,
        teacherIds: newTeacherIds,
      );
      if (!mounted) return;
      setState(() {
        _assignedTeacherIds = newTeacherIds;
        _selectedTeacher = null;
        _searchController.clear();
        _refreshFilteredTeachers();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _handleAdd() {
    if (_selectedTeacher == null) {
      setState(() => _errorMessage = 'Vui lòng chọn cán bộ coi thi');
      return;
    }
    final nextList = [..._assignedTeacherIds, _selectedTeacher!.id];
    _syncInvigilators(nextList);
  }

  void _handleRemove(int teacherId) {
    final nextList = _assignedTeacherIds
        .where((id) => id != teacherId)
        .toList();
    _syncInvigilators(nextList);
  }

  String _teacherLabel(int teacherId) {
    final t = widget.teachers.where((p) => p.id == teacherId).firstOrNull;
    if (t == null) return 'Giáo viên #$teacherId';
    return '${t.firstName} ${t.lastName} (${t.userCode})';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Cán bộ coi thi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              if (_assignedTeacherIds.isEmpty)
                const Text(
                  'Chưa có cán bộ coi thi nào được phân công.',
                  style: TextStyle(color: Colors.grey),
                )
              else
                ..._assignedTeacherIds.map(
                  (tId) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.person_outline),
                      title: Text(_teacherLabel(tId)),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: _isSubmitting
                            ? null
                            : () => _handleRemove(tId),
                      ),
                    ),
                  ),
                ),
              const Divider(height: 24),
              TextFormField(
                controller: _searchController,
                focusNode: _searchFocus,
                decoration: InputDecoration(
                  labelText: 'Tìm giáo viên',
                  border: const OutlineInputBorder(),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _selectedTeacher = null);
                          },
                        )
                      : const Icon(Icons.search),
                ),
              ),
              if (_searchFocus.hasFocus && _filteredTeachers.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredTeachers.length,
                    itemBuilder: (context, index) {
                      final t = _filteredTeachers[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          '${t.firstName} ${t.lastName} (${t.userCode})',
                        ),
                        onTap: () {
                          setState(() {
                            _selectedTeacher = t;
                            _searchController.text =
                                '${t.firstName} ${t.lastName} (${t.userCode})';
                            _searchFocus.unfocus();
                          });
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _handleAdd,
                icon: const Icon(Icons.add),
                label: const Text('Thêm CBCT'),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Xong'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
