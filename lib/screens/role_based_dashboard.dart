import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RoleBasedDashboard extends StatefulWidget {
  final String userRole;

  const RoleBasedDashboard({super.key, required this.userRole});

  @override
  State<RoleBasedDashboard> createState() => _RoleBasedDashboardState();
}

class _RoleBasedDashboardState extends State<RoleBasedDashboard> {
  final AuthService _authService = AuthService();
  String _userName = "User";
  String? _profilePictureUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = await _authService.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _userName = user['full_name'] ?? "User";
          _profilePictureUrl = user['profile_picture_url'];
        });
      }
    } catch (e) {
      // Handle error silently
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine UI elements based on role
    String dashboardTitle;
    Color primaryColor;
    List<Map<String, dynamic>> menuItems = [];
    switch (widget.userRole) {
      case 'admin':
        dashboardTitle = 'Admin Dashboard';
        primaryColor = Colors.red;        menuItems = [
          {
            'title': 'Course Enrollments',
            'icon': Icons.how_to_reg,
            'color': Colors.amber.shade800,
            'route': '/course_enrollments',
          },
          {
            'title': 'Manage Students',
            'icon': Icons.school,
            'color': Colors.blue.shade800,
            'route': '/manage_students',
          },
          {
            'title': 'Add Student',
            'icon': Icons.person_add,
            'color': Colors.blue.shade600,
            'route': '/add_student',
          },
          {
            'title': 'Manage Teachers',
            'icon': Icons.person,
            'color': Colors.green.shade700,
            'route': '/manage_teachers',
          },
          {
            'title': 'Add Teacher',
            'icon': Icons.person_add,
            'color': Colors.green.shade600,
            'route': '/add_teacher',
          },
          {
            'title': 'Manage Courses',
            'icon': Icons.book,
            'color': Colors.orange.shade700,
            'route': '/manage_courses',
          },
          {
            'title': 'Create Course',
            'icon': Icons.add_chart,
            'color': Colors.orange.shade600,
            'route': '/create_course',
          },
          {
            'title': 'Manage Departments',
            'icon': Icons.business,
            'color': Colors.purple.shade700,
            'route': '/manage_departments',
          },
          {
            'title': 'Create Department',
            'icon': Icons.add_business,
            'color': Colors.purple.shade600,
            'route': '/create_department',
          },
          {
            'title': 'Assign Supervisor',
            'icon': Icons.assignment_ind,
            'color': Colors.teal.shade600,
            'route': '/assign_supervisor',
          },
          {
            'title': 'Create Supervisor',
            'icon': Icons.person_add,
            'color': Colors.teal.shade700,
            'route': '/create_supervisor',
          },
          {
            'title': 'Manage User Profiles',
            'icon': Icons.people,
            'color': Colors.amber.shade700,
            'route': '/manage_user_profiles',
          },
          {
            'title': 'My Profile',
            'icon': Icons.account_circle,
            'color': Colors.red.shade800,
            'route': '/profile',
          },
        ];
        break;      case 'supervisor':
        dashboardTitle = 'Supervisor Dashboard';
        primaryColor = Colors.teal;
        menuItems = [
          {
            'title': 'Course Enrollments',
            'icon': Icons.how_to_reg,
            'color': Colors.amber.shade800,
            'route': '/course_enrollments',
          },
          {
            'title': 'Manage Students',
            'icon': Icons.school,
            'color': Colors.blue.shade800,
            'route': '/manage_students',
          },
          {
            'title': 'Manage Teachers',
            'icon': Icons.person,
            'color': Colors.green.shade700,
            'route': '/manage_teachers',
          },
          {
            'title': 'Add Teacher',
            'icon': Icons.person_add,
            'color': Colors.green.shade600,
            'route': '/add_teacher',
          },
          {
            'title': 'Manage Courses',
            'icon': Icons.book,
            'color': Colors.orange.shade700,
            'route': '/manage_courses',
          },
          {
            'title': 'Academic Calendar',
            'icon': Icons.calendar_month,
            'color': Colors.purple.shade700,
            'route': '/admin', // Placeholder - will need implementation
          },
          {
            'title': 'My Profile',
            'icon': Icons.account_circle,
            'color': Colors.teal.shade800,
            'route': '/profile',
          },
        ];
        break;
      case 'teacher':
        dashboardTitle = 'Teacher Dashboard';
        primaryColor = Colors.blue;
        menuItems = [
          {
            'title': 'My Courses',
            'icon': Icons.book,
            'color': Colors.indigo,
            'route':
                '/teacher_courses', // Updated to teacher courses route instead of manage_courses
          },
          {
            'title': 'Student Grades',
            'icon': Icons.grade,
            'color': Colors.orange.shade700,
            'route':
                '/teacher_grades', // Updated to correct teacher grades route
          },
          {
            'title': 'Schedule',
            'icon': Icons.calendar_today,
            'color': Colors.green.shade700,
            'route': '/teacher_schedule', // Updated to correct route
          },
          {
            'title': 'My Profile',
            'icon': Icons.account_circle,
            'color': Colors.blue.shade800,
            'route': '/profile',
          },
        ];
        break;
      case 'student':
      default:
        dashboardTitle = 'Student Dashboard';
        primaryColor = Colors.blue;
        menuItems = [
          {
            'title': 'My Schedule',
            'icon': Icons.calendar_today,
            'color': Colors.blue.shade700,
            'route':
                '/student_schedule', // Updated to use the student schedule route
          },
          {
            'title': 'My Courses',
            'icon': Icons.book,
            'color': Colors.green.shade700,
            'route': '/admin', // Placeholder - will need implementation
          },
          {
            'title': 'Exam Results',
            'icon': Icons.score,
            'color': Colors.orange.shade700,
            'route': '/admin', // Placeholder - will need implementation
          },
          {
            'title': 'My Profile',
            'icon': Icons.account_circle,
            'color': Colors.purple.shade700,
            'route': '/profile',
          },
        ];
        break;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(dashboardTitle),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage: _profilePictureUrl != null
                        ? NetworkImage(_profilePictureUrl!)
                        : null,
                    child: _profilePictureUrl == null
                        ? Text(
                            _userName.isNotEmpty
                                ? _userName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    widget.userRole.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ...menuItems.map((item) => ListTile(
                  leading: Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                  ),
                  title: Text(item['title'] as String),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.pushNamed(context, item['route'] as String);
                  },
                )),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                _logout();
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: primaryColor,
                            backgroundImage: _profilePictureUrl != null
                                ? NetworkImage(_profilePictureUrl!)
                                : null,
                            child: _profilePictureUrl == null
                                ? Text(
                                    _userName.isNotEmpty
                                        ? _userName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, $_userName',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.userRole.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: menuItems.map((item) {
                      return _buildDashboardCard(
                        item['title'],
                        item['icon'],
                        item['color'],
                        () => Navigator.pushNamed(context, item['route']),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDashboardCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
