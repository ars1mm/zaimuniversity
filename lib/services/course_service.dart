import '../constants/app_constants.dart';
import '../main.dart';
import 'auth_service.dart';
import 'logger_service.dart';

class CourseService {
  final AuthService _authService = AuthService();
  static const String _tag = 'CourseService';

  /// Get all courses from the database
  Future<Map<String, dynamic>> getAllCourses() async {
    LoggerService.info(_tag, 'Fetching all courses');

    try {
      // Check if user has admin access
      final isAdmin = await _authService.isAdmin();
      if (!isAdmin) {
        LoggerService.warning(
            _tag, 'Unauthorized attempt to fetch all courses');
        return {
          'success': false,
          'message': 'Unauthorized: Admin privileges required',
        };
      }

      // Fetch courses from Supabase
      final response = await supabase
          .from(AppConstants.tableCourses)
          .select('*, ${AppConstants.tableDepartments}(name)')
          .order('code');

      LoggerService.info(
          _tag, 'Retrieved ${response.length} courses from database');

      return {
        'success': true,
        'message': 'Courses retrieved successfully',
        'data': response,
      };
    } catch (e) {
      LoggerService.error(_tag, 'Error retrieving courses', e);
      return {
        'success': false,
        'message': 'Failed to retrieve courses: ${e.toString()}',
      };
    }
  }

  /// Add a new course
  Future<Map<String, dynamic>> addCourse({
    required String name,
    required String code,
    required int credits,
    required String department,
    String? description,
    bool active = true,
  }) async {
    LoggerService.info(_tag, 'Adding course: $name ($code)');

    try {
      // Check if user has admin access
      final isAdmin = await _authService.isAdmin();
      if (!isAdmin) {
        LoggerService.warning(_tag, 'Unauthorized attempt to add course');
        return {
          'success': false,
          'message': 'Unauthorized: Admin privileges required',
        };
      }

      // Find or create department
      String departmentId;
      final departmentResponse = await supabase
          .from(AppConstants.tableDepartments)
          .select('id')
          .eq('name', department)
          .maybeSingle();

      if (departmentResponse == null) {
        // Department doesn't exist, create it
        LoggerService.info(_tag, 'Department not found. Creating: $department');
        final newDept = await supabase
            .from(AppConstants.tableDepartments)
            .insert({
              'name': department,
              'description': 'Department of $department',
            })
            .select('id')
            .single();
        departmentId = newDept['id'];
      } else {
        departmentId = departmentResponse['id'];
      }

      // Create course
      final courseData = {
        'name': name,
        'code': code,
        'credits': credits,
        'department_id': departmentId,
        'description': description ?? '',
        'active': active,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await supabase
          .from(AppConstants.tableCourses)
          .insert(courseData)
          .select()
          .single();

      LoggerService.info(_tag, 'Course added successfully: $code');

      return {
        'success': true,
        'message': 'Course added successfully',
        'data': response,
      };
    } catch (e) {
      LoggerService.error(_tag, 'Error adding course', e);
      return {
        'success': false,
        'message': 'Failed to add course: ${e.toString()}',
      };
    }
  }

  /// Update an existing course
  Future<Map<String, dynamic>> updateCourse({
    required String id,
    required String name,
    required String code,
    required int credits,
    required String department,
    String? description,
    required bool active,
  }) async {
    LoggerService.info(_tag, 'Updating course ID: $id ($code)');

    try {
      // Check if user has admin access
      final isAdmin = await _authService.isAdmin();
      if (!isAdmin) {
        LoggerService.warning(_tag, 'Unauthorized attempt to update course');
        return {
          'success': false,
          'message': 'Unauthorized: Admin privileges required',
        };
      }

      // Find or create department
      String departmentId;
      final departmentResponse = await supabase
          .from(AppConstants.tableDepartments)
          .select('id')
          .eq('name', department)
          .maybeSingle();

      if (departmentResponse == null) {
        // Department doesn't exist, create it
        LoggerService.info(_tag, 'Department not found. Creating: $department');
        final newDept = await supabase
            .from(AppConstants.tableDepartments)
            .insert({
              'name': department,
              'description': 'Department of $department',
            })
            .select('id')
            .single();
        departmentId = newDept['id'];
      } else {
        departmentId = departmentResponse['id'];
      }

      // Update course
      final courseData = {
        'name': name,
        'code': code,
        'credits': credits,
        'department_id': departmentId,
        'description': description ?? '',
        'active': active,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase
          .from(AppConstants.tableCourses)
          .update(courseData)
          .eq('id', id);

      LoggerService.info(_tag, 'Course updated successfully: $code');

      return {
        'success': true,
        'message': 'Course updated successfully',
      };
    } catch (e) {
      LoggerService.error(_tag, 'Error updating course', e);
      return {
        'success': false,
        'message': 'Failed to update course: ${e.toString()}',
      };
    }
  }

  /// Delete a course
  Future<Map<String, dynamic>> deleteCourse(String id) async {
    LoggerService.info(_tag, 'Deleting course ID: $id');

    try {
      // Check if user has admin access
      final isAdmin = await _authService.isAdmin();
      if (!isAdmin) {
        LoggerService.warning(_tag, 'Unauthorized attempt to delete course');
        return {
          'success': false,
          'message': 'Unauthorized: Admin privileges required',
        };
      }

      // Delete course
      await supabase.from(AppConstants.tableCourses).delete().eq('id', id);

      LoggerService.info(_tag, 'Course deleted successfully: $id');

      return {
        'success': true,
        'message': 'Course deleted successfully',
      };
    } catch (e) {
      LoggerService.error(_tag, 'Error deleting course', e);
      return {
        'success': false,
        'message': 'Failed to delete course: ${e.toString()}',
      };
    }
  }
}
