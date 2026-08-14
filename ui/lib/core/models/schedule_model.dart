import 'enum_model.dart';
import 'room_model.dart';

class Schedule {
  final int id;
  final int subjectClassId;
  final int roomId;
  final Room room;
  final Weekday weekday;
  final SessionPeriod session;
  final String academicYear;

  Schedule({
    required this.id,
    required this.subjectClassId,
    required this.roomId,
    required this.room,
    required this.weekday,
    required this.session,
    required this.academicYear,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
  return Schedule(
    id: json['id'],
    subjectClassId: json['subject_class_id'],
    roomId: json['room_id'],

    room: json['room'] != null
        ? Room.fromJson(
            json['room'] as Map<String, dynamic>,
          )
        : Room(
            id: json['room_id'],
            name: 'Không xác định',
            capacity: 0,
          ),

    weekday: Weekday.fromJson(
      json['weekday'] ?? '',
    ),

    session: SessionPeriod.fromJson(
      json['session'] ?? '',
    ),

    academicYear: json['academic_year'] ?? '',
  );
}
}