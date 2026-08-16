class ExamInvigilator {
  final int id;
  final int examId;
  final int teacherId;

  ExamInvigilator({
    required this.id,
    required this.examId,
    required this.teacherId,
  });

  factory ExamInvigilator.fromJson(Map<String, dynamic> json) {
    return ExamInvigilator(
      id: json['id'],
      examId: json['exam_id'],
      teacherId: json['teacher_id'],
    );
  }
}