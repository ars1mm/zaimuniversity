import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import 'logger_service.dart';

/// SupabaseService provides a centralized way to interact with the Supabase client.
/// It handles common operations like authentication, table access, and error handling.
class SupabaseService {
  // Get the Supabase client from the main.dart file
  final SupabaseClient supabase = Supabase.instance.client;
  final GoTrueClient _auth = Supabase.instance.client.auth;
  static const String _tag = 'SupabaseService';

  // Authentication methods
  Future<AuthResponse> signUp(
      {required String email, required String password}) async {
    LoggerService.info(_tag, 'Creating new user account for: $email');
    try {
      final result = await _auth.signUp(email: email, password: password);
      if (result.user != null) {
        LoggerService.info(
            _tag, 'Successfully created auth account for: $email');
      } else {
        LoggerService.warning(
            _tag, 'Auth account creation returned null user for: $email');
      }
      return result;
    } catch (e) {
      LoggerService.error(_tag, 'Failed to create auth account for: $email', e);
      rethrow; // Let the calling code handle the error
    }
  }

  Future<AuthResponse> signIn(
      {required String email, required String password}) async {
    LoggerService.info(_tag, 'Attempting to sign in user: $email');
    try {
      final result =
          await _auth.signInWithPassword(email: email, password: password);
      if (result.user != null) {
        LoggerService.info(_tag, 'Successfully signed in user: $email');
      } else {
        LoggerService.warning(_tag, 'Sign in returned null user for: $email');
      }
      return result;
    } catch (e) {
      LoggerService.error(_tag, 'Failed to sign in user: $email', e);
      rethrow;
    }
  }

