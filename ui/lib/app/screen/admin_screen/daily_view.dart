import 'package:flutter/material.dart';
import '../../../core/models/calendar_event.dart';
import '../../../core/models/enum_model.dart'; 

class DailyView extends StatelessWidget {
  final DateTime currentDate;
  final List<CalendarEvent> Function(DateTime) getEventsForDate;

  final bool showClasses;
  final bool showExams;

  const DailyView({
    super.key,
    required this.currentDate,
    required this.getEventsForDate,
    this.showClasses = true,
    this.showExams = true,
  });

  @override
  Widget build(BuildContext context) {
    final allEvents = getEventsForDate(currentDate);

    final events = allEvents.where((e) {
      if (e.isExam && !showExams) return false;
      if (!e.isExam && !showClasses) return false;
      return true;
    }).toList();

    final morningEvents = events.where((e) => e.session == 'MORNING').toList();
    final afternoonEvents = events.where((e) => e.session == 'AFTERNOON').toList();
    final eveningEvents = events.where((e) => e.session == 'EVENING').toList();

    return ListView(
      padding: const EdgeInsets.all(12.0),
      children: [
        _buildSessionRow('Ca Sáng', morningEvents),
        const SizedBox(height: 12),
        _buildSessionRow('Ca Chiều', afternoonEvents),
        const SizedBox(height: 12),
        _buildSessionRow('Ca Tối', eveningEvents),
      ],
    );
  }

  Widget _buildSessionRow(String title, List<CalendarEvent> events) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề Ca
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold, 
                color: Color(0xFF6E8CF0),
                fontSize: 16,
              ),
            ),
          ),
          const Divider(height: 1),
          
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Không có lịch', 
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: events.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 300,
                      child: _buildDailyCard(e),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDailyCard(CalendarEvent e) {    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  e.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (!e.isExam && e.classStatus != null) _buildClassStatusBadge(e.classStatus!),
              if (e.isExam && e.examStatus != null) _buildExamStatusBadge(e.examStatus!),
            ],
          ),

          if (!e.isExam) ...[
            if (e.subjectName != null) ...[
              const SizedBox(height: 2),
              Text(
                e.subjectName!,
                style: const TextStyle(color: Colors.black87, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${e.semesterLabel} • Năm học ${e.academicYear}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (e.maxStudents != null) ...[
              const SizedBox(height: 4),
              Text(
                'Sĩ số tối đa: ${e.maxStudents}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.room, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Phòng: ${e.roomName}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],

          if (e.isExam) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Ngày thi: ${e.examDate?.day}/${e.examDate?.month}/${e.examDate?.year}',
                  style: const TextStyle(color: Colors.black87, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Khung giờ: ${e.examTime} (${e.duration} phút)',
                  style: const TextStyle(color: Colors.black87, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.room, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Phòng: ${e.roomName}',
                    style: const TextStyle(color: Colors.black87, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  e.teacherName,
                  style: TextStyle(
                    color: e.teacherName.contains('Chưa phân công') ? Colors.grey : Colors.black87,
                    fontSize: 12,
                    fontStyle: e.teacherName.contains('Chưa phân công') ? FontStyle.italic : FontStyle.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassStatusBadge(ClassStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildExamStatusBadge(ExamStatus status) {
    final color = status == ExamStatus.scheduled ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}