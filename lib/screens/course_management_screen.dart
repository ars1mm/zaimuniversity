import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/course_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  String _selectedDepartmentId = '';

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

  Future<void> _loadDepartments() async {
    try {
      final response = await _supabase
          .from(AppConstants.tableDepartments)
          .select()
          .order('name');

      if (response != null) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading departments: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
    _selectedDepartmentId = '';

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
                      child: Text(department['name']?.toString() ?? 'Unknown Department'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartmentId = value ?? '';
                      _departmentController.text = _departments
                          .firstWhere((dept) => dept['id'] == value)['name'];
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
                setState(() => _isLoading = true);

                final result = await _courseService.addCourse(
                  title: _courseNameController.text,
                  capacity: int.parse(_creditController.text),
                  department: _departmentController.text,
                  description: _descriptionController.text,
                  semester: _courseCodeController.text,
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
                      content: Text('Failed to add course: ${result['message']}'),
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
    
    // Properly initialize all controllers with existing data
    _courseNameController.text = course['title'] ?? '';
    _courseCodeController.text = course['semester'] ?? '';
    _creditController.text = (course['capacity'] ?? '0').toString();
    _descriptionController.text = course['description'] ?? '';
    
    // Find the correct department ID
    _selectedDepartmentId = _departments
        .firstWhere(
          (dept) => dept['name'] == course['department'],
          orElse: () => {'id': '', 'name': ''},
        )['id']
        .toString();
    
    // Set the department controller text
    _departmentController.text = course['department'] ?? '';
    
    // Initialize status
    String selectedStatus = course['status'] ?? 'active';

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
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a semester';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _courseNameController,
                  decoration: const InputDecoration(
                    labelText: 'Course Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a course title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _creditController,
                  decoration: const InputDecoration(
                    labelText: 'Capacity',
                    border: OutlineInputBorder(),
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
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedDepartmentId.isNotEmpty ? _selectedDepartmentId : null,
                  items: _departments.map((department) {
                    return DropdownMenuItem<String>(
                      value: department['id'].toString(),
                      child: Text(department['name']?.toString() ?? 'Unknown Department'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartmentId = value ?? '';
                      if (value != null) {
                        final dept = _departments.firstWhere(
                          (d) => d['id'].toString() == value,
                          orElse: () => {'name': 'Unknown Department'},
                        );
                        _departmentController.text = dept['name'];
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
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedStatus,
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'active',
                      child: Text('Active'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'pending',
                      child: Text('Pending'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'rejected',
                      child: Text('Rejected'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'completed',
                      child: Text('Completed'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'cancelled',
                      child: Text('Cancelled'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value ?? 'active';
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
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
                  department: _selectedDepartmentId,
                  description: _descriptionController.text,
                  semester: _courseCodeController.text,
                  status: selectedStatus,
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
                      content: Text('Failed to update course: ${result['message']}'),
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

  void _showSearchCourseDialog() {
    _searchCodeController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Course'),
        content: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _searchCodeController,
                decoration: const InputDecoration(
                  labelText: 'Course Code',
                  hintText: 'Enter course code to search',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final courseCode = _searchCodeController.text.trim();
              if (courseCode.isNotEmpty) {
                Navigator.of(context).pop();
                _searchAndEditCourse(courseCode);
              }
            },
            child: const Text('Search & Edit'),
          ),
        ],
      ),
    );
  }

  void _searchAndEditCourse(String courseCode) {
    final courseIndex = _courses.indexWhere(
      (course) => course['semester']?.toString().toLowerCase() == courseCode.toLowerCase(),
    );

    if (courseIndex != -1) {
      _showEditCourseDialog(courseIndex);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No course found with code: $courseCode'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                  onPressed: _showSearchCourseDialog,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Course'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
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
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _confirmDeleteCourse(index),
                                  color: Colors.red,
                                  tooltip: 'Delete Course',
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
        tooltip: 'Add Course',
      ),
    );
  }
}