  Future<void> signOut() async {
    LoggerService.info(_tag, 'Signing out current user');
    try {
      await _auth.signOut();
      LoggerService.info(_tag, 'User signed out successfully');
    } catch (e) {
      LoggerService.error(_tag, 'Error signing out user', e);
      rethrow;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        LoggerService.debug(_tag, 'Current user retrieved: ${user.email}');
      } else {
        LoggerService.debug(_tag, 'No current user found');
      }
      return user;
    } catch (e) {
      LoggerService.error(_tag, 'Error getting current user', e);
      return null;
    }
  }

  // User management
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String fullName,
    required String role,
    String status = 'active',
  }) async {
    LoggerService.info(
        _tag, 'Creating user record for: $email with role: $role');
    try {
      final Map<String, dynamic> userData = {
        'email': email,
        'full_name': fullName,
        'role': role,
        'status': status,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await supabase
          .from(AppConstants.tableUsers)
          .insert(userData)
          .select('id')
          .single();

      LoggerService.info(
          _tag, 'Created user record with ID: ${response['id']}');
      return {
        'success': true,
        'message': 'User created successfully',
        'data': response
      };
    } catch (e) {
      LoggerService.error(_tag, 'Failed to create user record for: $email', e);
      return {
        'success': false,
        'message': 'Failed to create user: ${e.toString()}',
      };
    }
  }

  // Student operations
  Future<Map<String, dynamic>> addStudent({
    required String name,
    required String email,
    required String studentId,
    required String departmentId,
    required String userId,
    String? address,
    Map<String, dynamic>? contactInfo,
    DateTime? enrollmentDate,
  }) async {
    LoggerService.info(_tag, 'Creating student record for: $name ($studentId)');
    try {
      // Create student record linked to user
      final Map<String, dynamic> studentData = {
        'id': userId, // This links to the users table
        'student_id': studentId,
        'department_id': departmentId,
        'address': address,
        'contact_info': contactInfo ?? {},
        'enrollment_date': enrollmentDate?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'academic_standing': 'good',
        'preferences': {},
      };

      final response = await supabase
          .from(AppConstants.tableStudents)
          .insert(studentData)
          .select()
          .single();

      LoggerService.info(
          _tag, 'Student record created successfully for ID: $studentId');
      return {
        'success': true,
        'message': 'Student added successfully',
        'data': response
      };
    } catch (e) {
      LoggerService.error(
          _tag, 'Failed to create student record for ID: $studentId', e);
      return {
        'success': false,
        'message': 'Failed to add student: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getAllStudents() async {
    LoggerService.info(_tag, 'Retrieving all students');
    try {
      // Join users and students tables to get complete student information
      final response = await supabase
          .from(AppConstants.tableStudents)
          .select(
              '*, ${AppConstants.tableUsers}(full_name, email, role, status)')
          .order('student_id');

      LoggerService.info(_tag, 'Retrieved ${response.length} student records');
      return {
        'success': true,
        'message': 'Students retrieved successfully',
        'data': response
      };
    } catch (e) {
      LoggerService.error(_tag, 'Failed to retrieve students', e);
      return {
        'success': false,
        'message': 'Failed to retrieve students: ${e.toString()}',
      };
    }
  }

  // Check user roles
  Future<bool> isAdmin() async {
    LoggerService.debug(_tag, 'Checking if current user is admin');
    final user = _auth.currentUser;
    if (user == null) {
      LoggerService.debug(_tag, 'No current user found during admin check');
      return false;
    }

    try {
      final userData = await supabase
          .from(AppConstants.tableUsers)
          .select('role')
          .eq('id', user.id)
          .single();

      final isAdmin = userData['role'] == AppConstants.roleAdmin;
      LoggerService.debug(_tag, 'User ${user.email} admin status: $isAdmin');
      return isAdmin;
    } catch (e) {
      LoggerService.error(
          _tag, 'Error checking admin status for user: ${user.email}', e);
      return false;
    }
  }

  Future<bool> isTeacher() async {
    LoggerService.debug(_tag, 'Checking if current user is teacher');
    final user = _auth.currentUser;
    if (user == null) {
      LoggerService.debug(_tag, 'No current user found during teacher check');
      return false;
    }

    try {
      final userData = await supabase
          .from(AppConstants.tableUsers)
          .select('role')
          .eq('id', user.id)
          .single();

      final isTeacher = userData['role'] == AppConstants.roleTeacher;
      LoggerService.debug(
          _tag, 'User ${user.email} teacher status: $isTeacher');
      return isTeacher;
    } catch (e) {
      LoggerService.error(
          _tag, 'Error checking teacher status for user: ${user.email}', e);
      return false;
    }
  }

  Future<bool> isSupervisor() async {
    LoggerService.debug(_tag, 'Checking if current user is supervisor');
    final user = _auth.currentUser;
    if (user == null) {
      LoggerService.debug(
          _tag, 'No current user found during supervisor check');
      return false;
    }

    try {
      final userData = await supabase
          .from(AppConstants.tableUsers)
          .select('role')
          .eq('id', user.id)
          .single();

      final isSupervisor = userData['role'] == AppConstants.roleSupervisor;
      LoggerService.debug(
          _tag, 'User ${user.email} supervisor status: $isSupervisor');
      return isSupervisor;
    } catch (e) {
      LoggerService.error(
          _tag, 'Error checking supervisor status for user: ${user.email}', e);
      return false;
    }
  }

  Future<bool> isStudent() async {
    LoggerService.debug(_tag, 'Checking if current user is student');
    final user = _auth.currentUser;
    if (user == null) {
      LoggerService.debug(_tag, 'No current user found during student check');
      return false;
    }

    try {
      final userData = await supabase
          .from(AppConstants.tableUsers)
          .select('role')
          .eq('id', user.id)
          .single();

      final isStudent = userData['role'] == AppConstants.roleStudent;
      LoggerService.debug(
          _tag, 'User ${user.email} student status: $isStudent');
      return isStudent;
    } catch (e) {
      LoggerService.error(
          _tag, 'Error checking student status for user: ${user.email}', e);
      return false;
    }
  }
}
