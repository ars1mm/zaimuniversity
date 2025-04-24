import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import 'auth_service.dart';

class CourseService {
  final AuthService _authService = AuthService();
  final _supabase = Supabase.instance.client;
  final _logger = Logger('CourseService');

  /// Get all courses from the database
  Future<List<Map<String, dynamic>>> getCourses() async {
    _logger.info('Fetching all courses');

    try {
      // Check if user has admin access
      final isAdmin = await _authService.isAdmin();
      if (!isAdmin) {
        _logger.warning('Unauthorized attempt to fetch all courses');
        throw Exception('Unauthorized: Admin privileges required');
      }      // Fetch courses from Supabase with proper join
      final response = await _supabase
          .from('courses')
          .select('''
            *,
            departments (name)
          ''')
          .order('title');

      _logger.info('Retrieved ${response.length} courses from database');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.severe('Error retrieving courses', e);
      throw Exception('Failed to retrieve courses: ${e.toString()}');
    }
  }

  /// Add a new course
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
      final isAdmin = await _authService.isAdmin();
      if (!isAdmin) {
        _logger.warning('Unauthorized attempt to add course');
        return {
          'success': false,
          'message': 'Unauthorized: Admin privileges required',
        };
      }

      // Find or create department
      String departmentId;
      final departmentResponse = await _supabase
          .from('departments')
          .select('id')
          .eq('name', department)
          .maybeSingle();

      if (departmentResponse == null) {
        // Department doesn't exist, create it
        _logger.info('Department not found. Creating: $department');
        final newDept = await _supabase
            .from('departments')
            .insert({
              'name': department,
              'description': 'Department of $department',
            })
            .select('id')
            .single();
        departmentId = newDept['id'];
      } else {
        departmentId = departmentResponse['id'];
      } // Create course
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
        'created_by': _supabase.auth.currentUser?.id,
      };

      final response = await _supabase
          .from('courses')
          .insert(courseData)
          .select()
          .single();

      _logger.info('Course added successfully: ${response['id']}');

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

  /// Update an existing course
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
      final isAdmin = await _authService.isAdmin();
      if (!isAdmin) {
        _logger.warning('Unauthorized attempt to update course');
        return {
          'success': false,
          'message': 'Unauthorized: Admin privileges required',
        };
      }

      // Find or create department
      String departmentId;
      final departmentResponse = await _supabase
          .from('departments')
          .select('id')
          .eq('name', department)
          .maybeSingle();

      if (departmentResponse == null) {
        // Department doesn't exist, create it
        _logger.info('Department not found. Creating: $department');
        final newDept = await _supabase
            .from('departments')
            .insert({
              'name': department,
              'description': 'Department of $department',
            })
            .select('id')
            .single();
        departmentId = newDept['id'];
      } else {
        departmentId = departmentResponse['id'];
      } // Update course
      final courseData = {
        'title': title,
        'capacity': capacity,
        'department_id': departmentId,
        'instructor_id': instructorId,
        'description': description ?? '',
        'semester': semester ?? '',
        'status': status,
        'schedule': schedule,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('courses')
          .update(courseData)
          .eq('id', id);

      _logger.info('Course updated successfully: $id ($title)');

      return {
        'success': true,
        'message': 'Course updated successfully',
      };
    } catch (e) {
      _logger.severe('Error updating course', e);
      return {
        'success': false,
        'message': 'Failed to update course: ${e.toString()}',
      };
    }
  }

  /// Delete a course
  Future<Map<String, dynamic>> deleteCourse(String id) async {
    _logger.info('Deleting course ID: $id');

    try {
      // Check if user has admin access
      final isAdmin = await _authService.isAdmin();
      if (!isAdmin) {
        _logger.warning('Unauthorized attempt to delete course');
        return {
          'success': false,
          'message': 'Unauthorized: Admin privileges required',
        };
      }

      // Delete course
      await _supabase.from('courses').delete().eq('id', id);

      _logger.info('Course deleted successfully: $id');

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

  Future<List<Map<String, dynamic>>> getDepartments() async {
    try {
      _logger.info('Fetching departments');
      final response = await _supabase
          .from('departments')
          .select('id, name')
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.severe('Error fetching departments', e);
      throw Exception('Failed to fetch departments: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTeachers() async {
    try {
      _logger.info('Fetching teachers');
      final response = await _supabase
          .from('users')
          .select('id, name')
          .eq('role', 'teacher')
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.severe('Error fetching teachers', e);
      throw Exception('Failed to fetch teachers: $e');
    }
  }

  Future<void> createCourse({
    required String title,
    required String description,
    required int capacity,
    required String departmentId,
    required String instructorId,
  }) async {
    try {
      _logger.info('Creating new course: $title');
      await _supabase.from('courses').insert({
        'title': title,
        'description': description,
        'capacity': capacity,
        'department_id': departmentId,
        'instructor_id': instructorId,
        'status': 'active',
      });
      _logger.info('Course created successfully: $title');
    } catch (e) {
      _logger.severe('Error creating course', e);
      throw Exception('Failed to create course: $e');
    }
  }

  Future<void> updateCourseDetails({
    required String courseId,
    String? title,
    String? description,
    int? capacity,
    String? instructorId,
    String? status,
  }) async {
    try {
      _logger.info('Updating course: $courseId');
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (capacity != null) updates['capacity'] = capacity;
      if (instructorId != null) updates['instructor_id'] = instructorId;
      if (status != null) updates['status'] = status;

      await _supabase
          .from('courses')
          .update(updates)
          .eq('id', courseId);
      _logger.info('Course updated successfully: $courseId');
    } catch (e) {
      _logger.severe('Error updating course', e);
      throw Exception('Failed to update course: $e');
    }
  }

  Future<void> deleteCourseById(String courseId) async {
    try {
      _logger.info('Deleting course: $courseId');
      await _supabase
          .from('courses')
          .delete()
          .eq('id', courseId);
      _logger.info('Course deleted successfully: $courseId');
    } catch (e) {
      _logger.severe('Error deleting course', e);
      throw Exception('Failed to delete course: $e');
    }
  }
}
