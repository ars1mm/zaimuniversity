import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/add_student_screen.dart';
import 'screens/add_teacher_screen.dart';
import 'screens/course_management_screen.dart';
import 'screens/student_management_screen.dart';
import 'screens/department_management_screen.dart';
import 'screens/teacher_management_screen.dart';
import 'screens/create_course_screen.dart';
import 'screens/create_department_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/create_supervisor_screen.dart';
import 'screens/teacher_schedule_screen.dart';
import 'screens/student_schedule_screen.dart';
import 'screens/teacher_course_screen.dart';
import 'screens/teacher_grades_screen.dart';
import 'package:zaimuniversity/screens/user_profile_management_screen.dart';
import 'screens/profile_management_screen.dart';
import './services/logger_service.dart';
import './utils/route_guard.dart';
import './constants/app_constants.dart';
import 'screens/supervisor_assignment_screen.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging first for better debugging during startup
  await LoggerService.init(
    logLevel: Level.ALL,
    enableFileLogging: true,
  );

  final logger = LoggerService.getLoggerForName('Main');

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    logger.info('Loaded .env file successfully');
  } catch (e) {
    logger.severe('Failed to load .env file', e);
    // Exit the app if environment variables cannot be loaded
    return;
  }

  // Validate required environment variables
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null ||
      supabaseUrl.isEmpty ||
      supabaseAnonKey == null ||
      supabaseAnonKey.isEmpty) {
    logger.severe(
        'Missing required environment variables: SUPABASE_URL or SUPABASE_ANON_KEY');
    return;
  }

  // Initialize Supabase client
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    logger.info('Supabase initialized successfully');
  } catch (e) {
    logger.severe('Failed to initialize Supabase', e);
    return;
  }

  runApp(const CampusInfoSystemApp());
}

// Provide global access to Supabase client
final supabase = Supabase.instance.client;
final auth = supabase.auth;

class CampusInfoSystemApp extends StatelessWidget {
  const CampusInfoSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Information System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Enhanced logging for route debugging
        print('DEBUG ROUTING: Requested route name is "${settings.name}"');
        print('DEBUG ROUTING: Route name type: ${settings.name.runtimeType}');

        // Use RouteSettings to pass data to screens if needed
        // Print all debug info for the route:
        print(
            'DEBUG: Teacher schedule route constant = ${TeacherScheduleScreen.routeName}');
        print('DEBUG: Current requested route = ${settings.name}');
        print(
            'DEBUG: Do they match? ${settings.name == TeacherScheduleScreen.routeName}');
        print(
            'DEBUG: Direct string comparison with "/teacher_schedule": ${settings.name == "/teacher_schedule"}');

