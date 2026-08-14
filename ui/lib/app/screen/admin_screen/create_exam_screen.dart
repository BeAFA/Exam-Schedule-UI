import 'package:flutter/material.dart';

import '../../../features/auth/api.dart';
import '../../../core/models/subject_class_model.dart';
import '../../../core/models/room_model.dart';
import '../../../core/models/enum_model.dart';
import '../../../core/models/exam_model.dart';
import '../../../core/models/schedule_model.dart';

class CreateExamSheet extends StatefulWidget {
  const CreateExamSheet({super.key});

  @override
  State<CreateExamSheet> createState() => _CreateExamSheetState();
}

class _CreateExamSheetState extends State<CreateExamSheet> {
  final _formKey = GlobalKey<FormState>();

  // Custom Inline Autocomplete Controllers
  final TextEditingController _classSearchController = TextEditingController();
  final FocusNode _classSearchFocus = FocusNode();
  List<SubjectClass> _allClasses = [];
  List<SubjectClass> _filteredClasses = [];
  SubjectClass? _selectedClass;

  final TextEditingController _roomSearchController = TextEditingController();
  final FocusNode _roomSearchFocus = FocusNode();
  List<Room> _allRooms = [];
  List<Room> _filteredRooms = [];
  Room? _selectedRoom;
  
  // Lưu lịch trình để tính toán ngày thi tự động
  List<Schedule> _allSchedules = [];

  // Form Fields
  TypeOfExam _selectedType = TypeOfExam.finalExam;
  TimeFrame _selectedTimeFrame = TimeFrame.values.first; // Sẽ tự động gán sau
  final TextEditingController _durationController = TextEditingController(text: '90');

  // Date selection state
  int _dateSelectionOption = 1; // 1: Kế tiếp buổi cuối, 2: Tùy chọn
  DateTime? _selectedCustomDate;
  DateTime? _calculatedNextDate; // Lưu ngày tự động tính cho Option 1

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    _classSearchController.addListener(() {
      final query = _classSearchController.text.toLowerCase();
      setState(() {
        _filteredClasses = _allClasses
            .where((c) => c.subjectClassName.toLowerCase().contains(query))
            .toList();
      });
    });

