import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import 'package:logger/logger.dart';

class EnrollmentService {
  final _supabase = Supabase.instance.client;
  final _logger = Logger();

  // Get enrollments for a specific course
  Future<List<Map<String, dynamic>>> getCourseEnrollments(
      String courseId) async {
    try {
      final response = await _supabase.from('course_enrollments').select('''
            id,
            status,
            enrollment_date,
            final_grade,
            student:students!course_enrollments_student_id_fkey(
              student_id,
              user:users!students_id_fkey!inner(
                id,
                full_name,
                email
              )
            )
          ''').eq('course_id', courseId).order('enrollment_date');

      // Transform the response to match the expected format
      return List<Map<String, dynamic>>.from(response.map((enrollment) {
        final student = enrollment['student'];
        return {
          ...enrollment,
          'student': student == null
              ? null
              : {
                  'id': student['user']['id'],
                  'full_name': student['user']['full_name'],
                  'email': student['user']['email']
                }
        };
      }));
    } catch (e) {
      _logger.e('Error fetching course enrollments: $e');
      rethrow;
    }
  }

  // Get enrollments for a specific student
  Future<List<Map<String, dynamic>>> getStudentEnrollments(
      String studentId) async {
    try {
      final response = await _supabase
          .from('course_enrollments')
          .select('''
            id,
            status,
            enrollment_date,
            final_grade,
            course:course_id (
              id,
              title,
              instructor:instructor_id (
                id,
                full_name
              )
            )
          ''')
          .eq('student_id', studentId)
          .order('enrollment_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.e('Error fetching student enrollments: $e');
      rethrow;
    }
  }

  // Enroll a student in a course using the secure function
  Future<String> enrollStudent(String studentId, String courseId) async {
    try {
      final response = await _supabase.rpc('enroll_student', params: {
        'p_student_id': studentId,
        'p_course_id': courseId,
      });

      return response as String;
    } catch (e) {
      _logger.e('Error enrolling student: $e');
      rethrow;
    }
  }

  // Update enrollment status using the secure function
  Future<void> updateEnrollmentStatus(
      String enrollmentId, String status) async {
    try {
      await _supabase.rpc('update_enrollment_status', params: {
        'p_enrollment_id': enrollmentId,
        'p_status': status,
      });
    } catch (e) {
      _logger.e('Error updating enrollment status: $e');
      rethrow;
    }
  }

  // Update final grade (only available to teachers, admins, and supervisors)
  Future<void> updateFinalGrade(String enrollmentId, double grade) async {
    try {
      await _supabase
          .from('course_enrollments')
          .update({'final_grade': grade}).eq('id', enrollmentId);
    } catch (e) {
      _logger.e('Error updating final grade: $e');
      rethrow;
    }
  }

  // Get all available students that can be enrolled
  Future<List<Map<String, dynamic>>> getAvailableStudents() async {
    try {
      final response = await _supabase.from('users').select('''
            id,
            full_name,
            students!inner (
              student_id,
              department_id
            )
          ''').eq('role', AppConstants.roleStudent).eq('status', 'active');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.e('Error fetching available students: $e');
      rethrow;
    }
  }

  // Get all available courses that students can be enrolled in
  Future<List<Map<String, dynamic>>> getAvailableCourses() async {
    try {
      final response = await _supabase.from('courses').select('''
            id,
            title,
            department_id,
            instructor:teachers!courses_instructor_id_fkey(
              user:users!teachers_id_fkey!inner(
                id,
                full_name
              )
            )
          ''').eq('status', 'active').order('title');

      // Transform the response to match the expected format, handling possible null values
      return List<Map<String, dynamic>>.from(response.map((course) {
        final instructor = course['instructor'];
        return {
          ...course,
          'instructor': instructor == null
              ? null
              : {
                  'id': instructor['user']?['id'],
                  'full_name': instructor['user']?['full_name']
                }
        };
      }));
    } catch (e) {
      _logger.e('Error fetching available courses: $e');
      rethrow;
    }
  }

  // Create new enrollment
  Future<void> createEnrollment({
    required String studentId,
    required String courseId,
  }) async {
    try {
      // Use the secure enrollStudent function
      await enrollStudent(studentId, courseId);
    } catch (e) {
      _logger.e('Error creating enrollment: $e');
      rethrow;
    }
  }

  // Delete enrollment - remove a student from a course
  Future<Map<String, dynamic>> deleteEnrollment({
    required String enrollmentId,
    required String courseId,
    required String studentId,
  }) async {
    try {
      _logger.i(
          'Deleting enrollment $enrollmentId for student $studentId from course $courseId');

      // Option 1: Direct deletion using Supabase
      await _supabase
          .from('course_enrollments')
          .delete()
          .eq('id', enrollmentId);

      return {
        'success': true,
        'message': 'Student successfully unenrolled from course'
      };
    } catch (e) {
      _logger.e('Error deleting enrollment: $e');
      return {
        'success': false,
        'message': 'Error deleting enrollment: ${e.toString()}'
      };
    }
  }
}
