import '../constants/app_constants.dart';
import '../main.dart';
import 'base_service.dart';
import 'logger_service.dart';

/// StudentServiceImpl handles student-specific database operations
class StudentServiceImpl extends BaseService {
  static const String _tag = 'StudentServiceImpl';

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
    LoggerService.info(_tag, 'Creating student record for: $name ($studentId)');
    try {
      // First, verify that the user record exists in the users table
      final userExists = await verifyUserExists(userId);
      if (!userExists) {
        LoggerService.warning(_tag,
            'User ID $userId does not exist in users table. Creating it now.');

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

  /// Retrieves all students from the database
  Future<Map<String, dynamic>> getAllStudents() async {
    LoggerService.info(_tag, 'Retrieving all students');
    try {
      // Query the users table to find all users with student role
      final usersResponse = await supabase
          .from(AppConstants.tableUsers)
          .select('id, full_name, email, role, status')
          .eq('role', AppConstants.roleStudent);
      LoggerService.info(
          _tag, 'Found ${usersResponse.length} users with student role');

      // No students found in users table
      if (usersResponse.isEmpty) {
        LoggerService.info(
            _tag, 'No users with student role found in users table.');
        return {'success': true, 'message': 'No students found', 'data': []};
      }

      // Process the student user data
      List<Map<String, dynamic>> studentRecords = [];

      // Convert each user record into a student record format
      for (var userRecord in usersResponse) {
        // Create a combined student record from user data
        Map<String, dynamic> studentRecord = {
          'id': userRecord['id'],
          'user': userRecord, // Include the full user record as a nested object
          'student_id': 'N/A', // Default values for student-specific fields
          'department_id': null,
          'address': null,
          'contact_info': {},
          'enrollment_date': null,
          'academic_standing': 'pending',
          'preferences': {},
        };

        // Add to our results
        studentRecords.add(studentRecord);
      }

      // Try to enhance records with data from students table (if it exists)
      try {
        // Get the list of user IDs with student role
        final studentUserIds =
            usersResponse.map((user) => user['id'].toString()).toList();

        // Log that we're checking the students table separately
        LoggerService.info(_tag,
            'Attempting to fetch additional student details from students table');

        // Query the students table for these IDs
        if (studentUserIds.isNotEmpty) {
          final studentsResponse = await supabase
              .from(AppConstants.tableStudents)
              .select('*')
              .inFilter('id', studentUserIds);

          if (studentsResponse.isNotEmpty) {
            LoggerService.info(_tag,
                'Found ${studentsResponse.length} student details records');

            // Create a map of student data by ID for easy lookup
            final studentDetailsMap = {
              for (var student in studentsResponse)
                student['id'].toString(): student
            };

            // Update our student records with details from students table
            for (int i = 0; i < studentRecords.length; i++) {
              final userId = studentRecords[i]['id'].toString();
              if (studentDetailsMap.containsKey(userId)) {
                // Merge in student table data
                final studentData = studentDetailsMap[userId]!;
                studentRecords[i] = {
                  ...studentRecords[i],
                  ...studentData,
                  // Keep the user field which has the user details
                  'user': studentRecords[i]['user'],
                };
              }
            }
          } else {
            LoggerService.info(
                _tag, 'No matching records found in students table');
          }
        }
      } catch (studentTableError) {
        // If there's an issue with the students table, just continue with the user data we have
        LoggerService.warning(_tag,
            'Error querying students table: ${studentTableError.toString()}');
      }

      LoggerService.info(
          _tag, 'Retrieved ${studentRecords.length} student records');
      return {
        'success': true,
        'message': 'Students retrieved successfully',
        'data': studentRecords
      };
    } catch (e) {
      LoggerService.error(_tag, 'Failed to retrieve students', e);
      return {
        'success': false,
        'message': 'Failed to retrieve students: ${e.toString()}',
      };
    }
  }

  /// Gets a student by their ID
  Future<Map<String, dynamic>> getStudentById(String studentId) async {
    LoggerService.info(_tag, 'Retrieving student with ID: $studentId');
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
    } catch (e) {
      LoggerService.error(
          _tag, 'Failed to retrieve student with ID: $studentId', e);
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
    LoggerService.info(_tag, 'Updating student with ID: $userId');
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
          .eq('id', userId);

      return {
        'success': true,
        'message': 'Student updated successfully',
      };
    } catch (e) {
      LoggerService.error(_tag, 'Failed to update student with ID: $userId', e);
      return {
        'success': false,
        'message': 'Failed to update student: ${e.toString()}',
      };
    }
  }

  /// Deletes a student
  Future<Map<String, dynamic>> deleteStudent(String userId) async {
    LoggerService.info(_tag, 'Deleting student with ID: $userId');
    try {
      // First delete from students table
      await supabase.from(AppConstants.tableStudents).delete().eq('id', userId);

      // Then delete from users table
      await supabase.from(AppConstants.tableUsers).delete().eq('id', userId);

      return {
        'success': true,
        'message': 'Student deleted successfully',
      };
    } catch (e) {
      LoggerService.error(_tag, 'Failed to delete student with ID: $userId', e);
      return {
        'success': false,
        'message': 'Failed to delete student: ${e.toString()}',
      };
    }
  }
}
