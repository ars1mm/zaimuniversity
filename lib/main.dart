import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/add_student_screen.dart';
import 'screens/course_management_screen.dart';
import 'screens/student_management_screen.dart';
import 'screens/department_management_screen.dart';
import 'screens/teacher_management_screen.dart';
import 'services/logger_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging first for better debugging during startup
  await LoggerService.init(
    logLevel: Level.ALL,
    enableFileLogging: true,
  );

  final logger = LoggerService.getLogger('Main');

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

  if (supabaseUrl == null || supabaseUrl.isEmpty || 
      supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
    logger.severe('Missing required environment variables: SUPABASE_URL or SUPABASE_ANON_KEY');
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
      routes: {
        '/': (context) => const LoginScreen(),
        '/login': (context) => const LoginScreen(),
        '/admin': (context) => const AdminDashboard(),
        '/add_student': (context) => const AddStudentScreen(),
        '/manage_courses': (context) => const CourseManagementScreen(),
        DepartmentManagementScreen.routeName: (context) => const DepartmentManagementScreen(),
        TeacherManagementScreen.routeName: (context) => const TeacherManagementScreen(),
        StudentManagementScreen.routeName: (context) =>
            const StudentManagementScreen(),
      },
    );
  }
}
