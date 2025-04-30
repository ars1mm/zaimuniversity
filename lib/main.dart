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
import 'screens/assign_supervisor_screen.dart';
import 'screens/create_department_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/user_profile_management_screen.dart';
import 'screens/create_supervisor_screen.dart';
import './services/logger_service.dart';
import './utils/route_guard.dart';
import './constants/app_constants.dart';

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
        // Use RouteSettings to pass data to screens if needed
        switch (settings.name) {
          case '/':
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());

          // Admin-only routes
          case '/admin':
          case '/admin_dashboard':
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<Widget>(
                future: RouteGuard.protectRoute(
                  context: context,
                  targetWidget: const AdminDashboard(),
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
              ),
            );

          case '/assign_supervisor':
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<Widget>(
                future: RouteGuard.protectRoute(
                  context: context,
                  targetWidget: const AssignSupervisorScreen(),
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
                  targetWidget: const UserProfileManagementScreen(),
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

          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );
  }
}
