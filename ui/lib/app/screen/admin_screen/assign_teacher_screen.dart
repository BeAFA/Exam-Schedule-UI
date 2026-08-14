import 'package:flutter/material.dart';

import '../../../features/auth/api.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/models/subject_class_model.dart';
import '../../../core/models/teaching_assignment_model.dart';

/// Bottom sheet Thêm/Sửa giảng viên giảng dạy cho 1 lớp học phần.
///
/// - [existingAssignment] == null -> gọi API tạo phân công mới
///   (`POST /teaching_assignment/create`).
/// - [existingAssignment] != null -> gọi API cập nhật phân công đã có
///   (`POST /teaching_assignment/{id}/update`).
///
/// Danh sách [teachers] được truyền từ màn hình cha (đã tải sẵn 1 lần)
/// để tránh gọi lại `GET /teacher` mỗi lần mở sheet.
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

  bool get _isEdit => widget.existingAssignment != null;

  @override
  void initState() {
    super.initState();
    _selectedTeacher = widget.currentTeacher;
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
      final TeachingAssignment result;
      if (_isEdit) {
        result = await ApiService.updateTeachingAssignment(
          teachingAssignmentId: widget.existingAssignment!.id,
          teacherId: _selectedTeacher!.id,
          subjectClassId: widget.subjectClass.id,
        );
      } else {
        result = await ApiService.createTeachingAssignment(
          teacherId: _selectedTeacher!.id,
          subjectClassId: widget.subjectClass.id,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(result); // báo cho màn hình cha reload
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
    final teachers = widget.teachers;

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
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subjectClass.subjectClassName,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),

              if (teachers.isEmpty)
                const Text(
                  'Chưa có giảng viên nào trong hệ thống.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                )
              else
                Autocomplete<Profile>(
                  displayStringForOption: (p) =>
                      '${p.fullName} (${p.userCode})',
                  initialValue: TextEditingValue(
                    text: _selectedTeacher == null
                        ? ''
                        : '${_selectedTeacher!.fullName} (${_selectedTeacher!.userCode})',
                  ),
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) return teachers;
                    final query = textEditingValue.text.toLowerCase();
                    return teachers.where(
                      (t) =>
                          t.fullName.toLowerCase().contains(query) ||
                          t.userCode.toLowerCase().contains(query),
                    );
                  },
                  onSelected: (t) => setState(() {
                    _selectedTeacher = t;
                    _errorMessage = null;
                  }),
                  fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Giảng viên',
                        hintText: 'Gõ để tìm giảng viên...',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) {
                        if (_selectedTeacher != null) {
                          setState(() => _selectedTeacher = null);
                        }
                      },
                    );
                  },
                  optionsViewBuilder: (context, onSelectedOption, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 240),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                dense: true,
                                title:
                                    Text('${option.fullName} (${option.userCode})'),
                                onTap: () => onSelectedOption(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),

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
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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