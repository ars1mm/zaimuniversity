import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:logging/logging.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/add_student_screen.dart';
import 'screens/course_management_screen.dart';
import 'screens/student_management_screen.dart';
import 'services/logger_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging first for better debugging during startup
  await LoggerService.init(
    logLevel: Level.ALL,
    enableFileLogging: true,
  );

  // final logger = LoggerService.getLogger('Main');

  // Try loading from multiple locations to handle the issue
  try {
    await dotenv.load(fileName: ".env");
    LoggerService.info('Main', 'Loaded .env file from root directory');
  } catch (e) {
    // If first attempt fails, try the alternate location
    try {
      await dotenv.load(fileName: "env/.env");
      LoggerService.info('Main', 'Loaded .env file from env/ directory');
    } catch (e) {
      LoggerService.error('Main', 'Error loading .env file', e);
    }
  }

  // Initialize Supabase client
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
    LoggerService.info('Main', 'Supabase initialized successfully');
  } catch (e) {
    LoggerService.error('Main', 'Failed to initialize Supabase', e);
  }

  runApp(const CampusInfoSystemApp());
}

// Provide global access to Supabase client
final supabase = Supabase.instance.client;

class CampusInfoSystemApp extends StatelessWidget {
  const CampusInfoSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Information System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/login': (context) => const LoginScreen(),
        '/admin': (context) => const AdminDashboard(),
        '/add_student': (context) => const AddStudentScreen(),
        '/manage_courses': (context) => const CourseManagementScreen(),
        StudentManagementScreen.routeName: (context) =>
            const StudentManagementScreen(),
      },
    );
  }
}