    _roomSearchController.addListener(() {
      final query = _roomSearchController.text.toLowerCase();
      setState(() {
        _filteredRooms = _allRooms
            .where((r) => r.name.toLowerCase().contains(query))
            .toList();
      });
    });
  }

  Future<void> _loadInitialData() async {
    try {
      // Tải song song Lớp, Phòng, Lịch thi (để lọc) và Lịch học (để tính ngày)
      final results = await Future.wait([
        ApiService.getSubjectClass(),
        ApiService.getRooms(),
        ApiService.getExams(),
        ApiService.getSchedules(),
      ]);

      final classes = results[0] as List<SubjectClass>;
      final rooms = results[1] as List<Room>;
      final exams = results[2] as List<Exam>;
      final schedules = results[3] as List<Schedule>;

      // Lọc: Chỉ lấy những lớp CHƯA có lịch thi (id không nằm trong danh sách exams)
      final scheduledClassIds = exams.map((e) => e.subjectClassId).toSet();
      final availableClasses = classes.where((c) => !scheduledClassIds.contains(c.id)).toList();

      setState(() {
        _allClasses = availableClasses;
        _filteredClasses = availableClasses;
        _allRooms = rooms;
        _filteredRooms = rooms;
        _allSchedules = schedules;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Không tải được dữ liệu ban đầu.');
    }
  }

  // Hàm ánh xạ Enum Weekday sang int của Dart (Thứ 2 = 1, Chủ nhật = 7)
  int _getDartWeekday(Weekday weekday) {
    switch (weekday) {
      case Weekday.mon: return DateTime.monday;
      case Weekday.tue: return DateTime.tuesday;
      case Weekday.wed: return DateTime.wednesday;
      case Weekday.thu: return DateTime.thursday;
      case Weekday.fri: return DateTime.friday;
      case Weekday.sat: return DateTime.saturday;
      case Weekday.sun: return DateTime.sunday;
    }
  }

  // Tự động tính toán ngày thi và giờ thi cho Option 1
  void _calculateOption1Date() {
    if (_selectedClass == null || _selectedClass!.startDate == null || _selectedClass!.numberOfSessions == null) {
      _calculatedNextDate = null;
      return;
    }

    try {
      // Lấy lịch học của lớp này
      final schedule = _allSchedules.firstWhere((s) => s.subjectClassId == _selectedClass!.id);
      
      int targetWeekday = _getDartWeekday(schedule.weekday);
      DateTime current = _selectedClass!.startDate!;
      
      // Chạy tới ngày học ĐẦU TIÊN đúng với thứ trong tuần
      while (current.weekday != targetWeekday) {
        current = current.add(const Duration(days: 1));
      }

      // Buổi kế tiếp sau buổi cuối = Ngày học đầu + (Tổng số buổi * 7 ngày)
      _calculatedNextDate = current.add(Duration(days: _selectedClass!.numberOfSessions! * 7));

      // Tự động đặt Khung giờ thi theo Buổi học (Sáng -> 07:30, Chiều -> 13:00)
      if (schedule.session.value == 'MORNING') {
        _selectedTimeFrame = TimeFrame.values.firstWhere((tf) => tf.value.contains('07'), orElse: () => TimeFrame.values.first);
      } else {
        _selectedTimeFrame = TimeFrame.values.firstWhere((tf) => tf.value.contains('13'), orElse: () => TimeFrame.values.first);
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
        _dateSelectionOption = 2; // Tự động chuyển sang Option 2 nếu pick ngày
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    if (_selectedClass == null) {
      setState(() => _errorMessage = 'Vui lòng chọn lớp học phần');
      return;
    }
    if (_selectedRoom == null) {
      setState(() => _errorMessage = 'Vui lòng chọn phòng thi');
      return;
    }

    // Xác định ngày gửi đi phụ thuộc vào Radio button
    final examDate = _dateSelectionOption == 1 ? _calculatedNextDate : _selectedCustomDate;
    
    if (examDate == null) {
      setState(() => _errorMessage = _dateSelectionOption == 1 
          ? 'Không thể tính toán ngày tự động. Vui lòng dùng ngày tùy chỉnh.' 
          : 'Vui lòng chọn ngày dự kiến thi');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ApiService.createExam(
        subjectClassId: _selectedClass!.id,
        roomId: _selectedRoom!.id,
        examDate: "${examDate.year}-${examDate.month.toString().padLeft(2, '0')}-${examDate.day.toString().padLeft(2, '0')}",
        type: _selectedType,
        timeFrame: _selectedTimeFrame,
        duration: int.parse(_durationController.text),
      );

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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const Text('Tạo lịch thi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),

                // Lớp học phần
                _buildSearchDropdown(
                  label: 'Lớp học phần (Chỉ hiện lớp chưa có lịch thi)',
                  controller: _classSearchController,
                  focusNode: _classSearchFocus,
                  selectedItem: _selectedClass,
                  items: _filteredClasses,
                  displayString: (c) => c.subjectClassName,
                  onSelect: (c) {
                    setState(() {
                      _selectedClass = c;
                      _classSearchController.text = c.subjectClassName;
                      _calculateOption1Date(); // Tính ngày ngay khi chọn xong lớp
                    });
                  },
                  onClear: () => setState(() {
                    _selectedClass = null;
                    _calculatedNextDate = null;
                  }),
                ),
                const SizedBox(height: 12),

                // Hình thức chọn ngày
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
                      const Text('Chọn ngày thi', style: TextStyle(fontWeight: FontWeight.bold)),
                      RadioListTile<int>(
                        value: 1,
                        groupValue: _dateSelectionOption,
                        title: const Text('Sau khi kết thúc môn học', style: TextStyle(fontSize: 14)),
                        subtitle: Text(
                          _calculatedNextDate != null && _selectedClass != null
                              ? 'Dự kiến: ${_calculatedNextDate!.day}/${_calculatedNextDate!.month}/${_calculatedNextDate!.year}'
                              : 'Tự động tính ngày & giờ thi theo lịch học',
                          style: TextStyle(
                            fontSize: 12, 
                            color: _calculatedNextDate != null ? const Color(0xFF6E8CF0) : Colors.grey,
                            fontWeight: _calculatedNextDate != null ? FontWeight.w600 : FontWeight.normal
                          ),
                        ),
                        activeColor: const Color(0xFF6E8CF0),
                        onChanged: (val) => setState(() => _dateSelectionOption = val!),
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<int>(
                        value: 2,
                        groupValue: _dateSelectionOption,
                        title: const Text('Ngày tùy chỉnh', style: TextStyle(fontSize: 14)),
                        activeColor: const Color(0xFF6E8CF0),
                        onChanged: (val) => setState(() => _dateSelectionOption = val!),
                        contentPadding: EdgeInsets.zero,
                      ),
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_month, color: Color(0xFF6E8CF0)),
                        label: Text(
                          _selectedCustomDate == null
                              ? 'Nhấn để chọn ngày thi'
                              : '${_selectedCustomDate!.day}/${_selectedCustomDate!.month}/${_selectedCustomDate!.year}',
                          style: const TextStyle(color: Color(0xFF6E8CF0)),
                        ),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF6E8CF0))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Phòng thi
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
                        decoration: const InputDecoration(labelText: 'Loại hình', border: OutlineInputBorder()),
                        value: _selectedType,
                        items: const [
                          DropdownMenuItem(value: TypeOfExam.midterm, child: Text('Giữa kỳ')),
                          DropdownMenuItem(value: TypeOfExam.finalExam, child: Text('Cuối kỳ')),
                        ],
                        onChanged: (v) => setState(() => _selectedType = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Thời gian (Phút)', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Khung giờ
                DropdownButtonFormField<TimeFrame>(
                  decoration: const InputDecoration(labelText: 'Khung giờ bắt đầu', border: OutlineInputBorder()),
                  value: _selectedTimeFrame,
                  items: TimeFrame.values.map((tf) => DropdownMenuItem(value: tf, child: Text(tf.label))).toList(),
                  onChanged: (v) => setState(() => _selectedTimeFrame = v!),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ],

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6E8CF0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Xếp lịch thi'),
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
            suffixIcon: selectedItem != null
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
          onChanged: (val) {
            if (selectedItem != null) onClear();
          },
        ),
        if (focusNode.hasFocus) ...[
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
                    child: Text('Không tìm thấy dữ liệu', style: TextStyle(color: Colors.grey)),
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