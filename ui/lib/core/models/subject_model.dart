class Subject {
  final int id;
  final String subjectCode;
  final String name;
 
  Subject({required this.id, required this.subjectCode, required this.name});
 
  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      subjectCode: json['subject_code'] ?? json['code'] ?? '',
      name: json['subject_name'] ?? json['name'] ?? '',
    );
  }
 
  @override
  String toString() => name;
}