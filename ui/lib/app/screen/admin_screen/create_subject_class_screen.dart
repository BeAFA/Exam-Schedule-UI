import 'package:flutter/material.dart';

import '../../../features/auth/api.dart';
import '../../../core/models/subject_model.dart';
import '../../../core/models/room_model.dart';
import '../../../core/models/enum_model.dart';
import '../../../core/models/subject_class_model.dart';
import '../../../core/models/schedule_model.dart';

class SubjectClassFormSheet extends StatefulWidget {
  final SubjectClass? existing;
  final String? existingSubjectName;
  final Schedule? existingSchedule;

  const SubjectClassFormSheet({
    super.key,
    this.existing,
    this.existingSubjectName,
    this.existingSchedule,
  });

  @override
  State<SubjectClassFormSheet> createState() => _SubjectClassFormSheetState();
}

class _SubjectClassFormSheetState extends State<SubjectClassFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _academicYearController;
  late final TextEditingController _maxStudentsController;
  late final TextEditingController _startDateController;
  late final TextEditingController _numberOfSessionsController;
  DateTime? _selectedStartDate;

  late Future<List<Subject>> _subjectsFuture;
  late Future<List<Room>> _roomsFuture;

  Subject? _selectedSubject;
  Room? _selectedRoom;
  late Semester _selectedSemester;
  Weekday _selectedWeekday = Weekday.mon;
  SessionPeriod _selectedSession = SessionPeriod.morning;
  late ClassStatus _selectedStatus;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    final schedule = widget.existingSchedule;

    _nameController = TextEditingController(
      text: existing?.subjectClassName ?? '',
    );
    _academicYearController = TextEditingController(
      text: existing?.academicYear ?? '',
    );
    _maxStudentsController = TextEditingController(
      text: existing?.maxStudents != null
          ? existing!.maxStudents.toString()
          : '',
    );

    _selectedSemester = existing?.semester ?? Semester.semester1;
    _selectedStatus = existing?.status ?? ClassStatus.open;
    if (schedule != null) {
      _selectedRoom = schedule.room;
      _selectedWeekday = schedule.weekday;
      _selectedSession = schedule.session;
    }

    _subjectsFuture = ApiService.getSubjects();
    _roomsFuture = ApiService.getRooms();

    _selectedStartDate = widget.existing?.startDate;
    _startDateController = TextEditingController(
      text: _selectedStartDate != null
          ? "${_selectedStartDate!.year}-${_selectedStartDate!.month.toString().padLeft(2, '0')}-${_selectedStartDate!.day.toString().padLeft(2, '0')}"
          : '',
    );

    _numberOfSessionsController = TextEditingController(
      text: widget.existing?.numberOfSessions?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _academicYearController.dispose();
    _maxStudentsController.dispose();
    _startDateController.dispose();
    _numberOfSessionsController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedStartDate = picked;
        _startDateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    if (!_isEdit && _selectedSubject == null) {
      setState(() => _errorMessage = 'Vui lòng chọn môn học');
      return;
    }
    if (_selectedRoom == null) {
      setState(() => _errorMessage = 'Vui lòng chọn phòng học');
      return;
    }
    if (_selectedStartDate == null) {
      setState(() => _errorMessage = 'Vui lòng chọn ngày bắt đầu');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (_isEdit) {
        await ApiService.updateSubjectClass(
          subjectClassId: widget.existing!.id,
          subjectClassName: _nameController.text.trim(),
          semester: _selectedSemester,
          academicYear: _academicYearController.text.trim(),
          maxStudents: int.parse(_maxStudentsController.text.trim()),
          startDate: _startDateController.text.trim(),
          numberOfSessions: int.parse(_numberOfSessionsController.text.trim()),
          roomId: _selectedRoom!.id,
          weekday: _selectedWeekday,
          session: _selectedSession,
          status: _selectedStatus,
        );
      } else {
        await ApiService.createSubjectClass(
          subjectClassName: _nameController.text.trim(),
          subjectId: _selectedSubject!.id,
          semester: _selectedSemester,
          academicYear: _academicYearController.text.trim(),
          maxStudents: int.parse(_maxStudentsController.text.trim()),
          startDate: _startDateController.text.trim(),
          numberOfSessions: int.parse(_numberOfSessionsController.text.trim()),
          roomId: _selectedRoom!.id,
          weekday: _selectedWeekday,
          session: _selectedSession,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
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
    return AnimatedPadding(
      duration: const Duration(milliseconds: 50),
      curve: Curves.linear,
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
                Text(
                  _isEdit ? 'Sửa lớp học phần' : 'Thêm lớp học phần',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
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

                if (_isEdit) ...[
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Môn học',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(widget.existingSubjectName ?? 'Không rõ'),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
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
                    onRetry: () => setState(
                      () => _subjectsFuture = ApiService.getSubjects(),
                    ),
                    emptyMessage: 'Chưa có môn học nào trong hệ thống.',
                  ),
                  const SizedBox(height: 12),
                ],

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
                if (_isEdit) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Hệ thống chưa hỗ trợ tải sẵn lịch học hiện tại của lớp, '
                    'vui lòng chọn lại phòng/thứ/buổi.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
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
                            .map(
                              (w) => DropdownMenuItem(
                                value: w,
                                child: Text(w.label),
                              ),
                            )
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
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.label),
                              ),
                            )
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

                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _startDateController,
                        readOnly: true,
                        onTap: _pickStartDate,
                        decoration: const InputDecoration(
                          labelText: 'Ngày bắt đầu',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Bắt buộc';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _numberOfSessionsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Số buổi',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Bắt buộc';
                          }
                          if (int.tryParse(value.trim()) == null) {
                            return 'Phải là số';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
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

                if (_isEdit) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ClassStatus>(
                    initialValue: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Trạng thái',
                      border: OutlineInputBorder(),
                    ),
                    items: ClassStatus.values
                        .map(
                          (s) =>
                              DropdownMenuItem(value: s, child: Text(s.label)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedStatus = value);
                      }
                    },
                  ),
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
                      : Text(_isEdit ? 'Lưu thay đổi' : 'Tạo lớp'),
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
          initialValue: selected != null
              ? TextEditingValue(text: displayString(selected))
              : null,
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
