import 'enum_model.dart';

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