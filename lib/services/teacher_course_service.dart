import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import '../main.dart';
import '../constants/app_constants.dart';
import 'base_service.dart';

/// Service for teacher-specific course operations
class TeacherCourseService extends BaseService {
  final _logger = Logger('TeacherCourseService');

  /// Get courses taught by the current teacher
  Future<List<Map<String, dynamic>>> getTeacherCourses() async {
    try {
      _logger.info('Fetching courses for teacher');
      
      // Get current user
      final user = supabase.auth.currentUser;
      if (user == null) {
        _logger.severe('User not authenticated');
        throw Exception('User not authenticated');
      }

      _logger.info('Current user ID: ${user.id}');
      _logger.info('User email: ${user.email}');

      // Query courses directly with a join to departments
      _logger.info('Querying courses with instructor_id = ${user.id}');
      final response = await supabase
          .from('courses')
          .select('''
            *,
            departments (
              id, 
              name
            )
          ''')
          .eq('instructor_id', user.id)
          .order('title');

      _logger.info('Retrieved ${response.length} courses for teacher');
      
      // Log the retrieved courses for debugging
      if (response.isEmpty) {
        _logger.warning('No courses found for teacher');
      } else {
        _logger.info('First course title: ${response[0]['title']}');
      }
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.severe('Error retrieving teacher courses', e);
      throw Exception('Failed to retrieve courses: ${e.toString()}');
    }
  }

  /// Update a course taught by the current teacher
  Future<Map<String, dynamic>> updateCourse({
    required String id,
    required String title,
    String? description,
    Map<String, dynamic>? schedule,
  }) async {
    try {
      _logger.info('Teacher updating course: $id');
      
      // Get current user
      final user = supabase.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      // Verify teacher owns this course
      final courseCheck = await supabase
          .from('courses')
          .select('id')
          .eq('id', id)
          .eq('instructor_id', user.id)
          .maybeSingle();

      if (courseCheck == null) {
        _logger.warning('Teacher attempted to update course they do not own');
        return {
          'success': false,
          'message': 'You can only update courses you teach',
        };
      }

      // Update course with limited fields that teachers can modify
      await supabase
          .from('courses')
          .update({
            'title': title,
            'description': description ?? '',
            'schedule': schedule ?? {},
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      _logger.info('Course updated successfully by teacher: $id');
      return {
        'success': true,
        'message': 'Course updated successfully',
      };
    } catch (e) {
      _logger.severe('Error updating course by teacher', e);
      return {
        'success': false,
        'message': 'Failed to update course: ${e.toString()}',
      };
    }
  }

  /// Get information about a specific course
  Future<Map<String, dynamic>?> getCourseDetails(String courseId) async {
    try {
      _logger.info('Fetching course details for ID: $courseId');
      
      // Get current user
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Query the course with proper joins
      final response = await supabase
          .from('courses')
          .select('''
            *,
            departments (
              id, 
              name
            )
          ''')
          .eq('id', courseId)
          .eq('instructor_id', user.id)
          .maybeSingle();

      if (response == null) {
        _logger.warning('Course not found or teacher does not have access');
        return null;
      }

      _logger.info('Retrieved course details for ID: $courseId');
      return response;
    } catch (e) {
      _logger.severe('Error retrieving course details', e);
      throw Exception('Failed to retrieve course details: ${e.toString()}');
    }
  }
} 