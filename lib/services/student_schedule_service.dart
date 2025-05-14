// filepath: c:\Users\Windows 10 PRO\Desktop\Fakulltet\Instanbul\Mobile Applications\project\zaimuniversity\lib\services\student_schedule_service.dart
import '../main.dart';
import '../constants/app_constants.dart';
import 'package:logging/logging.dart';

class StudentScheduleService {
  final Logger _logger = Logger('StudentScheduleService');

  /// Retrieves the current student's schedule organized by day
  Future<Map<String, List<Map<String, dynamic>>>> getStudentSchedule() async {
    try {
      // Get the current user's ID
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get student profile using user ID
      final studentProfileResponse = await supabase
          .from(AppConstants.tableStudents)
          .select('id')
          .eq('id', user.id);

      if (studentProfileResponse.isEmpty) {
        throw Exception('Student profile not found');
      }

      final studentId = studentProfileResponse[0]['id'];

      // Get course enrollments for this student
      final enrollmentsResponse = await supabase.rpc(
        'get_student_schedule',
        params: {'student_id': studentId},
      );

      // Organize by day of the week
      final weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];

      Map<String, List<Map<String, dynamic>>> scheduleMap = {};
      for (final day in weekdays) {
        scheduleMap[day] = [];
      }

      // Process the enrollments and extract schedule information
      for (final schedule in enrollmentsResponse) {
        final day = schedule['day_of_week'] ?? 'Unknown';
        if (scheduleMap.containsKey(day)) {
          scheduleMap[day]!.add({
            'course_title': schedule['course_title'] ?? 'Unnamed Course',
            'course_code': schedule['course_code'] ?? '',
            'start_time': schedule['start_time'] ?? '00:00',
            'end_time': schedule['end_time'] ?? '00:00',
            'room': schedule['room'] ?? 'TBA',
            'building': schedule['building'] ?? '',
            'teacher_name': schedule['teacher_name'] ?? 'Unassigned',
          });
        }
      }

      // Sort each day's schedule by start time
      scheduleMap.forEach((day, schedules) {
        schedules.sort((a, b) => a['start_time'].compareTo(b['start_time']));
      });

      return scheduleMap;
    } catch (e) {
      _logger.severe('Error retrieving student schedule', e);
      rethrow;
    }
  }

  /// Check if a course would conflict with the student's existing schedule
  Future<List<Map<String, dynamic>>> checkCourseConflicts(String courseId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final studentProfileResponse = await supabase
          .from(AppConstants.tableStudents)
          .select('id')
          .eq('id', user.id);

      if (studentProfileResponse.isEmpty) {
        throw Exception('Student profile not found');
      }

      final studentId = studentProfileResponse[0]['id'];

      // Check for schedule conflicts
      final conflictsResponse = await supabase.rpc(
        'check_student_schedule_conflicts',
        params: {
          'p_student_id': studentId,
          'p_potential_course_id': courseId,
        },
      );

      return conflictsResponse;
    } catch (e) {
      _logger.severe('Error checking course conflicts', e);
      rethrow;
    }
  }
}
