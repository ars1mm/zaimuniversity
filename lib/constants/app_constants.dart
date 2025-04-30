import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // App Information
  static const String appName = 'Zaim University CIS';
  static const String appVersion = '1.0.0';

  // API Endpoints - Using environment variables
  static String get baseUrl =>
      dotenv.env['API_URL'] ??
      'https://uvurktstrcbcqzzuupeq.supabase.co/rest/v1';
  static String get loginEndpoint => '$baseUrl/auth/login';
  static String get coursesEndpoint => '$baseUrl/courses';
  static String get newsEndpoint => '$baseUrl/news';
  static String get addStudentEndpoint => '$baseUrl/students';

  // Supabase tables
  static const String tableUsers = 'users';
  static const String tableStudents = 'students';
  static const String tableTeachers = 'teachers';
  static const String tableCourses = 'courses';
  static const String tableDepartments = 'departments';
  static const String tableCourseEnrollments = 'course_enrollments';
  static const String tableCourseMaterials = 'course_materials';
  static const String tableHomeworkAssignments = 'homework_assignments';
  static const String tableHomeworkSubmissions = 'homework_submissions';
  static const String tableTranscripts = 'transcripts';
  static const String tableCourseApprovals = 'course_approvals';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double borderRadius = 8.0;

  // Shared Preferences Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleStudent = 'student';
  static const String roleFaculty = 'faculty';
  static const String roleStaff = 'staff';
  static const String roleSupervisor = 'supervisor';
  static const String roleTeacher = 'teacher';

  // Role Lists for Authorization
  static const List<String> adminRoles = ['admin'];
  static const List<String> teachingRoles = ['admin', 'teacher', 'supervisor'];
  static const List<String> managementRoles = ['admin', 'supervisor'];

  // Asset Paths
}
