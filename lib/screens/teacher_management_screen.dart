// filepath: c:\Users\Windows 10 PRO\Desktop\Fakulltet\Instanbul\Mobile Applications\project\zaimuniversity\lib\screens\teacher_management_screen.dart
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../main.dart';
import 'package:logging/logging.dart';
import 'add_teacher_screen.dart';

class TeacherManagementScreen extends StatefulWidget {
  static const String routeName = '/manage_teachers';

  const TeacherManagementScreen({super.key});

  @override
  State<TeacherManagementScreen> createState() =>
      _TeacherManagementScreenState();
}

class _TeacherManagementScreenState extends State<TeacherManagementScreen> {
  final Logger _logger = Logger('TeacherManagementScreen');
  List<Map<String, dynamic>> _teachers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _specializationController = TextEditingController();
  final _bioController = TextEditingController();
  final _departmentController = TextEditingController();
  List<Map<String, dynamic>> _departments = [];
  String _selectedStatus = 'active';

  @override
  void initState() {
    super.initState();
    _loadTeachers();
    _loadDepartments();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _specializationController.dispose();
    _bioController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await supabase
          .from(AppConstants.tableTeachers)
          .select('*, users(full_name, email), departments(name)')
          .order('users(full_name)');

      setState(() {
        _teachers = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      _logger.severe('Error loading teachers', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading teachers: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDepartments() async {
    try {
      final response = await supabase
          .from(AppConstants.tableDepartments)
          .select()
          .order('name');

      setState(() {
        _departments = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _logger.severe('Error loading departments', e);
    }
  }

  List<Map<String, dynamic>> get _filteredTeachers {
    if (_searchQuery.isEmpty) {
      return _teachers;
    }

    final query = _searchQuery.toLowerCase();
    return _teachers.where((teacher) {
      return teacher['users']['full_name']
              .toString()
              .toLowerCase()
              .contains(query) ||
          teacher['users']['email'].toString().toLowerCase().contains(query) ||
          teacher['specialization'].toString().toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _navigateToAddTeacher() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTeacherScreen()),
    );

    // If a teacher was added (result is true), refresh the list
    if (result == true) {
      _loadTeachers();
    }
  }

  void _showEditTeacherDialog(int index) {
    final teacher = _filteredTeachers[index];
    _nameController.text = teacher['users']['full_name'];
    _emailController.text = teacher['users']['email'];
    _specializationController.text = teacher['specialization'] ?? '';
    _bioController.text = teacher['bio'] ?? '';
    _departmentController.text = teacher['department_id'];
    _selectedStatus = teacher['status'] ?? 'active';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Teacher'),
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
                      return 'Please enter a name';
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
                      return 'Please enter an email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _specializationController,
                  decoration: const InputDecoration(
                    labelText: 'Specialization',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a specialization';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Department',
                  ),
                  items: _departments.map((department) {
                    return DropdownMenuItem<String>(
                      value: department['id'].toString(),
                      child: Text(department['name']?.toString() ??
                          'Unknown Department'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    _departmentController.text = value ?? '';
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a department';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Status',
                  ),
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(
                      value: 'active',
                      child: Text('Active'),
                    ),
                    DropdownMenuItem(
                      value: 'on_leave',
                      child: Text('On Leave'),
                    ),
                    DropdownMenuItem(
                      value: 'retired',
                      child: Text('Retired'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    }
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
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                setState(() => _isLoading = true);

                try {
                  // Update the user record
                  await supabase.from(AppConstants.tableUsers).update({
                    'full_name': _nameController.text,
                    'email': _emailController.text,
                    'updated_at': DateTime.now().toIso8601String(),
                  }).eq('id', teacher['id']);

                  // Update the teacher record
                  await supabase.from(AppConstants.tableTeachers).update({
                    'department_id': _departmentController.text,
                    'specialization': _specializationController.text,
                    'bio': _bioController.text,
                    'status': _selectedStatus,
                    'contact_info': {
                      'email': _emailController.text,
                    },
                  }).eq('id', teacher['id']);

                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  _loadTeachers();

                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Teacher updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Failed to update teacher: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }

                setState(() => _isLoading = false);
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTeacher(int index) {
    final teacher = _filteredTeachers[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Teacher'),
        content: Text(
          'Are you sure you want to delete "${teacher['users']['full_name']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red),
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() => _isLoading = true);

              try {
                // Delete the teacher record first
                await supabase
                    .from(AppConstants.tableTeachers)
                    .delete()
                    .eq('id', teacher['id']);

                // Then delete the user record
                await supabase
                    .from(AppConstants.tableUsers)
                    .delete()
                    .eq('id', teacher['id']);

                setState(() {
                  _teachers.removeWhere((t) => t['id'] == teacher['id']);
                });

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Teacher deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete teacher: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }

              setState(() => _isLoading = false);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeachers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search teachers...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _navigateToAddTeacher,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Teacher'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredTeachers.isEmpty
                      ? const Center(
                          child: Text(
                            'No teachers found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredTeachers.length,
                          itemBuilder: (context, index) {
                            final teacher = _filteredTeachers[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text(
                                  teacher['users']['full_name'] ??
                                      'Unknown Teacher',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(teacher['users']['email'] ?? ''),
                                    if (teacher['specialization'] != null)
                                      Text(
                                          'Specialization: ${teacher['specialization']}'),
                                    Text(
                                      'Department: ${teacher['departments']['name'] ?? 'Not assigned'}',
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    Text(
                                      'Status: ${teacher['status'] ?? 'Unknown'}',
                                      style: TextStyle(
                                        color: teacher['status'] == 'active'
                                            ? Colors.green
                                            : teacher['status'] == 'on_leave'
                                                ? Colors.orange
                                                : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () =>
                                          _showEditTeacherDialog(index),
                                      color: Colors.blue,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () =>
                                          _confirmDeleteTeacher(index),
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTeacher,
        child: const Icon(Icons.add),
      ),
    );
  }
}
