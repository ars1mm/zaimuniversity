import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try loading from multiple locations to handle the issue
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // If first attempt fails, try the alternate location
    try {
      await dotenv.load(fileName: "env/.env");
    } catch (e) {
      debugPrint("Error loading .env file: $e");
    }
  }

  runApp(const CampusInfoSystemApp());
}

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
      home: const LoginScreen(),
    );
  }
}
