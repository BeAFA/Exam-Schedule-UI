/// Tương ứng backend: class Weekday(Enum)
enum Weekday {
  mon('MON'),
  tue('TUE'),
  wed('WED'),
  thu('THU'),
  fri('FRI'),
  sat('SAT'),
  sun('SUN');

  final String value;
  const Weekday(this.value);

  static Weekday fromJson(String raw) {
    return Weekday.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => Weekday.mon,
    );
  }

  String get label => switch (this) {
        Weekday.mon => 'Thứ 2',
        Weekday.tue => 'Thứ 3',
        Weekday.wed => 'Thứ 4',
        Weekday.thu => 'Thứ 5',
        Weekday.fri => 'Thứ 6',
        Weekday.sat => 'Thứ 7',
        Weekday.sun => 'Chủ nhật',
      };
}

/// Tương ứng backend: class Session(Enum) — đổi tên thành SessionPeriod
/// trong Dart để tránh nhầm với các khái niệm "session" khác (đăng nhập...).
enum SessionPeriod {
  morning('MORNING'),
  afternoon('AFTERNOON');

  final String value;
  const SessionPeriod(this.value);

  static SessionPeriod fromJson(String raw) {
    return SessionPeriod.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => SessionPeriod.morning,
    );
  }

  String get label => switch (this) {
        SessionPeriod.morning => 'Buổi sáng',
        SessionPeriod.afternoon => 'Buổi chiều',
      };
}

class Schedule {
  final int id;
  final int subjectClassId;
  final int roomId;
  final Weekday weekday;
  final SessionPeriod session;
  final String academicYear;

  Schedule({
    required this.id,
    required this.subjectClassId,
    required this.roomId,
    required this.weekday,
    required this.session,
    required this.academicYear,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      subjectClassId: json['subject_class_id'],
      roomId: json['room_id'],
      weekday: Weekday.fromJson(json['weekday'] ?? ''),
      session: SessionPeriod.fromJson(json['session'] ?? ''),
      academicYear: json['academic_year'] ?? '',
    );
  }
}