        switch (settings.name) {
          case '/':
          case '/login':
            return MaterialPageRoute(
                builder: (_) => const LoginScreen()); // Admin-only routes
          case '/admin':
          case '/admin_dashboard':
            print('DEBUG ROUTING: Admin route requested');
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<Widget>(
                future: RouteGuard.protectRoute(
                  context: context,
                  targetWidget: const AdminDashboard(),
                  allowedRoles: AppConstants.adminRoles,
                ),
                builder: (context, snapshot) {
                  print(
                      'DEBUG ADMIN ROUTE: Future builder state = ${snapshot.connectionState}');
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                        body: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) {
                    print('DEBUG ADMIN ROUTE ERROR: ${snapshot.error}');
                  }
                  print(
                      'DEBUG ADMIN ROUTE: Returning widget = ${snapshot.data.runtimeType}');
                  return snapshot.data ?? const LoginScreen();
                },
              ),
            );

          case '/add_student':
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<Widget>(
                future: RouteGuard.protectRoute(
                  context: context,
                  targetWidget: const AddStudentScreen(),
                  allowedRoles: ['admin', 'supervisor'],
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                        body: Center(child: CircularProgressIndicator()));
                  }
                  return snapshot.data ?? const LoginScreen();
                },
              ),
            );

          case '/manage_courses':
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<Widget>(
                future: RouteGuard.protectRoute(
                  context: context,
                  targetWidget: const CourseManagementScreen(),
                  allowedRoles: ['admin', 'supervisor', 'teacher'],
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                        body: Center(child: CircularProgressIndicator()));
                  }
                  return snapshot.data ?? const LoginScreen();
                },
              ),
            );

          case '/create_course':
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<Widget>(
                future: RouteGuard.protectRoute(
                  context: context,
                  targetWidget: const CreateCourseScreen(),
                  allowedRoles: ['admin', 'supervisor', 'teacher'],
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                        body: Center(child: CircularProgressIndicator()));
                  }
                  return snapshot.data ?? const LoginScreen();
                },
              ),
            );
          case '/add_teacher':
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<Widget>(
                future: RouteGuard.protectRoute(
                  context: context,
                  targetWidget: const AddTeacherScreen(),
                  allowedRoles: AppConstants.adminRoles,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                        body: Center(child: CircularProgressIndicator()));
                  }
                  return snapshot.data ?? const LoginScreen();
                },
              ),
            );
          case '/manage_teachers':
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<Widget>(
                future: RouteGuard.protectRoute(
                  context: context,
                  targetWidget: const TeacherManagementScreen(),
                  allowedRoles: ['admin', 'supervisor'],
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                        body: Center(child: CircularProgressIndicator()));
                  }
                  return snapshot.data ?? const LoginScreen();
                },
              ),
            );

          case '/manage_departments':
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<Widget>(
                future: RouteGuard.protectRoute(
                  context: context,
                  targetWidget: const DepartmentManagementScreen(),
                  allowedRoles: ['admin'],
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                        body: Center(child: CircularProgressIndicator()));
                  }
                  return snapshot.data ?? const LoginScreen();
                },
              ),
            );

          case '/manage_students':
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<Widget>(
                future: RouteGuard.protectRoute(
                  context: context,
                  targetWidget: const StudentManagementScreen(),
                  allowedRoles: ['admin', 'supervisor'],
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                        body: Center(child: CircularProgressIndicator()));
                  }
                  return snapshot.data ?? const LoginScreen();
                },
              ),              );
          case SupervisorAssignmentScreen.routeName:
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<Widget>(
                future: RouteGuard.protectRoute(
                  context: context,
                  targetWidget: const SupervisorAssignmentScreen(),
                  allowedRoles: ['admin'],
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                        body: Center(child: CircularProgressIndicator()));
                  }
                  return snapshot.data ?? const LoginScreen();
                },
              ),
            );
          case '/create_department':
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<Widget>(
                future: RouteGuard.protectRoute(
                  context: context,
                  targetWidget: const CreateDepartmentScreen(),
                  allowedRoles: ['admin'],
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                        body: Center(child: CircularProgressIndicator()));
                  }
                  return snapshot.data ?? const LoginScreen();
                },
              ),
            );
          case '/profile':
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<Widget>(
                future: RouteGuard.protectRoute(
                  context: context,
                  targetWidget: const ProfileScreen(),
                  allowedRoles: ['admin', 'supervisor', 'teacher', 'student'],
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                        body: Center(child: CircularProgressIndicator()));
                  }
                  return snapshot.data ?? const LoginScreen();
                },
              ),
            );
          case '/manage_user_profiles':
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<Widget>(
                future: RouteGuard.protectRoute(
                  context: context,
                  targetWidget: UserProfileManagementScreen.create(),
                  allowedRoles: ['admin'],
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                        body: Center(child: CircularProgressIndicator()));
                  }
                  return snapshot.data ?? const LoginScreen();
                },
              ),
            );

          case ProfileManagementScreen.routeName:
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<Widget>(
                future: RouteGuard.protectRoute(
                  context: context,
                  targetWidget: const ProfileManagementScreen(),
                  allowedRoles: AppConstants.adminRoles,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                        body: Center(child: CircularProgressIndicator()));
                  }
                  return snapshot.data ?? const LoginScreen();
                },
              ),
            );
          case '/create_supervisor':
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<Widget>(
                future: RouteGuard.protectRoute(
                  context: context,
                  targetWidget: const CreateSupervisorScreen(),
                  allowedRoles: ['admin'],
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                        body: Center(child: CircularProgressIndicator()));
                  }
                  return snapshot.data ?? const LoginScreen();
                },
              ),
            );
          case '/teacher_schedule':
            // Add debug logs for teacher schedule route
            print('DEBUG: Entering teacher schedule route case');
            print(
                'DEBUG: Teacher roles from constants: ${AppConstants.roleTeacher}, ${AppConstants.roleAdmin}, ${AppConstants.roleSupervisor}');
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<Widget>(
                future: RouteGuard.protectRoute(
                  context: context,
                  targetWidget: const TeacherScheduleScreen(),
                  allowedRoles: [
                    AppConstants.roleTeacher,
                    AppConstants.roleSupervisor,
                    AppConstants.roleAdmin
                  ],
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                        body: Center(child: CircularProgressIndicator()));
                  }
                  return snapshot.data ?? const LoginScreen();
                },
              ),
            );
          case '/teacher_courses':
            // Add debug logs for teacher courses route
            print('DEBUG: Entering teacher courses route case');
            print(
                'DEBUG: Teacher roles from constants: ${AppConstants.roleTeacher}, ${AppConstants.roleSupervisor}, ${AppConstants.roleAdmin}');
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<Widget>(
                future: RouteGuard.protectRoute(
                  context: context,
                  targetWidget: const TeacherCourseScreen(),
                  allowedRoles: [
                    AppConstants.roleTeacher,
                    AppConstants.roleSupervisor,
                    AppConstants.roleAdmin
                  ],
                ),
                builder: (context, snapshot) {
                  print(
                      'DEBUG: Teacher courses FutureBuilder, snapshot state: ${snapshot.connectionState}');
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                        body: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) {
                    print(
                        'DEBUG: Error in teacher courses FutureBuilder: ${snapshot.error}');
                  }
                  print(
                      'DEBUG: Teacher courses widget to return: ${snapshot.data?.runtimeType ?? "LoginScreen (fallback)"}');
                  return snapshot.data ?? const LoginScreen();
                },
              ),
            );

          case '/teacher_grades':
            // Route for teacher grades functionality
            print('DEBUG: Entering teacher grades route case');
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<Widget>(
                future: RouteGuard.protectRoute(
                  context: context,
                  targetWidget: const TeacherGradesScreen(),
                  allowedRoles: [
                    AppConstants.roleTeacher,
                    AppConstants.roleSupervisor,
                    AppConstants.roleAdmin
                  ],
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                        body: Center(child: CircularProgressIndicator()));
                  }
                  return snapshot.data ?? const LoginScreen();
                },
              ),
            );

          case '/student_schedule':
            // Add debug logs for student schedule route
            print('DEBUG: Entering student schedule route case');
            print(
                'DEBUG: Student roles from constants: ${AppConstants.studentRoles}');
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<Widget>(
                future: RouteGuard.protectRoute(
                  context: context,
                  targetWidget: const StudentScheduleScreen(),
                  allowedRoles: AppConstants.studentRoles,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                        body: Center(child: CircularProgressIndicator()));
                  }
                  return snapshot.data ?? const LoginScreen();
                },
              ),
            );

          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );
  }
}
