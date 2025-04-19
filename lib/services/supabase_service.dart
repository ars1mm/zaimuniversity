import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import 'base_service.dart';
import 'logger_service.dart';

/// SupabaseService handles role-based access control checks
class SupabaseService extends BaseService {
  final _logger = LoggerService();
  static const String _tag = 'SupabaseService';

  /// Gets the user's role from the database
  Future<String?> _getUserRole() async {
    try {
      final user = auth.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user found', tag: _tag);
        return null;
      }

      final userData = await supabase
          .from(AppConstants.tableUsers)
          .select('role')
          .eq('id', user.id)
          .single();

      return userData['role'] as String?;
    } catch (e, stackTrace) {
      _logger.error('Error getting user role', tag: _tag, error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Checks if the current user has admin role
  Future<bool> isAdmin() async {
    final role = await _getUserRole();
    return role == AppConstants.roleAdmin;
  }

  /// Checks if the current user has teacher role
  Future<bool> isTeacher() async {
    final role = await _getUserRole();
    return role == AppConstants.roleTeacher;
  }

  /// Checks if the current user has supervisor role
  Future<bool> isSupervisor() async {
    final role = await _getUserRole();
    return role == AppConstants.roleSupervisor;
  }

  /// Checks if the current user has student role
  Future<bool> isStudent() async {
    final role = await _getUserRole();
    return role == AppConstants.roleStudent;
  }

  /// Gets the current authenticated user
  Future<User?> getCurrentUser() async {
    try {
      _logger.info('Getting current user', tag: _tag);
      return auth.currentUser;
    } catch (e, stackTrace) {
      _logger.error('Error getting current user', tag: _tag, error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // Authentication methods
  Future<AuthResponse> signUp({required String email, required String password}) async {
    _logger.info('Creating new user account', tag: _tag);
    try {
      // Clean email and ensure it's in proper format
      final cleanEmail = email.trim().toLowerCase();
      String authEmail = cleanEmail;

      // If email doesn't contain @, append the institutional domain
      if (!cleanEmail.contains('@')) {
        String sanitizedPart = cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
        if (sanitizedPart.isEmpty) sanitizedPart = 'user';
        authEmail = '$sanitizedPart@zaim.edu.tr';
        _logger.warning('Using fallback email for auth', tag: _tag);
      }

      final result = await auth.signUp(
        email: authEmail,
        password: password,
      );

      if (result.user != null) {
        _logger.info('Successfully created auth account', tag: _tag);
      } else {
        _logger.warning('Auth account creation returned null user', tag: _tag);
      }
      return result;
    } catch (e, stackTrace) {
      if (e is AuthException) {
        _logger.error('Auth error creating account', tag: _tag, error: e, stackTrace: stackTrace);

        // Special handling for common email issues
        if (e.message == 'email_address_invalid') {
          _logger.warning('Email address rejected by Supabase', tag: _tag);
        } else if (e.message == 'user_already_exists') {
          _logger.warning('User already exists', tag: _tag);
        }
      } else {
        _logger.error('Failed to create auth account', tag: _tag, error: e, stackTrace: stackTrace);
      }
      rethrow;
    }
  }

  Future<AuthResponse> signIn({required String email, required String password}) async {
    _logger.info('Attempting to sign in user', tag: _tag);
    try {
      final result = await auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        _logger.info('Successfully signed in user', tag: _tag);
      } else {
        _logger.warning('Sign in returned null user', tag: _tag);
      }
      return result;
    } catch (e, stackTrace) {
      _logger.error('Failed to sign in user', tag: _tag, error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    _logger.info('Signing out current user', tag: _tag);
    try {
      await auth.signOut();
      _logger.info('User signed out successfully', tag: _tag);
    } catch (e, stackTrace) {
      _logger.error('Error signing out user', tag: _tag, error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // User management
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String fullName,
    required String role,
    required String userId,
    String status = 'active',
  }) async {
    _logger.info('Creating user record for: $email with role: $role', tag: _tag);
    try {
      final Map<String, dynamic> userData = {
        'id': userId,
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

      _logger.info('Created user record with ID: ${response['id']}', tag: _tag);
      return {
        'success': true,
        'message': 'User created successfully',
        'data': response
      };
    } catch (e) {
      _logger.error('Failed to create user record for: $email', tag: _tag, error: e);
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
    _logger.info('Creating student record for: $name ($studentId)', tag: _tag);
    try {
      // First, verify that the user record exists in the users table
      final userExists = await _verifyUserExists(userId);

      if (!userExists) {
        _logger.warning('User ID $userId does not exist in users table. Creating it now.', tag: _tag);

        // Create the user record if it doesn't exist
        final userData = {
          'id': userId,
          'email': email,
          'full_name': name,
          'role': 'student',
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await supabase.from(AppConstants.tableUsers).insert(userData);

        // Verify again to make sure it was created
        final verifiedAgain = await _verifyUserExists(userId);
        if (!verifiedAgain) {
          throw Exception('Failed to create user record in users table');
        }
      }

      // Now create the student record
      final Map<String, dynamic> studentData = {
        'id': userId,
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

      _logger.info('Student record created successfully for ID: $studentId', tag: _tag);
      return {
        'success': true,
        'message': 'Student added successfully',
        'data': response
      };
    } catch (e) {
      _logger.error('Failed to create student record for ID: $studentId', tag: _tag, error: e);
      return {
        'success': false,
        'message': 'Failed to add student: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getAllStudents() async {
    _logger.info('Retrieving all students', tag: _tag);
    try {
      // Join users and students tables to get complete student information
      final response = await supabase
          .from(AppConstants.tableStudents)
          .select(
              '*, ${AppConstants.tableUsers}(full_name, email, role, status)')
          .order('student_id', ascending: false);

      // If no students were found, try a different query to diagnose the issue
      if (response.isEmpty) {
        _logger.warning('No students found with the primary query. Trying a direct query to check if students exist.', tag: _tag);

        // Try a simple query to check if students table has any records at all
        final directQuery = await supabase
            .from(AppConstants.tableStudents)
            .select('id, student_id')
            .limit(5);

        if (directQuery.isNotEmpty) {
          _logger.warning('Found ${directQuery.length} student records with direct query, but join failed. Possible join configuration issue.', tag: _tag);
        } else {
          _logger.warning('No student records found even with direct query. Students table might be empty.', tag: _tag);
        }
      }

      _logger.info('Retrieved ${response.length} student records', tag: _tag);
      return {
        'success': true,
        'message': 'Students retrieved successfully',
        'data': response
      };
    } catch (e) {
      _logger.error('Failed to retrieve students', tag: _tag, error: e);
      return {
        'success': false,
        'message': 'Failed to retrieve students: ${e.toString()}',
      };
    }
  }

  // Helper function to check if an email follows Supabase's requirements
  bool _isValidEmail(String email) {
    // Basic email validation for Supabase compatibility
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email) && email.length <= 255;
  }

  // Helper method to verify if a user with the given ID exists in the users table
  Future<bool> _verifyUserExists(String userId) async {
    try {
      final response = await supabase
          .from(AppConstants.tableUsers)
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      _logger.error('Error verifying user existence: $userId', tag: _tag, error: e);
      return false;
    }
  }
}
