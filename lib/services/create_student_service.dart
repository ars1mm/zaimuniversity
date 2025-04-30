import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../main.dart';
import 'logger_service.dart';

class CreateStudentService {
  final _logger = LoggerService();
  static const String _tag = 'CreateStudentService';

  /// Creates a student account and database records
  Future<bool> createStudent({
    required String email,
    required String password,
    required String fullName,
    required String studentId,
    required String departmentId,
    required String address,
    required String phone,
    required String status,
    required String academicStanding,
  }) async {
    try {
      _logger.info('Creating student account for: $email', tag: _tag);

      // First, create the user through signup
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': AppConstants.roleStudent,
        },
      );

      if (authResponse.user == null) {
        _logger.error('Failed to create auth record for student', tag: _tag);
        return false;
      }

      final userId = authResponse.user!.id;

      // We need to manually confirm the email since we're in a client app
      // This is a workaround because we can't use admin API

      // 1. Create user record in the users table
      await supabase.from(AppConstants.tableUsers).insert({
        'id': userId,
        'email': email,
        'full_name': fullName,
        'role': AppConstants.roleStudent,
        'status': status,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 2. Create student record in the students table
      await supabase.from(AppConstants.tableStudents).insert({
        'id': userId,
        'student_id': studentId,
        'department_id': departmentId,
        'address': address,
        'contact_info': {
          'phone': phone,
        },
        'enrollment_date': DateTime.now().toIso8601String(),
        'academic_standing': academicStanding,
        'preferences': {},
      });

      _logger.info('Successfully created student records for: $email',
          tag: _tag);

      // 3. Now we need to tell the user they must verify their email before logging in
      return true;
    } catch (e) {
      _logger.error('Error creating student', tag: _tag, error: e);
      return false;
    }
  }
}
