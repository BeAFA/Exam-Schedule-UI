import '../../../core/models/enum_model.dart';

class CalendarEvent {
  final String title;
  final String roomName;
  final String teacherName;
  final bool isExam;
  final String session; // MORNING, AFTERNOON, EVENING

  // Dành cho Lớp học phần
  final String? subjectName;
  final String? academicYear;
  final String? semesterLabel;
  final int? maxStudents;
  final int? numberOfSessions;
  final DateTime? startDate;
  final ClassStatus? classStatus;

  // Dành cho Lịch thi
  final String? examTime;
  final int? duration;
  final String? examTypeLabel;
  final ExamStatus? examStatus;
  final DateTime? examDate;

  CalendarEvent({
    required this.title,
    required this.roomName,
    required this.teacherName,
    required this.isExam,
    required this.session,
    this.subjectName,
    this.academicYear,
    this.semesterLabel,
    this.maxStudents,
    this.numberOfSessions,
    this.startDate,
    this.classStatus,
    this.examTime,
    this.duration,
    this.examTypeLabel,
    this.examStatus,
    this.examDate,
  });
}