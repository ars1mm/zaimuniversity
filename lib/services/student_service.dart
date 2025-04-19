import '../constants/app_constants.dart';
import '../main.dart';
import '../models/user.dart';
import 'auth_service.dart';
import 'logger_service.dart';
import 'supabase_service.dart';

class StudentService {
  final AuthService _authService = AuthService();
  final SupabaseService _supabaseService = SupabaseService();
  final _logger = LoggerService();
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
    _logger.info('Attempting to add student: $name ($email)', tag: _tag);

    // First check if user has admin access
    final isAdmin = await _authService.isAdmin();
    if (!isAdmin) {
      _logger.warning('Unauthorized attempt to add student: $email', tag: _tag);
      return {
        'success': false,
        'message': 'Unauthorized: Admin privileges required',
      };
    }

    // We're allowing any email format, but still log if it doesn't match a standard pattern
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _logger.warning('Non-standard email format detected: $email (continuing anyway)', tag: _tag);
    }

    try {
      // Clean the email (trim whitespace and convert to lowercase)
      final cleanEmail = email.trim().toLowerCase();

      // Step 1: Create a user account in Auth
      _logger.debug('Step 1: Creating auth account for: $cleanEmail', tag: _tag);
      final signUpResult = await _supabaseService.signUp(
        email: cleanEmail,
        password: password ?? generateDefaultPassword(studentId),
      );

      if (signUpResult.user == null) {
        _logger.error('Failed to create auth account for: $cleanEmail', tag: _tag);
        return {
          'success': false,
          'message': 'Failed to create auth account',
        };
      }

      // Step 2: Create a record in the users table
      final userId = signUpResult.user!.id;
      _logger.debug('Step 2: Creating user record with ID: $userId', tag: _tag);
      final createUserResult = await _supabaseService.createUser(
        userId: userId,
        email: cleanEmail,
        fullName: name,
        role: AppConstants.roleStudent,
      );

      if (!createUserResult['success']) {
        _logger.error('Failed to create user record: ${createUserResult['message']}', tag: _tag);
        return createUserResult;
      }

      // Step 3: Find the department ID
      _logger.debug('Step 3: Finding department ID for: $department', tag: _tag);
      final departmentResponse = await supabase
          .from(AppConstants.tableDepartments)
          .select('id')
          .eq('name', department)
          .maybeSingle();

      String departmentId;
      if (departmentResponse == null) {
        // Department doesn't exist, create it
        _logger.info('Department not found. Creating new department: $department', tag: _tag);
        final newDept = await supabase
            .from(AppConstants.tableDepartments)
            .insert({
              'name': department,
              'description': 'Department of $department',
            })
            .select('id')
            .single();
        departmentId = newDept['id'];
        _logger.debug('Created new department with ID: $departmentId', tag: _tag);
      } else {
        departmentId = departmentResponse['id'];
        _logger.debug('Found existing department with ID: $departmentId', tag: _tag);
      }

      // Step 4: Add student details
      _logger.debug('Step 4: Adding student details for user ID: $userId', tag: _tag);
      final addStudentResult = await _supabaseService.addStudent(
        name: name,
        email: cleanEmail,
        studentId: studentId,
        departmentId: departmentId,
        userId: userId,
        enrollmentDate: DateTime(enrollmentYear, 9, 1), // Assuming enrollment in September
      );

      if (addStudentResult['success']) {
        _logger.info('Successfully added student: $name with ID: $studentId', tag: _tag);
      } else {
        _logger.error('Failed to add student details: ${addStudentResult['message']}', tag: _tag);
      }

      return addStudentResult;
    } catch (e, stackTrace) {
      _logger.error('Error adding student: $email', tag: _tag, error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Error adding student: ${e.toString()}',
      };
    }
  }

  /// Generates a default password for new students based on their student ID
  String generateDefaultPassword(String studentId) {
    // A simple default password pattern
    _logger.debug('Generating default password for student ID: $studentId', tag: _tag);
    return 'IZU${studentId.substring(0, 4)}!';
  }

  /// Lists all students - also restricted to admin users
  Future<Map<String, dynamic>> getAllStudents() async {
    _logger.info('Fetching all students', tag: _tag);

    // Check if user has admin access
    final isAdmin = await _authService.isAdmin();
    if (!isAdmin) {
      _logger.warning('Unauthorized attempt to fetch all students', tag: _tag);
      return {
        'success': false,
        'message': 'Unauthorized: Admin privileges required',
      };
    }

    try {
      final result = await _supabaseService.getAllStudents();

      if (result['success'] && result['data'] != null) {
        final List<dynamic> studentsData = result['data'];
        _logger.debug('Retrieved ${studentsData.length} students from database', tag: _tag);

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

        _logger.info('Successfully processed ${students.length} student records', tag: _tag);
        return {
          'success': true,
          'message': 'Students retrieved successfully',
          'data': students,
        };
      } else {
        _logger.warning('Failed to retrieve students: ${result['message']}', tag: _tag);
        return result;
      }
    } catch (e, stackTrace) {
      _logger.error('Error retrieving students', tag: _tag, error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Failed to retrieve students: ${e.toString()}',
      };
    }
  }
}
