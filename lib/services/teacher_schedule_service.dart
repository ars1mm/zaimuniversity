// filepath: c:\Users\Windows 10 PRO\Desktop\Fakulltet\Instanbul\Mobile Applications\project\zaimuniversity\lib\services\teacher_schedule_service.dart
import '../main.dart';
import '../constants/app_constants.dart';
import 'package:logging/logging.dart';
import '../services/auth_service.dart';

class TeacherScheduleService {
  final Logger _logger = Logger('TeacherScheduleService');
  final AuthService _authService = AuthService();

  /// Retrieves the current teacher's schedule organized by day
  Future<Map<String, List<Map<String, dynamic>>>> getTeacherSchedule() async {
    try {
      // Get the current user's ID
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get teacher profile using user ID
      final teacherProfileResponse = await supabase
          .from(AppConstants.tableTeachers)
          .select('id')
          .eq('id', user.id);

      if (teacherProfileResponse.isEmpty) {
        throw Exception('Teacher profile not found');
      }

      final teacherId = teacherProfileResponse[0]['id'];

      // Get courses taught by this teacher
      final scheduleResponse = await supabase
          .from('course_schedules')
          .select('''
            *,
            courses!course_id (
              id,
              title,
              description
            )
          ''')
          .eq('courses.instructor_id', teacherId);

      if (scheduleResponse.isEmpty) {
        return _createEmptySchedule();
      }

      // Organize by day of the week
      final Map<String, List<Map<String, dynamic>>> scheduleByDay =
          _organizeByDay(scheduleResponse);

      return scheduleByDay;
    } catch (e) {
      _logger.severe('Error retrieving teacher schedule', e);
      rethrow;
    }
  }

  /// Get all courses taught by the current teacher
  Future<List<Map<String, dynamic>>> getTeacherCourses() async {
    try {
      _logger.info('Fetching courses for teacher');
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get teacher profile using user ID
      final teacherProfileResponse = await supabase
          .from(AppConstants.tableTeachers)
          .select('id')
          .eq('id', user.id)
          .single();

      if (teacherProfileResponse == null) {
        throw Exception('Teacher profile not found');
      }

      final teacherId = teacherProfileResponse['id'];

      // Get courses where this teacher is the instructor
      final response = await supabase
          .from('courses')
          .select('id, title, description, credits')
          .eq('instructor_id', teacherId)
          .eq('status', 'active');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.severe('Error getting teacher courses', e);
      throw e;
    }
  }

  Map<String, List<Map<String, dynamic>>> _createEmptySchedule() {
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    
    Map<String, List<Map<String, dynamic>>> emptySchedule = {};
    for (var day in weekdays) {
      emptySchedule[day] = [];
    }
    
    return emptySchedule;
  }

  Map<String, List<Map<String, dynamic>>> _organizeByDay(
      List<Map<String, dynamic>> schedules) {
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    Map<String, List<Map<String, dynamic>>> scheduleByDay = {};
    for (var day in weekdays) {
      scheduleByDay[day] = [];
    }

    for (var schedule in schedules) {
      final day = schedule['day_of_week'] ?? 'Unknown';
      final course = schedule['courses'] ?? {};

      if (scheduleByDay.containsKey(day)) {
        scheduleByDay[day]!.add({
          'id': schedule['id'],
          'course_id': schedule['course_id'],
          'course_title': course['title'] ?? 'Unknown Course',
          'start_time': schedule['start_time'] ?? '00:00',
          'end_time': schedule['end_time'] ?? '00:00',
          'room': schedule['room'] ?? 'TBA',
          'building': schedule['building'] ?? '',
          'day_of_week': day,
        });
      }
    }

    // Sort each day's schedule by start time
    scheduleByDay.forEach((day, daySchedules) {
      daySchedules.sort((a, b) => 
        (a['start_time'] ?? '').compareTo(b['start_time'] ?? ''));
    });

    return scheduleByDay;
  }

  /// Creates a new schedule entry for a course
  Future<Map<String, dynamic>> addScheduleEntry({
    required String courseId,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    required String room,
    String? building,
  }) async {
    try {
      // Check if user has permission to create schedules
      final isAdmin = await _authService.isAdmin();
      final isSupervisor = await _authService.isSupervisor();
      
      if (!isAdmin && !isSupervisor) {
        _logger.warning('Unauthorized attempt to create schedule by regular teacher');
        return {
          'success': false,
          'message': 'You do not have permission to create or modify schedules'
        };
      }
      
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate teacher has rights to the course
      final teacherId = user.id;
      
      final courseCheck = await supabase
          .from('courses')
          .select('id')
          .eq('id', courseId)
          .eq('instructor_id', teacherId);

      if (courseCheck.isEmpty) {
        return {
          'success': false,
          'message': 'You do not have permission to schedule this course'
        };
      }

      // Check for scheduling conflicts
      final conflicts = await checkScheduleConflicts(
        courseId,
        dayOfWeek,
        startTime,
        endTime,
      );

      if (conflicts.isNotEmpty) {
        return {
          'success': false,
          'message': 'Schedule conflicts with existing course: ${conflicts[0]['course_title']}'
        };
      }

      // Insert the schedule directly with room and building
      await supabase.from('course_schedules').insert({
        'course_id': courseId,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'room': room,
        'building': building ?? '',
      });

      return {
        'success': true,
        'message': 'Schedule created successfully'
      };
    } catch (e) {
      _logger.severe('Error creating schedule entry', e);
      return {
        'success': false,
        'message': 'Error: ${e.toString()}'
      };
    }
  }

  /// Checks for scheduling conflicts
  Future<List<Map<String, dynamic>>> checkScheduleConflicts(
      String courseId, String dayOfWeek, String startTime, String endTime) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final teacherProfileResponse = await supabase
          .from(AppConstants.tableTeachers)
          .select('id')
          .eq('id', user.id);

      if (teacherProfileResponse.isEmpty) {
        throw Exception('Teacher profile not found');
      }

      final teacherId = teacherProfileResponse[0]['id'];

      // Get all courses for this teacher
      final courses = await supabase
          .from('courses')
          .select('id, title')
          .eq('instructor_id', teacherId);

      if (courses.isEmpty) {
        return [];
      }

      // Extract course IDs
      final courseIds = courses.map((c) => c['id']).toList();

      // Find any overlapping schedules on the same day
      final conflicts = await supabase.rpc(
        'check_teacher_schedule_conflicts',
        params: {
          'p_course_ids': courseIds,
          'p_day_of_week': dayOfWeek,
          'p_start_time': startTime,
          'p_end_time': endTime,
          'p_exclude_course_id': courseId,
        },
      );

      // Format the conflicts with course info
      List<Map<String, dynamic>> formattedConflicts = [];
      for (var conflict in conflicts) {
        final courseInfo = courses.firstWhere(
          (c) => c['id'] == conflict['course_id'],
          orElse: () => {'title': 'Unknown Course'},
        );

        formattedConflicts.add({
          'course_id': conflict['course_id'],
          'course_title': courseInfo['title'],
          'day_of_week': conflict['day_of_week'],
          'start_time': conflict['start_time'],
          'end_time': conflict['end_time'],
        });
      }

      return formattedConflicts;
    } catch (e) {
      _logger.severe('Error checking schedule conflicts', e);
      rethrow;
    }
  }

  Future<String?> _getTeacherId() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final teacherProfileResponse = await supabase
        .from(AppConstants.tableTeachers)
        .select('id')
        .eq('id', user.id);

    if (teacherProfileResponse.isEmpty) {
      return null;
    }

    return teacherProfileResponse[0]['id'];
  }
}

