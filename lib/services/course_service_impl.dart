import 'package:logging/logging.dart';
import '../constants/app_constants.dart';
import '../main.dart';
import 'base_service.dart';
import 'role_service.dart';

/// CourseServiceImpl handles course-related database operations
class CourseServiceImpl extends BaseService {
  final _logger = Logger('CourseServiceImpl');
  final RoleService _roleService = RoleService();

  /// Retrieves all courses from the database
  @override
  Future<List<Map<String, dynamic>>> getCourses() async {
    _logger.info('Fetching all courses');

    try {
      // Check if user has admin access
      final isAdmin = await _roleService.isAdmin();
      if (!isAdmin) {
        _logger.warning('Unauthorized attempt to fetch all courses');
        throw Exception('Unauthorized: Admin privileges required');
      }

      // Fetch courses from Supabase with proper join
      final response = await supabase.from('courses').select('''
            *,
            departments (name),
            users!instructor_id (name)
          ''').order('title');

      _logger.info('Retrieved ${response.length} courses from database');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.severe('Error retrieving courses', e);
      throw Exception('Failed to retrieve courses: ${e.toString()}');
    }
  }

  /// Adds a new course to the database
  Future<Map<String, dynamic>> addCourse({
    required String title,
    required int capacity,
    required String department,
    String? instructorId,
    String? description,
    String? semester,
    String status = 'active',
    Map<String, dynamic>? schedule,
  }) async {
    _logger.info('Adding course: $title');

    try {
      // Check if user has admin access
      final isAdmin = await _roleService.isAdmin();
      if (!isAdmin) {
        _logger.warning('Unauthorized attempt to add course');
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
        _logger.info('Department not found. Creating: $department');
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
        'title': title,
        'department_id': departmentId,
        'description': description ?? '',
        'capacity': capacity,
        'instructor_id': instructorId,
        'schedule': schedule ?? {},
        'semester': semester ?? '',
        'status': status,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'created_by': supabase.auth.currentUser?.id,
      };

      final response = await supabase
          .from(AppConstants.tableCourses)
          .insert(courseData)
          .select()
          .single();

      _logger.info('Course added successfully: $title');

      return {
        'success': true,
        'message': 'Course added successfully',
        'data': response,
      };
    } catch (e) {
      _logger.severe('Error adding course', e);
      return {
        'success': false,
        'message': 'Failed to add course: ${e.toString()}',
      };
    }
  }

  /// Updates an existing course
  Future<Map<String, dynamic>> updateCourse({
    required String id,
    required String title,
    required int capacity,
    required String department,
    String? instructorId,
    String? description,
    String? semester,
    String status = 'active',
    Map<String, dynamic>? schedule,
  }) async {
    _logger.info('Updating course ID: $id ($title)');

    try {
      // Check if user has admin access
      final isAdmin = await _roleService.isAdmin();
      if (!isAdmin) {
        _logger.warning('Unauthorized attempt to update course');
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
        _logger.info('Department not found. Creating: $department');
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
        'title': title,
        'department_id': departmentId,
        'description': description ?? '',
        'capacity': capacity,
        'instructor_id': instructorId,
        'schedule': schedule ?? {},
        'semester': semester ?? '',
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await supabase
          .from(AppConstants.tableCourses)
          .update(courseData)
          .eq('id', id.toString())
          .select()
          .single();

      _logger.info('Course updated successfully: $title');

      return {
        'success': true,
        'message': 'Course updated successfully',
        'data': response,
      };
    } catch (e) {
      _logger.severe('Error updating course', e);
      return {
        'success': false,
        'message': 'Failed to update course: ${e.toString()}',
      };
    }
  }

  /// Deletes a course by its ID
  Future<Map<String, dynamic>> deleteCourse(String courseId) async {
    _logger.info('Deleting course with ID: $courseId');

    try {
      // Check if user has admin access
      final isAdmin = await _roleService.isAdmin();
      if (!isAdmin) {
        _logger.warning('Unauthorized attempt to delete course');
        return {
          'success': false,
          'message': 'Unauthorized: Admin privileges required',
        };
      }
      await supabase
          .from(AppConstants.tableCourses)
          .delete()
          .eq('id', courseId.toString());

      _logger.info('Course deleted successfully');

      return {
        'success': true,
        'message': 'Course deleted successfully',
      };
    } catch (e) {
      _logger.severe('Error deleting course', e);
      return {
        'success': false,
        'message': 'Failed to delete course: ${e.toString()}',
      };
    }
  }

  /// Gets course by ID
  Future<Map<String, dynamic>> getCourseById(String courseId) async {
    _logger.info('Fetching course with ID: $courseId');

    try {
      final response = await supabase
          .from(AppConstants.tableCourses)
          .select('*, ${AppConstants.tableDepartments}(name)')
          .eq('id', courseId.toString())
          .single();

      return {
        'success': true,
        'message': 'Course retrieved successfully',
        'data': response,
      };
    } catch (e) {
      _logger.severe('Error retrieving course with ID: $courseId', e);
      return {
        'success': false,
        'message': 'Failed to retrieve course: ${e.toString()}',
      };
    }
  }
}
