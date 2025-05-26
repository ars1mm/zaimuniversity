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
      final isAdmin = await _authService
          .isAdmin(); // For admin users, fetch all courses with additional data
      if (isAdmin) {
        final response = await _supabase.from('courses').select('''
            *,
            departments (id, name)
          ''').order('title'); // Process the response to ensure department data is correctly structured
        final courses = List<Map<String, dynamic>>.from(response).map((course) {
          // Use our utility method to extract department data safely
          final departmentsMap = extractDepartmentData(course['departments']);

          return {
            ...course,
            'departments': departmentsMap,
          };
        }).toList();

        _logger.info(
            'Retrieved ${courses.length} courses from database (admin view)');
        return courses;
      }
      // For non-admin users, fetch only basic course data that everyone can access
      else {
        final user = _supabase.auth.currentUser;
        if (user == null) {
          throw Exception('User not authenticated');
        }

        // Get the user's role
        final userRole = await _authService.getUserRole();
        if (userRole == 'teacher') {
          // Teachers can only see their own courses
          final response = await _supabase.from('courses').select('''
              id, title, department_id, 
              departments (id, name)
            ''').eq('instructor_id', user.id).order('title');

          // Process the response to ensure department data is correctly structured
          final courses =
              List<Map<String, dynamic>>.from(response).map((course) {
            // Use our utility method to extract department data safely
            final departmentsMap = extractDepartmentData(course['departments']);

            return {
              ...course,
              'departments': departmentsMap,
            };
          }).toList();

          _logger.info('Retrieved ${courses.length} courses for teacher');
          return courses;
        } else {
          // Student or other non-admin user - show active courses only
          final response = await _supabase.from('courses').select('''
              id, title, department_id,
              departments (id, name)
            ''').eq('status', 'active').order('title');

          // Process the response to ensure department data is correctly structured
          final courses =
              List<Map<String, dynamic>>.from(response).map((course) {
            // Use our utility method to extract department data safely
            final departmentsMap = extractDepartmentData(course['departments']);

            return {
              ...course,
              'departments': departmentsMap,
            };
          }).toList();

          _logger.info(
              'Retrieved ${courses.length} active courses for non-admin user');
          return courses;
        }
      }
    } catch (e) {
      _logger.severe('Error retrieving courses', e);
      throw Exception('Failed to retrieve courses: ${e.toString()}');
    }
  }

  /// Get all courses (admin view)
  Future<List<Map<String, dynamic>>> getAllCourses() async {
    _logger.info('Fetching all courses for admin');

    try {
      // Get all courses with their instructors' information
      final response = await _supabase.from('courses').select('''
          id,
          title,
          course_code,
          department_id,
          instructor_id,
          departments (name)
        ''').order('title');

      // Fetch instructor names in a separate query - using dynamic type to handle JSON properly
      final instructorIds = List<Map<String, dynamic>>.from(response)
          .map((course) => course['instructor_id']
              ?.toString()) // Convert to String explicitly
          .where((id) => id != null)
          .toSet()
          .toList();

      // Create map of instructor IDs to names
      Map<String, String> instructorNames = {};
      if (instructorIds.isNotEmpty) {
        final instructorList = await _supabase
            .from('users')
            .select('id, full_name')
            .filter('id', 'in', instructorIds);

        for (var instructor in instructorList) {
          instructorNames[instructor['id']] = instructor['full_name'];
        }
      } // Transform the response to include instructor name and properly handle department data
      final courses = response.map((course) {
        final instructorId = course['instructor_id']?.toString();

        // Process departments data safely
        final departmentsMap = extractDepartmentData(course['departments']);

        return {
          ...course,
          'departments': departmentsMap,
          'instructor_name':
              instructorId != null && instructorNames.containsKey(instructorId)
                  ? instructorNames[instructorId]
                  : 'No instructor'
        };
      }).toList();

      _logger.info('Retrieved ${courses.length} courses from database');
      return courses;
    } catch (e) {
      _logger.severe('Error fetching all courses: $e');
      throw Exception('Error fetching courses: $e');
    }
  }

  /// Get courses where the current user is enrolled
  Future<List<Map<String, dynamic>>> getEnrolledCourses() async {
    _logger.info('Fetching enrolled courses for current student');

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.from('course_enrollments').select('''
          course:course_id (
            id,
            title,
            course_code,
            instructor_id
          )
        ''').eq('student_id', user.id).eq('status', 'active');

      // Get all the courses from the enrollments
      final coursesList = response
          .map((enrollment) => enrollment['course'] as Map<String, dynamic>)
          .toList(); // Get instructor IDs from the courses, converting to string to ensure type safety
      final instructorIds = coursesList
          .map((course) => course['instructor_id']?.toString())
          .where((id) => id != null)
          .toSet()
          .toList();

      // Create map of instructor IDs to names
      Map<String, String> instructorNames = {};
      if (instructorIds.isNotEmpty) {
        final instructorList = await _supabase
            .from('users')
            .select('id, full_name')
            .filter('id', 'in', instructorIds);

        for (var instructor in instructorList) {
          instructorNames[instructor['id']] = instructor['full_name'];
        }
      } // Add instructor names to courses
      final courses = coursesList.map((courseData) {
        final instructorId = courseData['instructor_id']?.toString();

        return {
          ...courseData,
          'instructor_name':
              instructorId != null && instructorNames.containsKey(instructorId)
                  ? instructorNames[instructorId]
                  : 'No instructor'
        };
      }).toList();

      _logger.info('Retrieved ${courses.length} enrolled courses for student');
      return courses;
    } catch (e) {
      _logger.severe('Error fetching enrolled courses: $e');
      throw Exception('Error fetching enrolled courses: $e');
    }
  }

  /// Get courses taught by the current teacher
  Future<List<Map<String, dynamic>>> getTeacherCourses() async {
    _logger.info('Fetching courses taught by current teacher');

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.from('courses').select('''
          id,
          title,
          course_code,
          department_id,
          departments (name)
        ''').eq('instructor_id', user.id);

      // Since these are the teacher's own courses, we can use their name directly
      String teacherName = '';
      try {
        final userData = await _supabase
            .from('users')
            .select('full_name')
            .eq('id', user.id)
            .single();
        teacherName = userData['full_name'] ?? 'Teacher';
      } catch (e) {
        teacherName = 'Teacher';
      } // Transform the response to include instructor name and properly handle departments
      final courses = response.map((course) {
        // Process departments data safely
        final departmentsMap = extractDepartmentData(course['departments']);

        return {
          ...course,
          'departments': departmentsMap,
          'instructor_name': teacherName
        };
      }).toList();

      _logger.info('Retrieved ${courses.length} courses taught by teacher');
      return courses;
    } catch (e) {
      _logger.severe('Error fetching teacher courses: $e');
      throw Exception('Error fetching courses: $e');
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

      final response =
          await _supabase.from('courses').insert(courseData).select().single();

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
          .eq('id', id.toString());

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
      } // Delete course
      await _supabase.from('courses').delete().eq('id', id.toString());

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
      final response =
          await _supabase.from('departments').select('id, name').order('name');

      _logger.info('Received departments response: $response');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.severe('Error fetching departments', e);
      throw Exception('Failed to fetch departments: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTeachers() async {
    try {
      _logger.info('Fetching teachers');
      // Join with users table to get more information about teachers
      final response = await _supabase
          .from('users')
          .select('id, full_name')
          .eq('role', 'teacher')
          .order('full_name');

      _logger.info('Retrieved ${response.length} teachers');
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
          .eq('id', courseId.toString());
      _logger.info('Course updated successfully: $courseId');
    } catch (e) {
      _logger.severe('Error updating course', e);
      throw Exception('Failed to update course: $e');
    }
  }

  Future<void> deleteCourseById(String courseId) async {
    try {
      _logger.info('Deleting course: $courseId');
      await _supabase.from('courses').delete().eq('id', courseId.toString());
      _logger.info('Course deleted successfully: $courseId');
    } catch (e) {
      _logger.severe('Error deleting course', e);
      throw Exception('Failed to delete course: $e');
    }
  }

  /// Check if the current user is the instructor for a specific course
  Future<bool> isInstructorForCourse(String courseId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      final response = await _supabase
          .from('courses')
          .select('id')
          .eq('id', courseId)
          .eq('instructor_id', user.id)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      _logger.severe('Error checking if user is instructor for course', e);
      return false;
    }
  }

  /// Remove a student from a course (unenroll)
  Future<Map<String, dynamic>> removeStudentFromCourse({
    required String courseId,
    required String studentId,
  }) async {
    _logger.info('Removing student $studentId from course $courseId');

    try {
      // Check if user has appropriate permissions
      final isAdmin = await _authService.isAdmin();
      final user = _supabase.auth.currentUser;
      final isInstructor =
          user != null && await isInstructorForCourse(courseId);

      // Only admin or the course instructor can remove students
      if (!isAdmin && !isInstructor) {
        _logger.warning('Unauthorized attempt to remove student from course');
        return {
          'success': false,
          'message': 'Unauthorized: Admin or instructor privileges required',
        };
      }

      // Check if the enrollment exists
      final enrollmentCheck = await _supabase
          .from('course_enrollments')
          .select('id')
          .eq('course_id', courseId)
          .eq('student_id', studentId)
          .maybeSingle();

      if (enrollmentCheck == null) {
        return {
          'success': false,
          'message': 'Student is not enrolled in this course',
        };
      }

      // Remove the enrollment (we can either delete it or set status to 'removed')
      await _supabase
          .from('course_enrollments')
          .delete()
          .eq('course_id', courseId)
          .eq('student_id', studentId);

      _logger.info('Student successfully removed from course');
      return {
        'success': true,
        'message': 'Student successfully removed from the course',
      };
    } catch (e) {
      _logger.severe('Error removing student from course', e);
      return {
        'success': false,
        'message': 'Failed to remove student: ${e.toString()}',
      };
    }
  }

  /// Get all students enrolled in a specific course
  Future<List<Map<String, dynamic>>> getEnrolledStudents(
      String courseId) async {
    _logger.info('Fetching enrolled students for course ID: $courseId');

    try {
      // Check if user has admin or teacher access to this course
      final isAdmin = await _authService.isAdmin();
      final isInstructor = await isInstructorForCourse(courseId);

      if (!isAdmin && !isInstructor) {
        _logger.warning('Unauthorized attempt to view course enrollments');
        throw Exception(
            'Unauthorized: Admin or instructor privileges required');
      }

      // Get enrollments with student information
      final response = await _supabase.from('course_enrollments').select('''
          id,
          enrollment_date,
          status,
          student:student_id (
            id, 
            full_name,
            email
          )
        ''').eq('course_id', courseId);

      // Transform the response to a more usable format
      final enrollments =
          List<Map<String, dynamic>>.from(response).map((enrollment) {
        final student = enrollment['student'] as Map<String, dynamic>;

        return {
          'id': enrollment['id'],
          'enrollment_id': enrollment['id'],
          'enrollment_date': enrollment['enrollment_date'],
          'status': enrollment['status'],
          'student_id': student['id'],
          'student_name': student['full_name'],
          'student_email': student['email'],
        };
      }).toList();

      _logger.info(
          'Retrieved ${enrollments.length} enrolled students for course $courseId');
      return enrollments;
    } catch (e) {
      _logger.severe('Error fetching enrolled students', e);
      throw Exception('Failed to fetch enrolled students: ${e.toString()}');
    }
  }

  /// Safely extracts department data from various formats
  Map<String, dynamic> extractDepartmentData(dynamic departments) {
    Map<String, dynamic> departmentsMap = {};

    if (departments != null) {
      if (departments is Map) {
        departmentsMap = Map<String, dynamic>.from(departments);
      } else if (departments is Function) {
        try {
          final result = departments();
          if (result is Map) {
            departmentsMap = Map<String, dynamic>.from(result);
          }
        } catch (e) {
          _logger.warning('Error calling department function: $e');
          // Function call failed, keep empty map
        }
      }
    }

    return departmentsMap;
  }
}
