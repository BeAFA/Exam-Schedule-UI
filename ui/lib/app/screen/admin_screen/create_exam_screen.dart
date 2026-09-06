import 'package:flutter/material.dart';
import '../../../features/auth/api.dart';
import '../../../core/models/subject_class_model.dart';
import '../../../core/models/room_model.dart';
import '../../../core/models/enum_model.dart';
import '../../../core/models/exam_model.dart';
import '../../../core/models/schedule_model.dart';

class CreateExamSheet extends StatefulWidget {
  final Exam? existing;
  final SubjectClass? existingClass;
  final Room? existingRoom;

  const CreateExamSheet({
    super.key,
    this.existing,
    this.existingClass,
    this.existingRoom,
  });

  @override
  State<CreateExamSheet> createState() => _CreateExamSheetState();
}

class _CreateExamSheetState extends State<CreateExamSheet> {
  final _formKey = GlobalKey<FormState>();
  bool isChecked = false;

  final TextEditingController _classSearchController = TextEditingController();
  final FocusNode _classSearchFocus = FocusNode();
  List<SubjectClass> _allClasses = [];
  List<SubjectClass> _filteredClasses = [];
  List<SubjectClass> _nonScheduledClasses = [];
  SubjectClass? _selectedClass;

  final TextEditingController _roomSearchController = TextEditingController();
  final FocusNode _roomSearchFocus = FocusNode();
  List<Room> _filteredRooms = [];
  Room? _selectedRoom;

  List<Schedule> _allSchedules = [];

  late TypeOfExam _selectedType;
  late TimeFrame _selectedTimeFrame;
  late TextEditingController _durationController;
  late ExamStatus _selectedStatus;

  int _dateSelectionOption = 1;
  DateTime? _selectedCustomDate;
  DateTime? _calculatedNextDate;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    
    _selectedType = widget.existing?.type ?? TypeOfExam.finalExam;
    _selectedTimeFrame = widget.existing?.timeFrame ?? TimeFrame.values.first;
    _durationController = TextEditingController(
      text: widget.existing?.duration.toString() ?? '90',
    );
    _selectedStatus = widget.existing?.status ?? ExamStatus.scheduled;
    
    if (_isEdit) {
      _selectedClass = widget.existingClass;
      if (_selectedClass != null) {
        _classSearchController.text = _selectedClass!.subjectClassName;
      }
      
      _selectedRoom = widget.existingRoom;
      if (_selectedRoom != null) {
        _roomSearchController.text = _selectedRoom!.name;
      }
      
      _selectedCustomDate = widget.existing?.examDate;
      _dateSelectionOption = 2;
    }

    _loadInitialData();

    _classSearchController.addListener(() {
      setState(() {
        _filterClasses();
      });
    });

