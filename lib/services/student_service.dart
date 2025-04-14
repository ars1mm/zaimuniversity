import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/user.dart';
import 'auth_service.dart';

class StudentService {
  final AuthService _authService = AuthService();

  /// Adds a new student to the system
  /// This method is protected and can only be called by admin users
  Future<Map<String, dynamic>> addStudent({
    required String name,
    required String email,
    required String studentId,
    required String department,
    required int enrollmentYear,
    String? password,
  }) async {
    // First check if user has admin access
    final isAdmin = await _authService.isAdmin();
    if (!isAdmin) {
      return {
        'success': false,
        'message': 'Unauthorized: Admin privileges required',
      };
    }

    try {
      final token = await _authService.getToken();

      final response = await http.post(
        Uri.parse(AppConstants.addStudentEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'student_id': studentId,
          'department': department,
          'enrollment_year': enrollmentYear,
          'role': AppConstants.roleStudent,
          'password': password ?? generateDefaultPassword(studentId),
        }),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Student added successfully',
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to add student: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error adding student: ${e.toString()}',
      };
    }
  }

  /// Generates a default password for new students based on their student ID
  String generateDefaultPassword(String studentId) {
    // A simple default password pattern
    return 'IZU${studentId.substring(0, 4)}!';
  }

  /// Lists all students - also restricted to admin users
  Future<Map<String, dynamic>> getAllStudents() async {
    // Check if user has admin access
    final isAdmin = await _authService.isAdmin();
    if (!isAdmin) {
      return {
        'success': false,
        'message': 'Unauthorized: Admin privileges required',
      };
    }

    try {
      final token = await _authService.getToken();

      final response = await http.get(
        Uri.parse(AppConstants.addStudentEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> studentsJson = jsonDecode(response.body);
        final List<User> students =
            studentsJson.map((json) => User.fromJson(json)).toList();

        return {
          'success': true,
          'message': 'Students retrieved successfully',
          'data': students,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to retrieve students: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error retrieving students: ${e.toString()}',
      };
    }
  }
}
