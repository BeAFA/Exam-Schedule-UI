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

enum TypeOfExam {
  midterm('MIDTERM'),
  finalExam('FINALTEST');

  final String value;
  const TypeOfExam(this.value);

  static TypeOfExam fromJson(String raw) {
    return TypeOfExam.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => TypeOfExam.finalExam,
    );
  }

  String get label => switch (this) {
        TypeOfExam.midterm => 'Giữa kỳ',
        TypeOfExam.finalExam => 'Cuối kỳ',
      };
}

enum TimeFrame {
  h0730('07:30'),
  h0950('09:50'),
  h1300('13:00'),
  h1520('15:20'),
  h1800('18:00');

  final String value;
  const TimeFrame(this.value);

  static TimeFrame fromJson(String raw) {
    return TimeFrame.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => TimeFrame.h0730,
    );
  }

  String get label => switch (this) {
        TimeFrame.h0730 => '07:30',
        TimeFrame.h0950 => '09:50',
        TimeFrame.h1300 => '13:00',
        TimeFrame.h1520 => '15:20',
        TimeFrame.h1800 => '18:00',
      };
}

enum ExamStatus {
  scheduled('SCHEDULED'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  final String value;
  const ExamStatus(this.value);

  static ExamStatus fromJson(String raw) {
    return ExamStatus.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => ExamStatus.scheduled,
    );
  }

  String get label => switch (this) {
        ExamStatus.scheduled => 'Đã xếp lịch',
        ExamStatus.completed => 'Đã hoàn thành',
        ExamStatus.cancelled => 'Đã hủy',
      };
}