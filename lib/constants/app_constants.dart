class AppConstants {
  // App Information
  static const String appName = 'Zaim University CIS';
  static const String appVersion = '1.0.0';

  // API Endpoints
  static const String baseUrl = 'https://api.izu.edu.tr/v1';
  static const String loginEndpoint = '$baseUrl/auth/login';
  static const String coursesEndpoint = '$baseUrl/courses';
  static const String newsEndpoint = '$baseUrl/news';
  static const String addStudentEndpoint = '$baseUrl/students';

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

  // Asset Paths
  static const String logoPath = 'assets/images/logo.png';
}
