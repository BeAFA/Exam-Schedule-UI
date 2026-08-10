import 'dart:convert';
import 'package:http/http.dart' as http;

import '/core/token_storage.dart';
import '/core/models/profile_model.dart';
import '/core/models/subject_class_model.dart';
import '/core/models/subject_model.dart';
import '/core/models/room_model.dart';
import '/core/models/schedule_model.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';

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

  static Future<SubjectClass> createSubjectClass({
    required String subjectClassName,
    required int subjectId,
    required Semester semester,
    required String academicYear,
    required ClassStatus status,
    required int maxStudents,
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
        'status': status.value,
        'max_students': maxStudents,
        'room_id': roomId,
        'weekday': weekday.value,
        'session': session.value,
      }),
    );
 
    final data = jsonDecode(response.body);
 
    if (response.statusCode == 200 || response.statusCode == 201) {
      // Response dạng { subject_class: {...}, schedule: {...} }
      return SubjectClass.fromJson(data['subject_class'] as Map<String, dynamic>);
    } else {
      throw Exception(data['detail'] ?? 'Tạo lớp học phần thất bại');
    }
  }
}
