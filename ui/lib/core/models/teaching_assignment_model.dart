class TeachingAssignment {
  final int id;
  final int teacherId;
  final int subjectClassId;

  TeachingAssignment({
    required this.id,
    required this.teacherId,
    required this.subjectClassId,
  });

  factory TeachingAssignment.fromJson(Map<String, dynamic> json) {
    return TeachingAssignment(
      id: json['id'],
      teacherId: json['teacher_id'],
      subjectClassId: json['subject_class_id'],
    );
  }
}