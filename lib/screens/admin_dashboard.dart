import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../constants/app_constants.dart';
import 'student_management_screen.dart'; // Import the StudentManagementScreen

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _authService = AuthService();
  String _adminName = 'Administrator';

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final user = await _authService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _adminName = user.name;
      });
    }
  }

  Future<void> _handleLogout() async {
    final success = await _authService.logout();
    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Control Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 30,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _adminName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const Text(
                    'Administrator',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Manage Students'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, StudentManagementScreen.routeName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Manage Courses'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/manage_courses');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Add Student'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/add_student');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Logout'),
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to Admin Control Panel',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'System Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardCard(
                    'Students',
                    Icons.people,
                    Colors.blue,
                    () {
                      Navigator.pushNamed(
                          context, StudentManagementScreen.routeName);
                    },
                  ),
                  _buildDashboardCard(
                    'Courses',
                    Icons.school,
                    Colors.green,
                    () {
                      Navigator.pushNamed(context, '/manage_courses');
                    },
                  ),
                  _buildDashboardCard(
                    'Teachers',
                    Icons.person,
                    Colors.orange,
                    () {
                      Navigator.pushNamed(context, '/manage_teachers');
                    },
                  ),
                  _buildDashboardCard(
                    'Departments',
                    Icons.business,
                    Colors.purple,
                    () {
                      Navigator.pushNamed(context, '/manage_departments');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
