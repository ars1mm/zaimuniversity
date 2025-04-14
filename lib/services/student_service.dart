import '../constants/app_constants.dart';
import '../main.dart';
import '../models/user.dart';
import 'auth_service.dart';
import 'logger_service.dart';
import 'supabase_service.dart';

class StudentService {
  final AuthService _authService = AuthService();
  final SupabaseService _supabaseService = SupabaseService();
  static const String _tag = 'StudentService';

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
    LoggerService.info(_tag, 'Attempting to add student: $name ($email)');

    // First check if user has admin access
    final isAdmin = await _authService.isAdmin();
    if (!isAdmin) {
      LoggerService.warning(
          _tag, 'Unauthorized attempt to add student: $email');
      return {
        'success': false,
        'message': 'Unauthorized: Admin privileges required',
      };
    }

    try {
      // Step 1: Create a user account in Auth
      LoggerService.debug(_tag, 'Step 1: Creating auth account for: $email');
      final signUpResult = await _supabaseService.signUp(
        email: email,
        password: password ?? generateDefaultPassword(studentId),
      );

      if (signUpResult.user == null) {
        LoggerService.error(_tag, 'Failed to create auth account for: $email');
        return {
          'success': false,
          'message': 'Failed to create auth account',
        };
      }

      // Step 2: Create a record in the users table
      final userId = signUpResult.user!.id;
      LoggerService.debug(
          _tag, 'Step 2: Creating user record with ID: $userId');
      final createUserResult = await _supabaseService.createUser(
        email: email,
        fullName: name,
        role: AppConstants.roleStudent,
      );

      if (!createUserResult['success']) {
        LoggerService.error(_tag,
            'Failed to create user record: ${createUserResult['message']}');
        return createUserResult;
      }

      // Step 3: Find the department ID
      LoggerService.debug(
          _tag, 'Step 3: Finding department ID for: $department');
      final departmentResponse = await supabase
          .from(AppConstants.tableDepartments)
          .select('id')
          .eq('name', department)
          .maybeSingle();

      String departmentId;
      if (departmentResponse == null) {
        // Department doesn't exist, create it
        LoggerService.info(
            _tag, 'Department not found. Creating new department: $department');
        final newDept = await supabase
            .from(AppConstants.tableDepartments)
            .insert({
              'name': department,
              'description': 'Department of $department',
            })
            .select('id')
            .single();
        departmentId = newDept['id'];
        LoggerService.debug(
            _tag, 'Created new department with ID: $departmentId');
      } else {
        departmentId = departmentResponse['id'];
        LoggerService.debug(
            _tag, 'Found existing department with ID: $departmentId');
      }

      // Step 4: Add student details
      LoggerService.debug(
          _tag, 'Step 4: Adding student details for user ID: $userId');
      final addStudentResult = await _supabaseService.addStudent(
        name: name,
        email: email,
        studentId: studentId,
        departmentId: departmentId,
        userId: userId,
        enrollmentDate:
            DateTime(enrollmentYear, 9, 1), // Assuming enrollment in September
      );

      if (addStudentResult['success']) {
        LoggerService.info(
            _tag, 'Successfully added student: $name with ID: $studentId');
      } else {
        LoggerService.error(_tag,
            'Failed to add student details: ${addStudentResult['message']}');
      }

      return addStudentResult;
    } catch (e) {
      LoggerService.error(_tag, 'Error adding student: $email', e);
      return {
        'success': false,
        'message': 'Error adding student: ${e.toString()}',
      };
    }
  }

  /// Generates a default password for new students based on their student ID
  String generateDefaultPassword(String studentId) {
    // A simple default password pattern
    LoggerService.debug(
        _tag, 'Generating default password for student ID: $studentId');
    return 'IZU${studentId.substring(0, 4)}!';
  }

  /// Lists all students - also restricted to admin users
  Future<Map<String, dynamic>> getAllStudents() async {
    LoggerService.info(_tag, 'Fetching all students');

    // Check if user has admin access
    final isAdmin = await _authService.isAdmin();
    if (!isAdmin) {
      LoggerService.warning(_tag, 'Unauthorized attempt to fetch all students');
      return {
        'success': false,
        'message': 'Unauthorized: Admin privileges required',
      };
    }

    try {
      final result = await _supabaseService.getAllStudents();

      if (result['success'] && result['data'] != null) {
        final List<dynamic> studentsData = result['data'];
        LoggerService.debug(
            _tag, 'Retrieved ${studentsData.length} students from database');

        final List<User> students = studentsData.map((json) {
          // Merge student data with user data
          final userData = json[AppConstants.tableUsers];
          return User.fromJson({
            ...json,
            'full_name': userData['full_name'],
            'email': userData['email'],
            'role': userData['role'],
            'status': userData['status'],
          });
        }).toList();

        LoggerService.info(
            _tag, 'Successfully processed ${students.length} student records');
        return {
          'success': true,
          'message': 'Students retrieved successfully',
          'data': students,
        };
      } else {
        LoggerService.warning(
            _tag, 'Failed to retrieve students: ${result['message']}');
        return result;
      }
    } catch (e) {
      LoggerService.error(_tag, 'Error retrieving students', e);
      return {
        'success': false,
        'message': 'Failed to retrieve students: ${e.toString()}',
      };
    }
  }
}
