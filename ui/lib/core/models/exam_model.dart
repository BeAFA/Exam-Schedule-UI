import 'enum_model.dart';

class Exam {
  final int id;
  final int subjectClassId;
  final int roomId;
  final DateTime examDate;
  final TypeOfExam type;
  final TimeFrame timeFrame;
  final int duration;
  final ExamStatus status;

  Exam({
    required this.id,
    required this.subjectClassId,
    required this.roomId,
    required this.examDate,
    required this.type,
    required this.timeFrame,
    required this.duration,
    required this.status,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'],
      subjectClassId: json['subject_class_id'],
      roomId: json['room_id'],
      examDate: DateTime.parse(json['exam_date']),
      type: TypeOfExam.fromJson(json['type']),
      timeFrame: TimeFrame.fromJson(json['time_frame']),
      duration: json['duration'],
      status: ExamStatus.fromJson(json['status'] ?? 'SCHEDULED'),
    );
  }
}