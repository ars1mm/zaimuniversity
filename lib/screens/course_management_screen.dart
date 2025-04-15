import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/course_service.dart';

class CourseManagementScreen extends StatefulWidget {
  const CourseManagementScreen({super.key});

  @override
  State<CourseManagementScreen> createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  final CourseService _courseService = CourseService();
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _formKey = GlobalKey<FormState>();
  final _courseNameController = TextEditingController();
  final _courseCodeController = TextEditingController();
  final _creditController = TextEditingController();
  final _departmentController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _courseCodeController.dispose();
    _creditController.dispose();
    _departmentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _courseService.getAllCourses();
      print('Raw courses data: $result'); // Debug log

      if (result['success'] && result['data'] != null) {
        final List<dynamic> coursesData = result['data'];
        print('Courses data length: ${coursesData.length}'); // Debug log

        final List<Map<String, dynamic>> formattedCourses =
            coursesData.map<Map<String, dynamic>>((course) {
          print('Processing course: $course'); // Debug log

          // Format the course data
          final formattedCourse = {
            'id': course['id'] ?? '',
            'title': course['title'] ?? 'Untitled Course',
            'capacity': course['capacity'] ?? 0,
            'semester': course['semester'] ?? '',
            'status': course['status'] ?? 'active',
            'department': course['department_name'] ?? 'Unknown',
            'description': course['description'] ?? '',
            'instructor_id': course['instructor_id'],
          };
          
          print('Formatted course: $formattedCourse'); // Debug log
          return formattedCourse;
        }).toList();

        setState(() {
          _courses = formattedCourses;
          _isLoading = false;
        });
      } else {
        print('Failed to load courses: ${result['message']}'); // Debug log
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load courses: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading courses: $e'); // Debug log
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
                TextFormField(
                  controller: _departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    hintText: 'e.g. Computer Science',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a department';
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
                setState(() => _isLoading = true);

                final result = await _courseService.addCourse(
                  title: _courseNameController.text,
                  capacity: int.parse(_creditController.text),
                  department: _departmentController.text,
                  description: _descriptionController.text,
                  semester: _courseCodeController
                      .text, // Using code field as semester temporarily
                );

                setState(() => _isLoading = false);

                if (result['success']) {
                  _loadCourses();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Course added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
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

  void _showEditCourseDialog(int index) {
    final course = _filteredCourses[index];
    _courseNameController.text = course['title'];
    _courseCodeController.text = course['semester'] ?? '';
    _creditController.text = course['capacity'].toString();
    _departmentController.text = course['department'];
    _descriptionController.text = course['description'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Course'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _courseCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Semester',
                    hintText: 'e.g. Fall 2025',
                  ),
                  validator: (value) {
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _courseNameController,
                  decoration: const InputDecoration(
                    labelText: 'Course Title',
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
                TextFormField(
                  controller: _departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a department';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
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
                setState(() => _isLoading = true);

                final result = await _courseService.updateCourse(
                  id: course['id'],
                  title: _courseNameController.text,
                  capacity: int.parse(_creditController.text),
                  department: _departmentController.text,
                  description: _descriptionController.text,
                  semester: _courseCodeController.text,
                  status: course['status'] ?? 'active',
                );

                setState(() => _isLoading = false);

                if (result['success']) {
                  _loadCourses();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Course updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Failed to update course: ${result['message']}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save Changes'),
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
              backgroundColor: MaterialStateProperty.all(Colors.red),
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() => _isLoading = true);

              final result = await _courseService.deleteCourse(course['id']);

              setState(() => _isLoading = false);

              if (result['success']) {
                setState(() {
                  _courses.removeWhere((c) => c['id'] == course['id']);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Course deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                                    Text('Department: ${course['department'] ?? 'No Department'}'),
                                    Text('Capacity: ${course['capacity'] ?? 0}'),
                                    Text('Semester: ${course['semester'] ?? 'Not Set'}'),
                                    if (course['description'] != null && course['description'].isNotEmpty)
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
                                          _showEditCourseDialog(index),
                                      color: Colors.blue,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () =>
                                          _confirmDeleteCourse(index),
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
        onPressed: _showAddCourseDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
