import 'package:flutter/material.dart';

import '../../../features/auth/api.dart';
import '../../../core/models/subject_class_model.dart';
import '../../../core/models/subject_model.dart';
import '../../../core/models/room_model.dart';
import '../../../core/models/schedule_model.dart';

class AddSubjectClassSheet extends StatefulWidget {
  const AddSubjectClassSheet({super.key});

  @override
  State<AddSubjectClassSheet> createState() => _AddSubjectClassSheetState();
}

class _AddSubjectClassSheetState extends State<AddSubjectClassSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _academicYearController = TextEditingController();
  final _maxStudentsController = TextEditingController();
 
  late Future<List<Subject>> _subjectsFuture;
  late Future<List<Room>> _roomsFuture;
 
  Subject? _selectedSubject;
  Room? _selectedRoom;
  Semester _selectedSemester = Semester.semester1;
  Weekday _selectedWeekday = Weekday.mon;
  SessionPeriod _selectedSession = SessionPeriod.morning;
 
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _subjectsFuture = ApiService.getSubjects();
    _roomsFuture = ApiService.getRooms();
  }
 
  @override
  void dispose() {
    _nameController.dispose();
    _academicYearController.dispose();
    _maxStudentsController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) return;
 
    if (_selectedSubject == null) {
      setState(() => _errorMessage = 'Vui lòng chọn môn học');
      return;
    }
 
    if (_selectedRoom == null) {
      setState(() => _errorMessage = 'Vui lòng chọn phòng học');
      return;
    }
 
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
 
    try {
      await ApiService.createSubjectClass(
        subjectClassName: _nameController.text.trim(),
        subjectId: _selectedSubject!.id,
        semester: _selectedSemester,
        academicYear: _academicYearController.text.trim(),
        maxStudents: int.parse(_maxStudentsController.text.trim()),
        roomId: _selectedRoom!.id,
        weekday: _selectedWeekday,
        session: _selectedSession,
      );
 
      if (!mounted) return;
      Navigator.of(context).pop(true); // báo cho màn hình cha reload danh sách
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
      // Đẩy sheet lên trên bàn phím ảo.
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
          child: Form(
            key: _formKey,
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
                  'Thêm lớp học phần',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
 
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên lớp học phần',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Vui lòng nhập tên lớp'
                      : null,
                ),
                const SizedBox(height: 12),
 
                // Dropdown tìm kiếm môn học (chỉ chọn trong danh sách có sẵn,
                // không cho tạo môn học mới).
                _buildSearchField<Subject>(
                  future: _subjectsFuture,
                  label: 'Môn học',
                  hint: 'Gõ để tìm môn học...',
                  displayString: (s) => s.name,
                  selected: _selectedSubject,
                  onSelected: (s) => setState(() {
                    _selectedSubject = s;
                    _errorMessage = null;
                  }),
                  onCleared: () => setState(() => _selectedSubject = null),
                  onRetry: () =>
                      setState(() => _subjectsFuture = ApiService.getSubjects()),
                  emptyMessage: 'Chưa có môn học nào trong hệ thống.',
                ),
                const SizedBox(height: 12),
 
                // Dropdown tìm kiếm phòng học, cùng cơ chế với môn học.
                _buildSearchField<Room>(
                  future: _roomsFuture,
                  label: 'Phòng học',
                  hint: 'Gõ để tìm phòng...',
                  displayString: (r) => '${r.name} (sức chứa ${r.capacity})',
                  selected: _selectedRoom,
                  onSelected: (r) => setState(() {
                    _selectedRoom = r;
                    _errorMessage = null;
                  }),
                  onCleared: () => setState(() => _selectedRoom = null),
                  onRetry: () =>
                      setState(() => _roomsFuture = ApiService.getRooms()),
                  emptyMessage: 'Chưa có phòng học nào trong hệ thống.',
                ),
                const SizedBox(height: 12),
 
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Weekday>(
                        initialValue: _selectedWeekday,
                        decoration: const InputDecoration(
                          labelText: 'Thứ',
                          border: OutlineInputBorder(),
                        ),
                        items: Weekday.values
                            .map((w) => DropdownMenuItem(
                                  value: w,
                                  child: Text(w.label),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedWeekday = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<SessionPeriod>(
                        initialValue: _selectedSession,
                        decoration: const InputDecoration(
                          labelText: 'Buổi',
                          border: OutlineInputBorder(),
                        ),
                        items: SessionPeriod.values
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.label),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedSession = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
 
                DropdownButtonFormField<Semester>(
                  initialValue: _selectedSemester,
                  decoration: const InputDecoration(
                    labelText: 'Học kỳ',
                    border: OutlineInputBorder(),
                  ),
                  items: Semester.values
                      .map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedSemester = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
 
                TextFormField(
                  controller: _academicYearController,
                  decoration: const InputDecoration(
                    labelText: 'Năm học (VD: 2025-2026)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập năm học';
                    }
                    final regex = RegExp(r'^\d{4}-\d{4}$');
                    if (!regex.hasMatch(value.trim())) {
                      return 'Định dạng: YYYY-YYYY, VD 2025-2026';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
 
                TextFormField(
                  controller: _maxStudentsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sĩ số tối đa',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập sĩ số tối đa';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Sĩ số phải là số';
                    }
                    return null;
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
                      : const Text('Tạo lớp'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
 
  Widget _buildSearchField<T extends Object>({
    required Future<List<T>> future,
    required String label,
    required String hint,
    required String Function(T) displayString,
    required T? selected,
    required void Function(T) onSelected,
    required VoidCallback onCleared,
    required VoidCallback onRetry,
    required String emptyMessage,
  }) {
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 56,
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
 
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Không tải được "$label": ${snapshot.error}',
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
              TextButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          );
        }
 
        final items = snapshot.data ?? [];
 
        if (items.isEmpty) {
          return Text(
            emptyMessage,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          );
        }
 
        return Autocomplete<T>(
          displayStringForOption: displayString,
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) return items;
            final query = textEditingValue.text.toLowerCase();
            return items.where(
              (item) => displayString(item).toLowerCase().contains(query),
            );
          },
          onSelected: onSelected,
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.search),
                errorText: (selected == null && controller.text.isNotEmpty)
                    ? 'Vui lòng chọn từ danh sách gợi ý'
                    : null,
              ),
              onChanged: (_) {
                if (selected != null) onCleared();
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
                        title: Text(displayString(option)),
                        onTap: () => onSelectedOption(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
