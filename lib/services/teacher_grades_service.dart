import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import '../services/auth_service.dart';

class TeacherGradesService {
  final _supabase = Supabase.instance.client;
  final _logger = Logger('TeacherGradesService');
  final _authService = AuthService();

  // Get all courses taught by the current teacher
  Future<List<Map<String, dynamic>>> getTeacherCourses() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        throw Exception('Not authenticated');
      }

      final teacherId = user['id'];
      _logger.info('Fetching courses for teacher $teacherId');

      final courses = await _supabase
          .from('courses')
          .select('id, title, course_code, semester, status')
          .eq('instructor_id', teacherId)
          .order('title', ascending: true);

      _logger.info('Retrieved ${courses.length} courses for teacher');
      return List<Map<String, dynamic>>.from(courses);
    } catch (e) {
      _logger.severe('Error fetching teacher courses', e);
      throw Exception('Failed to fetch courses: $e');
    }
  }

  // Get all students enrolled in a specific course
  Future<List<Map<String, dynamic>>> getCourseStudents(String courseId) async {
    try {
      _logger.info('Fetching students for course $courseId');

      // Join course_enrollments with students and users to get comprehensive data
      final enrollments = await _supabase.from('course_enrollments').select('''
            id, 
            student_id, 
            status, 
            final_grade,
            students:student_id(
              id, 
              student_id,
              users:id(
                full_name, 
                email
              )
            )
          ''').eq('course_id', courseId).order('created_at');

      _logger.info('Retrieved ${enrollments.length} student enrollments');
      return List<Map<String, dynamic>>.from(enrollments);
    } catch (e) {
      _logger.severe('Error fetching course students', e);
      throw Exception('Failed to fetch students: $e');
    }
  }

  // Get all homework assignments for a course
  Future<List<Map<String, dynamic>>> getCourseHomeworkAssignments(
      String courseId) async {
    try {
      _logger.info('Fetching homework assignments for course $courseId');

      final assignments = await _supabase
          .from('homework_assignments')
          .select('id, title, due_date, total_points')
          .eq('course_id', courseId)
          .order('due_date');

      _logger.info('Retrieved ${assignments.length} homework assignments');
      return List<Map<String, dynamic>>.from(assignments);
    } catch (e) {
      _logger.severe('Error fetching homework assignments', e);
      throw Exception('Failed to fetch homework assignments: $e');
    }
  }

  // Get all exam scores for a student in a course
  Future<List<Map<String, dynamic>>> getStudentExamScores(
      String studentId, String courseId) async {
    try {
      _logger.info(
          'Fetching exam scores for student $studentId in course $courseId');

      // Get exam schedules for the course, then join with scores for this student
      final examScores = await _supabase
          .from('exams_schedule')
          .select('''
            id,
            exam_date,
            duration,
            exams_score!inner(
              id,
              score,
              graded_at
            )
          ''')
          .eq('course_id', courseId)
          .eq('exams_score.student_id', studentId);

      _logger.info('Retrieved ${examScores.length} exam scores');
      return List<Map<String, dynamic>>.from(examScores);
    } catch (e) {
      _logger.severe('Error fetching exam scores', e);
      throw Exception('Failed to fetch exam scores: $e');
    }
  }

  // Get all homework submissions for a student in a course
  Future<List<Map<String, dynamic>>> getStudentHomeworkSubmissions(
      String studentId, String courseId) async {
    try {
      _logger.info(
          'Fetching homework submissions for student $studentId in course $courseId');

      // Get homework assignments for the course, then join with submissions for this student
      final homeworkSubmissions = await _supabase
          .from('homework_assignments')
          .select('''
            id,
            title,
            due_date,
            total_points,
            homework_submissions!inner(
              id,
              score,
              submitted_at,
              feedback,
              graded_at
            )
          ''')
          .eq('course_id', courseId)
          .eq('homework_submissions.student_id', studentId);

      _logger
          .info('Retrieved ${homeworkSubmissions.length} homework submissions');
      return List<Map<String, dynamic>>.from(homeworkSubmissions);
    } catch (e) {
      _logger.severe('Error fetching homework submissions', e);
      throw Exception('Failed to fetch homework submissions: $e');
    }
  }

  // Update the final grade for a student's course enrollment
  Future<void> updateStudentFinalGrade(
      String enrollmentId, double finalGrade) async {
    try {
      _logger.info(
          'Updating final grade for enrollment $enrollmentId to $finalGrade');

      await _supabase.from('course_enrollments').update({
        'final_grade': finalGrade,
      }).eq('id', enrollmentId);

      _logger.info('Successfully updated final grade');
    } catch (e) {
      _logger.severe('Error updating final grade', e);
      throw Exception('Failed to update final grade: $e');
    }
  }

  // Update an exam score
  Future<void> updateExamScore(String examScoreId, double score) async {
    try {
      _logger.info('Updating exam score $examScoreId to $score');

      await _supabase.from('exams_score').update({
        'score': score,
        'graded_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', examScoreId);

      _logger.info('Successfully updated exam score');
    } catch (e) {
      _logger.severe('Error updating exam score', e);
      throw Exception('Failed to update exam score: $e');
    }
  }

  // Update a homework submission score and feedback
  Future<void> updateHomeworkSubmission(
      String submissionId, double score, String feedback) async {
    try {
      _logger.info(
          'Updating homework submission $submissionId to score: $score, feedback: $feedback');

      final user = await _authService.getCurrentUser();
      if (user == null) {
        throw Exception('Not authenticated');
      }

      await _supabase.from('homework_submissions').update({
        'score': score,
        'feedback': feedback,
        'graded_by': user['id'],
        'graded_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', submissionId);

      _logger.info('Successfully updated homework submission');
    } catch (e) {
      _logger.severe('Error updating homework submission', e);
      throw Exception('Failed to update homework submission: $e');
    }
  }
}