    _roomSearchController.addListener(() {
      _filterClasses();
    });
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        ApiService.getSubjectClasses(),
        ApiService.getRooms(),
        ApiService.getExams(),
        ApiService.getSchedules(),
      ]);

      final classes = results[0] as List<SubjectClass>;
      final rooms = results[1] as List<Room>;
      final exams = results[2] as List<Exam>;
      final schedules = results[3] as List<Schedule>;

      final scheduledClassIds = exams.map((e) => e.subjectClassId).toSet();

      final nonScheduledClasses = classes
          .where((c) => !scheduledClassIds.contains(c.id))
          .toList();

      setState(() {
        _allClasses = classes;
        _filteredClasses = classes;
        _nonScheduledClasses = nonScheduledClasses;

        _filteredRooms = rooms;
        _allSchedules = schedules;
        
        if (!_isEdit && _selectedClass != null) {
            _calculateOption1Date();
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'Không tải được dữ liệu ban đầu.');
    }
  }

  void _filterClasses() {
    final query = _classSearchController.text.toLowerCase();

    _filteredClasses = (isChecked ? _nonScheduledClasses : _allClasses)
        .where((c) => c.subjectClassName.toLowerCase().contains(query))
        .toList();
  }

  int _getDartWeekday(Weekday weekday) {
    switch (weekday) {
      case Weekday.mon:
        return DateTime.monday;
      case Weekday.tue:
        return DateTime.tuesday;
      case Weekday.wed:
        return DateTime.wednesday;
      case Weekday.thu:
        return DateTime.thursday;
      case Weekday.fri:
        return DateTime.friday;
      case Weekday.sat:
        return DateTime.saturday;
      case Weekday.sun:
        return DateTime.sunday;
    }
  }

  void _calculateOption1Date() {
    if (_selectedClass == null ||
        _selectedClass!.startDate == null ||
        _selectedClass!.numberOfSessions == null) {
      _calculatedNextDate = null;
      return;
    }

    try {
      final schedule = _allSchedules.firstWhere(
        (s) => s.subjectClassId == _selectedClass!.id,
      );

      int targetWeekday = _getDartWeekday(schedule.weekday);
      DateTime current = _selectedClass!.startDate!;

      while (current.weekday != targetWeekday) {
        current = current.add(const Duration(days: 1));
      }

      _calculatedNextDate = current.add(
        Duration(days: _selectedClass!.numberOfSessions! * 7),
      );

      if (schedule.session.value == 'MORNING') {
        _selectedTimeFrame = TimeFrame.values.firstWhere(
          (tf) => tf.value.contains('07'),
          orElse: () => TimeFrame.values.first,
        );
      } else {
        _selectedTimeFrame = TimeFrame.values.firstWhere(
          (tf) => tf.value.contains('13'),
          orElse: () => TimeFrame.values.first,
        );
      }
    } catch (e) {
      _calculatedNextDate = null;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedCustomDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
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
    if (picked != null) {
      setState(() {
        _selectedCustomDate = picked;
        _dateSelectionOption = 2;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    if (!_isEdit && _selectedClass == null) {
      setState(() => _errorMessage = 'Vui lòng chọn lớp học phần');
      return;
    }
    if (_selectedRoom == null) {
      setState(() => _errorMessage = 'Vui lòng chọn phòng thi');
      return;
    }

    final examDate = _dateSelectionOption == 1
        ? _calculatedNextDate
        : _selectedCustomDate;

    if (examDate == null) {
      setState(
        () => _errorMessage = _dateSelectionOption == 1
            ? 'Không thể tính toán ngày tự động. Vui lòng dùng ngày tùy chỉnh.'
            : 'Vui lòng chọn ngày dự kiến thi',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (_isEdit) {
        await ApiService.updateExam(
          examId: widget.existing!.id,
          roomId: _selectedRoom!.id,
          examDate:
              "${examDate.year}-${examDate.month.toString().padLeft(2, '0')}-${examDate.day.toString().padLeft(2, '0')}",
          type: _selectedType,
          timeFrame: _selectedTimeFrame,
          duration: int.parse(_durationController.text),
          status: _selectedStatus,
        );
      } else {
        await ApiService.createExam(
          subjectClassId: _selectedClass!.id,
          roomId: _selectedRoom!.id,
          examDate:
              "${examDate.year}-${examDate.month.toString().padLeft(2, '0')}-${examDate.day.toString().padLeft(2, '0')}",
          type: _selectedType,
          timeFrame: _selectedTimeFrame,
          duration: int.parse(_durationController.text),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _errorMessage = e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
                  _isEdit ? 'Sửa lịch thi' : 'Tạo lịch thi',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),

                if (_isEdit) ...[
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Lớp học phần',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(widget.existingClass?.subjectClassName ?? 'Không rõ'),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  Column(
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            checkColor: Colors.white,
                            fillColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return const Color(0xFF6E8CF0);
                              }
                              return Colors.transparent;
                            }),
                            value: isChecked,
                            onChanged: (bool? value) {
                              setState(() {
                                isChecked = value ?? false;
                                _filterClasses();
                              });
                            },
                          ),
                          const Text(
                            'Lọc những lớp học phần chưa có lịch thi',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      _buildSearchDropdown(
                        label: 'Lớp học phần',
                        controller: _classSearchController,
                        focusNode: _classSearchFocus,
                        selectedItem: _selectedClass,
                        items: _filteredClasses,
                        displayString: (c) => c.subjectClassName,
                        onSelect: (c) {
                          setState(() {
                            _selectedClass = c;
                            _classSearchController.text = c.subjectClassName;
                            _calculateOption1Date();
                          });
                        },
                        onClear: () => setState(() {
                          _selectedClass = null;
                          _calculatedNextDate = null;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE3E1F5)),
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFFF8F9FE),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chọn ngày thi',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      RadioGroup<int>(
                        groupValue: _dateSelectionOption,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _dateSelectionOption = val);
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _dateSelectionOption = 1),
                              child: Row(
                                children: [
                                  Radio<int>(
                                    value: 1,
                                    activeColor: const Color(0xFF6E8CF0),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Sau khi kết thúc môn học',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        Text(
                                          _calculatedNextDate != null &&
                                                  _selectedClass != null
                                              ? 'Dự kiến: ${_calculatedNextDate!.day}/${_calculatedNextDate!.month}/${_calculatedNextDate!.year}'
                                              : 'Tự động tính ngày & giờ thi theo lịch học',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _calculatedNextDate != null
                                                ? const Color(0xFF6E8CF0)
                                                : Colors.grey,
                                            fontWeight:
                                                _calculatedNextDate != null
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _dateSelectionOption = 2),
                              child: Row(
                                children: [
                                  Radio<int>(
                                    value: 2,
                                    activeColor: const Color(0xFF6E8CF0),
                                  ),
                                  const Text(
                                    'Ngày tùy chỉnh',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(
                          Icons.calendar_month,
                          color: Color(0xFF6E8CF0),
                        ),
                        label: Text(
                          _selectedCustomDate == null
                              ? 'Nhấn để chọn ngày thi'
                              : '${_selectedCustomDate!.day}/${_selectedCustomDate!.month}/${_selectedCustomDate!.year}',
                          style: const TextStyle(color: Color(0xFF6E8CF0)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF6E8CF0)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                _buildSearchDropdown(
                  label: 'Phòng thi',
                  controller: _roomSearchController,
                  focusNode: _roomSearchFocus,
                  selectedItem: _selectedRoom,
                  items: _filteredRooms,
                  displayString: (r) => '${r.name} (Sức chứa: ${r.capacity})',
                  onSelect: (r) {
                    setState(() {
                      _selectedRoom = r;
                      _roomSearchController.text = r.name;
                    });
                  },
                  onClear: () => setState(() => _selectedRoom = null),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<TypeOfExam>(
                        decoration: const InputDecoration(
                          labelText: 'Loại hình',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _selectedType,
                        items: const [
                          DropdownMenuItem(
                            value: TypeOfExam.midterm,
                            child: Text('Giữa kỳ'),
                          ),
                          DropdownMenuItem(
                            value: TypeOfExam.finalExam,
                            child: Text('Cuối kỳ'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _selectedType = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Thời gian (Phút)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<TimeFrame>(
                  decoration: const InputDecoration(
                    labelText: 'Khung giờ bắt đầu',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _selectedTimeFrame,
                  items: TimeFrame.values
                      .map(
                        (tf) =>
                            DropdownMenuItem(value: tf, child: Text(tf.label)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedTimeFrame = v!),
                ),

                if (_isEdit) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ExamStatus>(
                    decoration: const InputDecoration(
                      labelText: 'Trạng thái',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedStatus,
                    items: ExamStatus.values
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.label),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedStatus = v!),
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
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Text(_isEdit ? 'Lưu thay đổi' : 'Xếp lịch thi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchDropdown<T>({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required T? selectedItem,
    required List<T> items,
    required String Function(T) displayString,
    required Function(T) onSelect,
    required VoidCallback onClear,
  }) {
    return Column(
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: selectedItem != null && !_isEdit
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      controller.clear();
                      onClear();
                      focusNode.requestFocus();
                    },
                  )
                : const Icon(Icons.search),
          ),
          readOnly: _isEdit && label == 'Lớp học phần',
          onChanged: (val) {
            if (selectedItem != null) onClear();
          },
        ),
        if (focusNode.hasFocus && !(_isEdit && label == 'Lớp học phần')) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Không tìm thấy dữ liệu',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        dense: true,
                        title: Text(displayString(item)),
                        onTap: () {
                          onSelect(item);
                          focusNode.unfocus();
                        },
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }
}