import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/student_service.dart';
import '../models/user.dart';

class StudentManagementScreen extends StatefulWidget {
  static const routeName = '/manage_students'; // Define static route name

  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final StudentService _studentService = StudentService();
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  final _enrollmentYearController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _enrollmentYearController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get real student data from the StudentService
      final result = await _studentService.getAllStudents();

      if (result['success'] && result['data'] != null) {
        final List<dynamic> studentsData = result['data'];

        // Convert the User objects to the format expected by the UI
        final List<Map<String, dynamic>> formattedStudents =
            studentsData.map<Map<String, dynamic>>((student) {
          if (student is User) {
            return {
              'id': student.id,
              'name': student.name,
              'email': student.email,
              'student_id': student.studentId,
              'department': student.department,
              'enrollment_year': student.enrollmentYear,
              'status': 'active', // Assume active if not specified
            };
          } else {
            // Handle cases where data might not be a User object
            return {
              'id': student['id'] ?? '',
              'name': student['full_name'] ?? student['name'] ?? '',
              'email': student['email'] ?? '',
              'student_id': student['student_id'] ?? '',
              'department': student['department'] ?? '',
              'enrollment_year':
                  student['enrollment_year'] ?? DateTime.now().year,
              'status': student['status'] ?? 'active',
            };
          }
        }).toList();

        setState(() {
          _students = formattedStudents;
          _isLoading = false;
        });
      } else {
        // If there's an error or no data, show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load students: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchQuery.isEmpty) {
      return _students;
    }

    final query = _searchQuery.toLowerCase();
    return _students.where((student) {
      return student['name'].toString().toLowerCase().contains(query) ||
          student['email'].toString().toLowerCase().contains(query) ||
          student['student_id'].toString().toLowerCase().contains(query) ||
          student['department'].toString().toLowerCase().contains(query);
    }).toList();
  }

  void _showEditStudentDialog(int index) {
    final student = _filteredStudents[index];
    _nameController.text = student['name'];
    _studentIdController.text = student['student_id'];
    _emailController.text = student['email'];
    _departmentController.text = student['department'];
    _enrollmentYearController.text = student['enrollment_year'].toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Student'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter student name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _studentIdController,
                  decoration: const InputDecoration(
                    labelText: 'Student ID',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter student ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter department';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _enrollmentYearController,
                  decoration: const InputDecoration(
                    labelText: 'Enrollment Year',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter enrollment year';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid year';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Active'),
                  value: student['status'] == 'active',
                  onChanged: (value) {
                    setState(() {
                      student['status'] = value ? 'active' : 'inactive';
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  // Update the student
                  final originalStudentIndex =
                      _students.indexWhere((s) => s['id'] == student['id']);
                  if (originalStudentIndex != -1) {
                    _students[originalStudentIndex] = {
                      'id': student['id'],
                      'name': _nameController.text,
                      'student_id': _studentIdController.text,
                      'email': _emailController.text,
                      'department': _departmentController.text,
                      'enrollment_year':
                          int.parse(_enrollmentYearController.text),
                      'status': student['status'],
                    };
                  }
                });

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Student updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );

                Navigator.of(context).pop();
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteStudent(int index) {
    final student = _filteredStudents[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text(
          'Are you sure you want to delete "${student['name']}" (${student['student_id']})? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.red),
            ),
            onPressed: () {
              setState(() {
                _students.removeWhere((s) => s['id'] == student['id']);
              });

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Student deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );

              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewStudentDetails(int index) {
    final student = _filteredStudents[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.badge),
              title: const Text('Student ID'),
              subtitle: Text(student['student_id']),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(student['email']),
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Department'),
              subtitle: Text(student['department']),
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Enrollment Year'),
              subtitle: Text(student['enrollment_year'].toString()),
            ),
            ListTile(
              leading: Icon(
                student['status'] == 'active'
                    ? Icons.check_circle
                    : Icons.cancel,
                color:
                    student['status'] == 'active' ? Colors.green : Colors.red,
              ),
              title: const Text('Status'),
              subtitle: Text(student['status'].toString().toUpperCase()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditStudentDialog(index);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Row
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search students...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // Statistics Row
            Row(
              children: [
                _buildStatCard(
                  'Total Students',
                  _students.length.toString(),
                  Icons.people,
                  Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Active Students',
                  _students
                      .where((s) => s['status'] == 'active')
                      .length
                      .toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Inactive Students',
                  _students
                      .where((s) => s['status'] != 'active')
                      .length
                      .toString(),
                  Icons.cancel,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Students List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredStudents.isEmpty
                      ? const Center(
                          child: Text(
                            'No students found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    student['name']
                                        .toString()
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  student['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${student['student_id']} • ${student['department']}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Status indicator
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: student['status'] == 'active'
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // View details button
                                    IconButton(
                                      icon: const Icon(Icons.visibility),
                                      onPressed: () =>
                                          _viewStudentDetails(index),
                                      color: Colors.blue,
                                    ),
                                    // Edit button
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () =>
                                          _showEditStudentDialog(index),
                                      color: Colors.blue,
                                    ),
                                    // Delete button
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () =>
                                          _confirmDeleteStudent(index),
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                                onTap: () => _viewStudentDetails(index),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/add_student');
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Student'),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
