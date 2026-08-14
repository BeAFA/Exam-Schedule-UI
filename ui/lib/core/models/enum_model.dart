import 'package:flutter/material.dart';

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

enum Semester {
  semester1('Semester 1'),
  semester2('Semester 2'),
  semester3('Semester 3');

  final String value;
  const Semester(this.value);

  static Semester fromJson(String raw) {
    return Semester.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => Semester.semester1,
    );
  }

  String get label => switch (this) {
        Semester.semester1 => 'Học kỳ 1',
        Semester.semester2 => 'Học kỳ 2',
        Semester.semester3 => 'Học kỳ 3',
      };
}

enum ClassStatus {
  open('OPEN'),
  closed('CLOSED'),
  finished('FINISHED');

  final String value;
  const ClassStatus(this.value);

  static ClassStatus fromJson(String raw) {
    return ClassStatus.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => ClassStatus.open,
    );
  }

  String get label => switch (this) {
        ClassStatus.open => 'Đang mở đăng ký',
        ClassStatus.closed => 'Đã đóng đăng ký',
        ClassStatus.finished => 'Đã kết thúc',
      };

  Color get color => switch (this) {
        ClassStatus.open => const Color(0xFF34C759),
        ClassStatus.closed => const Color(0xFFFF9500),
        ClassStatus.finished => const Color(0xFF8E8E93),
      };
}