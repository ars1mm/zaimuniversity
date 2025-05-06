import 'package:logging/logging.dart';
import '../constants/app_constants.dart';
import '../main.dart';
import 'base_service.dart';
import 'role_service.dart';

/// CourseEnrollmentService handles operations related to course enrollments and materials
class CourseEnrollmentService extends BaseService {
  final _logger = Logger('CourseEnrollmentService');
  final RoleService _roleService = RoleService();

  /// Enrolls a student in a course
  Future<Map<String, dynamic>> enrollStudent({
    required String courseId,
    required String studentId,
  }) async {
    _logger.info('Enrolling student $studentId in course $courseId');

    try {
      // Check if already enrolled
      final existingEnrollment = await supabase
          .from(AppConstants.tableCourseEnrollments)
          .select()
          .eq('student_id', studentId)
          .eq('course_id', courseId)
          .maybeSingle();

      if (existingEnrollment != null) {
        _logger.warning('Student already enrolled in this course');
        return {
          'success': false,
          'message': 'Student is already enrolled in this course',
        };
      }

      // Create enrollment record
      final enrollmentData = {
        'student_id': studentId,
        'course_id': courseId,
        'enrollment_date': DateTime.now().toIso8601String(),
        'status': 'active',
      };

      final response = await supabase
          .from(AppConstants.tableCourseEnrollments)
          .insert(enrollmentData)
          .select()
          .single();

      _logger.info('Student successfully enrolled in course');

      return {
        'success': true,
        'message': 'Student enrolled successfully',
        'data': response,
      };
    } catch (e) {
      _logger.severe('Error enrolling student in course', e);
      return {
        'success': false,
        'message': 'Failed to enroll student: ${e.toString()}',
      };
    }
  }

  /// Gets all enrollments for a specific course
  Future<Map<String, dynamic>> getCourseEnrollments(String courseId) async {
    _logger.info('Fetching enrollments for course: $courseId');

    try {
      // Check if user has admin or teacher access
      final isAdmin = await _roleService.isAdmin();
      final isTeacher = await _roleService.isTeacher();

      if (!isAdmin && !isTeacher) {
        _logger.warning('Unauthorized attempt to fetch course enrollments');
        return {
          'success': false,
          'message': 'Unauthorized: Admin or teacher privileges required',
        };
      }

      final response = await supabase
          .from(AppConstants.tableCourseEnrollments)
          .select(
              '*, ${AppConstants.tableStudents}(student_id, ${AppConstants.tableUsers}(full_name, email))')
          .eq('course_id', courseId);

      if (response.isEmpty) {
        _logger.warning('No enrollments found for course: $courseId');
        return {
          'success': false,
          'message': 'No enrollments found for this course',
        };
      }

      _logger.info(
          'Retrieved ${response.length} enrollments for course: $courseId');

      return {
        'success': true,
        'message': 'Course enrollments retrieved successfully',
        'data': response,
      };
    } catch (e) {
      _logger.severe('Error fetching course enrollments', e);
      return {
        'success': false,
        'message': 'Failed to retrieve course enrollments: ${e.toString()}',
      };
    }
  }

  /// Gets all courses a student is enrolled in
  Future<Map<String, dynamic>> getStudentEnrollments(String studentId) async {
    _logger.info('Fetching enrollments for student: $studentId');

    try {
      final response = await supabase
          .from(AppConstants.tableCourseEnrollments)
          .select(
              '*, ${AppConstants.tableCourses}(title, description, schedule, semester, ${AppConstants.tableDepartments}(name))')
          .eq('student_id', studentId);

      if (response.isEmpty) {
        _logger.warning('No enrollments found for student: $studentId');
        return {
          'success': false,
          'message': 'No enrollments found for this student',
        };
      }

      _logger.info(
          'Retrieved ${response.length} enrollments for student: $studentId');

      return {
        'success': true,
        'message': 'Student enrollments retrieved successfully',
        'data': response,
      };
    } catch (e) {
      _logger.severe('Error fetching student enrollments', e);
      return {
        'success': false,
        'message': 'Failed to retrieve student enrollments: ${e.toString()}',
      };
    }
  }

  /// Adds course material
  Future<Map<String, dynamic>> addCourseMaterial({
    required String courseId,
    required String title,
    required String description,
    required String fileUrl,
    required String fileType,
  }) async {
    _logger.info('Adding material to course $courseId: $title');

    try {
      // Check if user has admin or teacher access
      final isAdmin = await _roleService.isAdmin();
      final isTeacher = await _roleService.isTeacher();

      if (!isAdmin && !isTeacher) {
        _logger.warning('Unauthorized attempt to add course material');
        return {
          'success': false,
          'message': 'Unauthorized: Admin or teacher privileges required',
        };
      }

      final materialData = {
        'course_id': courseId,
        'title': title,
        'description': description,
        'file_url': fileUrl,
        'file_type': fileType,
        'uploaded_by': auth.currentUser?.id,
        'uploaded_at': DateTime.now().toIso8601String(),
      };

      final response = await supabase
          .from(AppConstants.tableCourseMaterials)
          .insert(materialData)
          .select()
          .single();

      _logger.info('Course material added successfully');

      return {
        'success': true,
        'message': 'Course material added successfully',
        'data': response,
      };
    } catch (e) {
      _logger.severe('Error adding course material', e);
      return {
        'success': false,
        'message': 'Failed to add course material: ${e.toString()}',
      };
    }
  }

  /// Gets all materials for a course
  Future<Map<String, dynamic>> getCourseMaterials(String courseId) async {
    _logger.info('Fetching materials for course: $courseId');

    try {
      final response = await supabase
          .from(AppConstants.tableCourseMaterials)
          .select()
          .eq('course_id', courseId)
          .order('uploaded_at', ascending: false);

      if (response.isEmpty) {
        _logger.warning('No materials found for course: $courseId');
        return {
          'success': false,
          'message': 'No materials found for this course',
        };
      }

      _logger
          .info('Retrieved ${response.length} materials for course: $courseId');

      return {
        'success': true,
        'message': 'Course materials retrieved successfully',
        'data': response,
      };
    } catch (e) {
      _logger.severe('Error fetching course materials', e);
      return {
        'success': false,
        'message': 'Failed to retrieve course materials: ${e.toString()}',
      };
    }
  }

  /// Deletes a course material
  Future<Map<String, dynamic>> deleteCourseMaterial(String materialId) async {
    _logger.info('Deleting course material: $materialId');

    try {
      // Check if user has admin or teacher access
      final isAdmin = await _roleService.isAdmin();
      final isTeacher = await _roleService.isTeacher();

      if (!isAdmin && !isTeacher) {
        _logger.warning('Unauthorized attempt to delete course material');
        return {
          'success': false,
          'message': 'Unauthorized: Admin or teacher privileges required',
        };
      }
      await supabase
          .from(AppConstants.tableCourseMaterials)
          .delete()
          .eq('id', materialId.toString());

      _logger.info('Course material deleted successfully');

      return {
        'success': true,
        'message': 'Course material deleted successfully',
      };
    } catch (e) {
      _logger.severe('Error deleting course material', e);
      return {
        'success': false,
        'message': 'Failed to delete course material: ${e.toString()}',
      };
    }
  }
}
