import 'package:flutter/material.dart';

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

class SubjectClass {
  final int id;
  final String subjectClassName;
  final int subjectId;
  final Semester semester;
  final String academicYear;
  final ClassStatus status;
  final int? maxStudents;

  SubjectClass({
    required this.id,
    required this.subjectClassName,
    required this.subjectId,
    required this.semester,
    required this.academicYear,
    required this.status,
    this.maxStudents,
  });

  factory SubjectClass.fromJson(Map<String, dynamic> json) {
    return SubjectClass(
      id: json['id'],
      subjectClassName: json['subject_class_name'] ?? '',
      subjectId: json['subject_id'],
      semester: Semester.fromJson(json['semester'] ?? ''),
      academicYear: json['academic_year'] ?? '',
      status: ClassStatus.fromJson(json['status'] ?? ''),
      maxStudents: json['max_students'],
    );
  }
}