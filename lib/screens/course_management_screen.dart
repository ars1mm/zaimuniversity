import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/course_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
class CourseManagementScreen extends StatefulWidget {
  const CourseManagementScreen({super.key});

  @override
  State<CourseManagementScreen> createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  final CourseService _courseService = CourseService();
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _departments = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _formKey = GlobalKey<FormState>();
  final _courseNameController = TextEditingController();
  final _courseCodeController = TextEditingController();
  final _creditController = TextEditingController();
  final _departmentController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchCodeController = TextEditingController();
  final _logger = Logger();

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _loadDepartments();
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _courseCodeController.dispose();
    _creditController.dispose();
    _departmentController.dispose();
    _descriptionController.dispose();
    _searchCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    try {
      setState(() => _isLoading = true);
      final courses = await _courseService.getCourses();
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading courses: ${e.toString()}')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDepartments() async {
    try {
      _logger.i('Loading departments...');
      final response = await _supabase
          .from(AppConstants.tableDepartments)
          .select()
          .order('name');

      _logger.d('Received departments response: $response');

      if (mounted) {
        setState(() {
          _departments = (response as List<dynamic>).map((dept) {
            return {
              'id': dept['id'].toString(),
              'name': dept['name']?.toString() ?? 'Unknown Department'
            };
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading departments: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredCourses {
    if (_searchQuery.isEmpty) {
      return _courses;
    }

    final query = _searchQuery.toLowerCase();
    return _courses.where((course) {
      return course['title'].toString().toLowerCase().contains(query) ||
          course['department'].toString().toLowerCase().contains(query) ||
          course['semester'].toString().toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _showAddCourseDialog() async {
    _courseNameController.clear();
    _courseCodeController.clear();
    _creditController.clear();
    _departmentController.clear();
    _descriptionController.clear();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Course'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _courseCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Course Code',
                    hintText: 'e.g. CS101',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a course code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _courseNameController,
                  decoration: const InputDecoration(
                    labelText: 'Course Title',
                    hintText: 'e.g. Introduction to Computer Science',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a course title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _creditController,
                  decoration: const InputDecoration(
                    labelText: 'Capacity',
                    hintText: 'e.g. 30',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter capacity';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
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
                    setState(() {
                      try {
                        _departmentController.text = _departments
                                .firstWhere(
                                  (dept) => dept['id'] == value,
                                  orElse: () => {'name': 'Unknown Department'},
                                )['name']
                                ?.toString() ??
                            'Unknown Department';
                      } catch (e) {
                        _departmentController.text = 'Unknown Department';
                        _logger.e('Error finding department: $e');
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a department';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter course description',
                  ),
                  maxLines: 3,
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
                if (!mounted) return;

                final scaffoldMessenger = ScaffoldMessenger.of(context);
                setState(() => _isLoading = true);

                final result = await _courseService.addCourse(
                  title: _courseNameController.text,
                  capacity: int.parse(_creditController.text),
                  department: _departmentController.text,
                  description: _descriptionController.text,
                  semester: _courseCodeController.text,
                );

                if (!mounted) return;

                setState(() => _isLoading = false);

                if (result['success']) {
                  _loadCourses();

                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Course added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content:
                          Text('Failed to add course: ${result['message']}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Add Course'),
          ),
        ],
      ),
    );
  }


  void _confirmDeleteCourse(int index) {
    final course = _filteredCourses[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text(
          'Are you sure you want to delete "${course['name']}"? This action cannot be undone.',
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
              if (!mounted) return;

              final scaffoldMessenger = ScaffoldMessenger.of(context);
              setState(() => _isLoading = true);

              final result = await _courseService.deleteCourse(course['id']);

              if (!mounted) return;

              setState(() => _isLoading = false);

              if (result['success']) {
                setState(() {
                  _courses.removeWhere((c) => c['id'] == course['id']);
                });

                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Course deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content:
                        Text('Failed to delete course: ${result['message']}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Navigate to edit course screen instead of using dialog
  void _navigateToEditCourse(int index) {
    final course = _filteredCourses[index];

    // Process departments data before passing to next screen to avoid potential function handling issues
    final processedCourse = Map<String, dynamic>.from(course);

    // If departments is a function, try to evaluate it and store the result
    if (processedCourse['departments'] is Function) {
      try {
        final departmentsFunc = processedCourse['departments'] as Function;
        final departmentsData = departmentsFunc();
        if (departmentsData is Map<String, dynamic>) {
          processedCourse['departments'] = departmentsData;
        } else {
          processedCourse['departments'] = {};
        }
      } catch (e) {
        _logger.e('Error processing department data: $e');
        processedCourse['departments'] = {};
      }
    }

    // We'll redirect to the ManageCoursesScreen for editing
    // This is a temporary solution until the EditCourseScreen is implemented
    Navigator.of(context).pushNamed(
      '/manage_courses',
      arguments: {'courseToEdit': processedCourse},
    ).then((_) {
      // Refresh data when returning from the edit screen
      _loadCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Course Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCourses,
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
                      hintText: 'Search courses...',
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
                  onPressed: _showAddCourseDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Course'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredCourses.isEmpty
                      ? const Center(
                          child: Text(
                            'No courses found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredCourses.length,
                          itemBuilder: (context, index) {
                            final course = _filteredCourses[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text(
                                  course['title'] ?? 'Untitled Course',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                        'Department: ${course['department'] ?? 'No Department'}'),
                                    Text(
                                        'Capacity: ${course['capacity'] ?? 0}'),
                                    Text(
                                        'Semester: ${course['semester'] ?? 'Not Set'}'),
                                    if (course['description'] != null &&
                                        course['description'].isNotEmpty)
                                      Text(
                                        course['description'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () =>
                                          _navigateToEditCourse(index),
                                      color: Colors.blue,
                                      tooltip: 'Edit Course',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () =>
                                          _confirmDeleteCourse(index),
                                      color: Colors.red,
                                      tooltip: 'Delete Course',
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
        onPressed: _showAddCourseDialog,
        tooltip: 'Add Course',
        child: const Icon(Icons.add),
      ),
    );
  }
}
