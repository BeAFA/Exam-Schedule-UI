import 'package:flutter/material.dart';

import '../../../features/auth/api.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/models/subject_class_model.dart';
import '../../../core/models/teaching_assignment_model.dart';

class AssignTeacherScreen extends StatefulWidget {
  final SubjectClass subjectClass;
  final List<Profile> teachers;
  final TeachingAssignment? existingAssignment;
  final Profile? currentTeacher;

  const AssignTeacherScreen({
    super.key,
    required this.subjectClass,
    required this.teachers,
    this.existingAssignment,
    this.currentTeacher,
  });

  @override
  State<AssignTeacherScreen> createState() => _AssignTeacherScreenState();
}

class _AssignTeacherScreenState extends State<AssignTeacherScreen> {
  Profile? _selectedTeacher;
  bool _isSubmitting = false;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<Profile> _filteredTeachers = [];

  bool get _isEdit => widget.existingAssignment != null;

  @override
  void initState() {
    super.initState();
    _selectedTeacher = widget.currentTeacher;
    _filteredTeachers = widget.teachers;

    if (_selectedTeacher != null) {
      _searchController.text =
          '${_selectedTeacher!.firstName} ${_selectedTeacher!.lastName} (${_selectedTeacher!.userCode})';
    }

    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        if (query.isEmpty) {
          _filteredTeachers = widget.teachers;
        } else {
          _filteredTeachers = widget.teachers
              .where((t) =>
                  t.firstName.toLowerCase().contains(query) ||
                  t.lastName.toLowerCase().contains(query) ||
                  t.userCode.toLowerCase().contains(query))
              .toList();
        }
      });
    });

    _searchFocus.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    if (_selectedTeacher == null) {
      setState(() => _errorMessage = 'Vui lòng chọn giảng viên');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (_isEdit) {
        await ApiService.updateTeachingAssignment(
          teachingAssignmentId: widget.existingAssignment!.id,
          teacherId: _selectedTeacher!.id,
          subjectClassId: widget.subjectClass.id,
        );
      } else {
        await ApiService.createTeachingAssignment(
          teacherId: _selectedTeacher!.id,
          subjectClassId: widget.subjectClass.id,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true); // báo cho màn hình cha reload
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleRemove() async {
    if (_isSubmitting || widget.existingAssignment == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ApiService.changeTeachingAssignmentActive([widget.existingAssignment!.id]);

      if (!mounted) return;
      Navigator.of(context).pop(true); // báo cho màn hình cha reload
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
              Text(
                _isEdit ? 'Đổi giảng viên giảng dạy' : 'Phân công giảng viên',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subjectClass.subjectClassName,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),

              if (widget.teachers.isEmpty)
                const Text(
                  'Chưa có giảng viên nào trong hệ thống.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                )
              else ...[
                TextFormField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  decoration: InputDecoration(
                    labelText: 'Giảng viên',
                    hintText: 'Gõ để tìm giảng viên...',
                    border: const OutlineInputBorder(),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _selectedTeacher = null);
                              _searchFocus.requestFocus();
                            },
                          )
                        : const Icon(Icons.search),
                  ),
                  onChanged: (_) {
                    if (_selectedTeacher != null) {
                      setState(() => _selectedTeacher = null);
                    }
                  },
                ),

                if (_searchFocus.hasFocus) ...[
                  const SizedBox(height: 4),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: _filteredTeachers.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Không tìm thấy giảng viên.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _filteredTeachers.length,
                            itemBuilder: (context, index) {
                              final t = _filteredTeachers[index];
                              return ListTile(
                                dense: true,
                                title: Text('${t.firstName} ${t.lastName} (${t.userCode})'),
                                onTap: () {
                                  setState(() {
                                    _selectedTeacher = t;
                                    _searchController.text =
                                        '${t.firstName} ${t.lastName} (${t.userCode})';
                                    _searchFocus.unfocus();
                                    _errorMessage = null;
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6E8CF0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEdit ? 'Lưu thay đổi' : 'Phân công'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}