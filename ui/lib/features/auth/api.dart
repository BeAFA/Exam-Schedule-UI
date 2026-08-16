import 'dart:convert';
import 'package:http/http.dart' as http;

import '/core/token_storage.dart';
import '/core/models/profile_model.dart';
import '/core/models/subject_class_model.dart';
import '/core/models/subject_model.dart';
import '/core/models/room_model.dart';
import '/core/models/enum_model.dart';
import '/core/models/teaching_assignment_model.dart';
import '/core/models/schedule_model.dart';
import '/core/models/exam_model.dart';
import '/core/models/exam_invigilator_model.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.158:8000';

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await TokenStorage.saveSession(data['access_token'], data['role']);
      return data;
    } else {
      throw Exception(data['detail'] ?? 'Đăng nhập thất bại');
    }
  }

  static Future<Profile> profile() async {
    final url = Uri.parse('$baseUrl/me');
    final token = await TokenStorage.getToken();

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Profile.fromJson(data);
    } else {
      throw Exception('Failed to fetch profile');
    }
  }

  static Future<Profile> getCurrentUser() async {
  final token = await TokenStorage.getToken();

  if (token == null) {
    throw Exception('No token');
  }

  final response = await http.get(
    Uri.parse('$baseUrl/me'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Unauthorized');
  }

  return Profile.fromJson(jsonDecode(response.body));
}

  static Future<void> logout() async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      await TokenStorage.clearSession();
      return;
    }

    final url = Uri.parse('$baseUrl/logout');
    try {
      await http.post(url, headers: {'Authorization': 'Bearer $token'});
    } catch (_) {}
    await TokenStorage.clearSession();
  }

  static Future<List<Subject>> getSubjects() async {
    final url = Uri.parse('$baseUrl/subject');
    final token = await TokenStorage.getToken();

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => Subject.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Failed to fetch subjects');
    }
  }

  static Future<List<Room>> getRooms() async {
    final url = Uri.parse('$baseUrl/room');
    final token = await TokenStorage.getToken();
 
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
 
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => Room.fromJson(e as Map<String, dynamic>)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Failed to fetch rooms');
    }
  }

  static Future<List<Schedule>> getSchedules() async{
    final url = Uri.parse('$baseUrl/schedule');
    final token = await TokenStorage.getToken();
 
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
 
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => Schedule.fromJson(e as Map<String, dynamic>)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Failed to fetch schedules');
    }
  }

  static Future<List<SubjectClass>> getSubjectClass() async {
    final url = Uri.parse('$baseUrl/subject_class');
    final token = await TokenStorage.getToken();
 
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
 
    if (response.statusCode == 200) {
      // Backend trả về MỘT DANH SÁCH (crud.get_all_subject_class trả list),
      // nên phải decode ra List rồi map từng phần tử, KHÔNG parse như 1 object.
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => SubjectClass.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (response.statusCode == 404) {
      // Backend cố tình trả 404 khi danh sách rỗng ("Hiện không có lớp nào cả!")
      // -> đây là trạng thái hợp lệ (danh sách rỗng), không phải lỗi thật sự.
      return [];
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Failed to fetch subject class');
    }
  }

  /// Danh sách giảng viên. Backend (UserOut) chỉ trả id/user_code/
  /// first_name/last_name/email — không có full_name/role như /me trả về.
  /// Để "dùng chung với Profile model" như yêu cầu, ta tự ghép full_name
  /// từ first_name + last_name và gắn role = 'TEACHER' ở phía client
  /// trước khi đưa vào Profile.fromJson.
  static Future<List<Profile>> getTeachers() async {
    final url = Uri.parse('$baseUrl/teacher');
    final token = await TokenStorage.getToken();
 
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
 
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) {
        final map = e as Map<String, dynamic>;
        final fullName =
            '${map['first_name'] ?? ''} ${map['last_name'] ?? ''}'.trim();
        return Profile.fromJson({
          ...map,
          'full_name': fullName,
          'role': 'TEACHER',
        });
      }).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Failed to fetch teachers');
    }
  }

  static Future<SubjectClass> createSubjectClass({
    required String subjectClassName,
    required int subjectId,
    required Semester semester,
    required String academicYear,
    required int maxStudents,
    required String startDate, // Định dạng YYYY-MM-DD
    required int numberOfSessions,
    required int roomId,
    required Weekday weekday,
    required SessionPeriod session,
  }) async {
    final url = Uri.parse('$baseUrl/subject_class/create');
    final token = await TokenStorage.getToken();
 
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'subject_class_name': subjectClassName,
        'subject_id': subjectId,
        'semester': semester.value,
        'academic_year': academicYear,
        'max_students': maxStudents,
        'start_date': startDate,
        'number_of_sessions': numberOfSessions,
        // Backend yêu cầu schedules là một list
        'schedules': [
          {
            'room_id': roomId,
            'weekday': weekday.value,
            'session': session.value,
          }
        ],
      }),
    );
 
    final data = jsonDecode(response.body);
 
    if (response.statusCode == 200 || response.statusCode == 201) {
      return SubjectClass.fromJson(data['subject_class'] as Map<String, dynamic>);
    } else {
      throw Exception(data['detail'] ?? 'Tạo lớp học phần thất bại');
    }
  }

  static Future<SubjectClass> updateSubjectClass({
    required int subjectClassId,
    required String subjectClassName,
    required Semester semester,
    required String academicYear,
    required int maxStudents,
    required String startDate, // Định dạng YYYY-MM-DD
    required int numberOfSessions,
    required int roomId,
    required Weekday weekday,
    required SessionPeriod session,
    required ClassStatus status,
  }) async {
    final url = Uri.parse('$baseUrl/subject_class/$subjectClassId/update');
    final token = await TokenStorage.getToken();
 
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'subject_class_name': subjectClassName,
        'semester': semester.value,
        'academic_year': academicYear,
        'max_students': maxStudents,
        'start_date': startDate,
        'number_of_sessions': numberOfSessions,
        'status': status.value,
        // Backend yêu cầu schedules là một list
        'schedules': [
          {
            'room_id': roomId,
            'weekday': weekday.value,
            'session': session.value,
          }
        ],
      }),
    );
 
    final data = jsonDecode(response.body);
 
    if (response.statusCode == 200 || response.statusCode == 201) {
      return SubjectClass.fromJson(data['subject_class'] as Map<String, dynamic>);
    } else {
      throw Exception(data['detail'] ?? 'Cập nhật lớp học phần thất bại');
    }
  }
 
  /// Lấy phân công giảng dạy hiện tại (nếu có) của 1 lớp học phần.
  /// Backend trả `null` (status 200) khi lớp chưa có giảng viên nào.
  static Future<TeachingAssignment?> getTeachingAssignment(
    int subjectClassId,
  ) async {
    final url =
        Uri.parse('$baseUrl/subject_class/$subjectClassId/teaching_assignment');
    final token = await TokenStorage.getToken();
 
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
 
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data == null) return null;
      return TeachingAssignment.fromJson(data as Map<String, dynamic>);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Failed to fetch teaching assignment');
    }
  }
 
  static Future<TeachingAssignment> createTeachingAssignment({
    required int teacherId,
    required int subjectClassId,
  }) async {
    final url = Uri.parse('$baseUrl/teaching_assignment/create');
    final token = await TokenStorage.getToken();
 
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'teacher_id': teacherId,
        'subject_class_id': subjectClassId,
      }),
    );
 
    final data = jsonDecode(response.body);
 
    if (response.statusCode == 200 || response.statusCode == 201) {
      return TeachingAssignment.fromJson(data as Map<String, dynamic>);
    } else {
      throw Exception(data['detail'] ?? 'Phân công giảng dạy thất bại');
    }
  }
 
  static Future<TeachingAssignment> updateTeachingAssignment({
    required int teachingAssignmentId,
    required int teacherId,
    required int subjectClassId,
  }) async {
    final url =
        Uri.parse('$baseUrl/teaching_assignment/$teachingAssignmentId/update');
    final token = await TokenStorage.getToken();
 
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'teacher_id': teacherId,
        'subject_class_id': subjectClassId,
      }),
    );
 
    final data = jsonDecode(response.body);
 
    if (response.statusCode == 200) {
      return TeachingAssignment.fromJson(data as Map<String, dynamic>);
    } else {
      throw Exception(data['detail'] ?? 'Cập nhật phân công giảng dạy thất bại');
    }
  }

  static Future<List<Exam>> getExams() async {
    final url = Uri.parse('$baseUrl/exam');
    final token = await TokenStorage.getToken();

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => Exam.fromJson(e as Map<String, dynamic>)).toList();
    } else if (response.statusCode == 404) {
      // Backend trả về 404 khi không có lịch thi nào
      return [];
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Failed to fetch exams');
    }
  }

  /// Tạo lịch thi mới
  static Future<Exam> createExam({
    required int subjectClassId,
    required int roomId,
    required String examDate,
    required TypeOfExam type,
    required TimeFrame timeFrame,
    required int duration,
  }) async {
    final url = Uri.parse('$baseUrl/exam/create');
    final token = await TokenStorage.getToken();

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'subject_class_id': subjectClassId,
        'room_id': roomId,
        'exam_date': examDate,
        'type': type.value,
        'time_frame': timeFrame.value,
        'duration': duration,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Exam.fromJson(data as Map<String, dynamic>);
    } else {
      throw Exception(data['detail'] ?? 'Tạo lịch thi thất bại');
    }
  }

  static Future<Exam> updateExam({
    required int examId,
    required int roomId,
    required String examDate,
    required TypeOfExam type,
    required TimeFrame timeFrame,
    required int duration,
    required ExamStatus status,
  }) async {
    final url = Uri.parse('$baseUrl/exam/$examId/update');
    final token = await TokenStorage.getToken();

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'room_id': roomId,
        'exam_date': examDate,
        'type': type.value,
        'time_frame': timeFrame.value,
        'duration': duration,
        'status': status.value,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return Exam.fromJson(data as Map<String, dynamic>);
    } else {
      throw Exception(data['detail'] ?? 'Cập nhật lịch thi thất bại');
    }
  }

  static Future<List<ExamInvigilator>> getExamInvigilators(int examId) async {
    final url = Uri.parse('$baseUrl/exam_invigilator?exam_id=$examId');
    final token = await TokenStorage.getToken();

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => ExamInvigilator.fromJson(e as Map<String, dynamic>)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Lấy danh sách CBCT thất bại');
    }
  }

  static Future<ExamInvigilator> createExamInvigilator({
    required int examId,
    required int teacherId,
  }) async {
    final url = Uri.parse('$baseUrl/exam_invigilator/create');
    final token = await TokenStorage.getToken();

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'exam_id': examId,
        'teacher_id': teacherId,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ExamInvigilator.fromJson(data as Map<String, dynamic>);
    } else {
      throw Exception(data['detail'] ?? 'Phân công CBCT thất bại');
    }
  }

  static Future<ExamInvigilator> updateExamInvigilator({
    required int examInvigilatorId,
    required int teacherId,
  }) async {
    final url = Uri.parse('$baseUrl/exam_invigilator/$examInvigilatorId/update');
    final token = await TokenStorage.getToken();

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'teacher_id': teacherId}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return ExamInvigilator.fromJson(data as Map<String, dynamic>);
    } else {
      throw Exception(data['detail'] ?? 'Cập nhật CBCT thất bại');
    }
  }
}
