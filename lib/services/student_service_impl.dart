import '../constants/app_constants.dart';
import '../main.dart';
import 'base_service.dart';
import 'logger_service.dart';

/// StudentServiceImpl handles student-specific database operations
class StudentServiceImpl extends BaseService {
  static const String _tag = 'StudentServiceImpl';
  final _logger = LoggerService();

  /// Adds a student record to the database
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
      final userExists = await verifyUserExists(userId);
      if (!userExists) {
        _logger.warning(
            'User ID $userId does not exist in users table. Creating it now.',
            tag: _tag);

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
        final verifiedAgain = await verifyUserExists(userId);
        if (!verifiedAgain) {
          throw Exception('Failed to create user record in users table');
        }
      }

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

      _logger.info('Student record created successfully for ID: $studentId',
          tag: _tag);
      return {
        'success': true,
        'message': 'Student added successfully',
        'data': response
      };
    } catch (e, stackTrace) {
      _logger.error('Failed to create student record for ID: $studentId',
          tag: _tag, error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Failed to add student: ${e.toString()}',
      };
    }
  }

  /// Retrieves all students from the database
  Future<Map<String, dynamic>> getAllStudents() async {
    _logger.info('Retrieving all students', tag: _tag);
    try {
      // Query the users table for users with student role and join with students and departments
      final response = await supabase.from(AppConstants.tableUsers).select('''
            *,
            students (
              *,
              departments (
                name
              )
            )
          ''').eq('role', AppConstants.roleStudent).order('full_name');

      if (response.isEmpty) {
        _logger.warning('No students found in the database', tag: _tag);
        return {
          'success': true,
          'message': 'No students found',
          'data': [],
        };
      }

      _logger.info('Retrieved ${response.length} students from database',
          tag: _tag);

      // Process the response to ensure proper data structure
      final processedResponse = response.map((user) {
        // Safely access nested data with null checks
        final studentData = user['students'] as List<dynamic>?;
        final student =
            studentData?.isNotEmpty == true ? studentData!.first : null;
        final departmentData =
            student?['departments'] as Map<String, dynamic>? ?? {};

        return {
          'id': user['id']?.toString() ?? '',
          'student_id': student?['student_id']?.toString() ?? '',
          'name': user['full_name']?.toString() ?? 'Unknown',
          'email': user['email']?.toString() ?? '',
          'department': departmentData['name']?.toString() ?? 'Unknown',
          'enrollment_date': student?['enrollment_date']?.toString() ?? '',
          'academic_standing':
              student?['academic_standing']?.toString() ?? 'Unknown',
          'status': user['status']?.toString() ?? 'active',
        };
      }).toList();

      return {
        'success': true,
        'message': 'Students retrieved successfully',
        'data': processedResponse,
      };
    } catch (e, stackTrace) {
      _logger.error('Error retrieving students',
          tag: _tag, error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Failed to retrieve students: ${e.toString()}',
      };
    }
  }

  /// Gets a student by their ID
  Future<Map<String, dynamic>> getStudentById(String studentId) async {
    _logger.info('Retrieving student with ID: $studentId', tag: _tag);
    try {
      final response = await supabase
          .from(AppConstants.tableStudents)
          .select(
              '*, ${AppConstants.tableUsers}(full_name, email, role, status)')
          .eq('student_id', studentId)
          .single();

      return {
        'success': true,
        'message': 'Student retrieved successfully',
        'data': response,
      };
    } catch (e, stackTrace) {
      _logger.error('Failed to retrieve student with ID: $studentId',
          tag: _tag, error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Failed to retrieve student: ${e.toString()}',
      };
    }
  }

  /// Updates a student's information
  Future<Map<String, dynamic>> updateStudent({
    required String userId,
    String? address,
    Map<String, dynamic>? contactInfo,
    String? academicStanding,
    Map<String, dynamic>? preferences,
  }) async {
    _logger.info('Updating student with ID: $userId', tag: _tag);
    try {
      final Map<String, dynamic> updateData = {};

      if (address != null) updateData['address'] = address;
      if (contactInfo != null) updateData['contact_info'] = contactInfo;
      if (academicStanding != null) {
        updateData['academic_standing'] = academicStanding;
      }
      if (preferences != null) updateData['preferences'] = preferences;

      if (updateData.isEmpty) {
        return {
          'success': true,
          'message': 'No changes to update',
        };
      }
      await supabase
          .from(AppConstants.tableStudents)
          .update(updateData)
          .eq('id', userId.toString());

      return {
        'success': true,
        'message': 'Student updated successfully',
      };
    } catch (e, stackTrace) {
      _logger.error('Failed to update student with ID: $userId',
          tag: _tag, error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Failed to update student: ${e.toString()}',
      };
    }
  }

  /// Deletes a student
  Future<Map<String, dynamic>> deleteStudent(String userId) async {
    _logger.info('Deleting student with ID: $userId', tag: _tag);
    try {
      // First delete from students table
      await supabase
          .from(AppConstants.tableStudents)
          .delete()
          .eq('id', userId.toString());

      // Then delete from users table
      await supabase
          .from(AppConstants.tableUsers)
          .delete()
          .eq('id', userId.toString());

      return {
        'success': true,
        'message': 'Student deleted successfully',
      };
    } catch (e, stackTrace) {
      _logger.error('Failed to delete student with ID: $userId',
          tag: _tag, error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Failed to delete student: ${e.toString()}',
      };
    }
  }
}
