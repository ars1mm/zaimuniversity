import 'package:flutter/material.dart';
import '../services/course_service.dart';
import '../constants/app_constants.dart';
import 'create_course_screen.dart';
import 'package:logger/logger.dart';

class ManageCoursesScreen extends StatefulWidget {
  static const routeName = '/manage_courses';

  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  final _courseService = CourseService();
  final _logger = Logger();
  bool _isLoading = true;
  List<Map<String, dynamic>> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
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

  Future<void> _deleteCourse(String courseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: const Text('Are you sure you want to delete this course?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        final result = await _courseService.deleteCourse(courseId);
        setState(() => _isLoading = false);

        if (mounted) {
          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Course deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _loadCourses();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${result['message']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting course: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showEditCourseDialog(Map<String, dynamic> course) async {
    // Safely extract course data with null checks and defaults
    final String title = course['title']?.toString() ?? '';
    final int capacity = course['capacity'] is int ? course['capacity'] : 0;
    final String description = course['description']?.toString() ?? '';
    final String status = course['status']?.toString() ?? 'active';
    final titleController = TextEditingController(text: title);
    final capacityController = TextEditingController(text: capacity.toString());
    final descriptionController = TextEditingController(text: description);
    String selectedStatus = status;

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Course'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
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
                  controller: capacityController,
                  decoration: const InputDecoration(
                    labelText: 'Capacity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter course capacity';
                    }
                    final capacity = int.tryParse(value);
                    if (capacity == null || capacity <= 0) {
                      return 'Please enter a valid capacity';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                        value: 'inactive', child: Text('Inactive')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      selectedStatus = value;
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        setState(() => _isLoading = true);

        // Get department ID from the course data, ensuring proper type handling
        String departmentId = '';
        if (course.containsKey('department_id')) {
          departmentId = course['department_id']?.toString() ?? '';
        }

        // Convert capacity to int safely
        final capacity = int.tryParse(capacityController.text) ?? 0;

        // Ensure course ID is a string
        final courseId = (course['id'] ?? '').toString();

        if (courseId.isEmpty) {
          throw Exception('Invalid course ID');
        }

        await _courseService.updateCourse(
          id: courseId, title: titleController.text.trim(),
          capacity: capacity,
          description: descriptionController.text.trim(),
          status: selectedStatus,
          department: departmentId, // Use the department ID we extracted
        );

        await _loadCourses();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Course updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating course: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
      }
    }

    // Clean up controllers
    titleController.dispose();
    capacityController.dispose();
    descriptionController.dispose();
  }

  // Helper method to safely get department info from a course
  Map<String, dynamic> safelyExtractDepartment(dynamic departmentData) {
    if (departmentData == null) {
      return {};
    }

    if (departmentData is Map<String, dynamic>) {
      return departmentData;
    } else if (departmentData is Function) {
      try {
        final result = departmentData();
        if (result is Map<String, dynamic>) {
          return result;
        }
      } catch (e) {
        _logger.e('Error extracting department data: $e');
      }
    }

    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.pushNamed(context, CreateCourseScreen.routeName);
              _loadCourses();
            },
            tooltip: 'Add New Course',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
              ? const Center(child: Text('No courses found'))
              : ListView.builder(
                  itemCount: _courses.length,
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  itemBuilder: (context, index) {
                    final course = _courses[
                        index]; // Extract department name using a safer approach
                    String departmentName = '';
                    final departments = course['departments'];

                    if (departments is Map<String, dynamic> &&
                        departments.containsKey('name')) {
                      departmentName = departments['name']?.toString() ?? '';
                    } else if (departments is Function) {
                      try {
                        final result = departments();
                        if (result is Map<String, dynamic> &&
                            result.containsKey('name')) {
                          departmentName = result['name']?.toString() ?? '';
                        }
                      } catch (e) {
                        _logger.e('Error calling department function: $e');
                      }
                    } else if (course['department'] is String) {
                      // Fallback to department string if available
                      departmentName = course['department'];
                    }

                    final instructor = course['users'] as Map<String, dynamic>?;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(course['title'] ?? 'Untitled Course'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Department: ${departmentName.isNotEmpty ? departmentName : 'Not assigned'}'),
                            if (instructor != null)
                              Text('Instructor: ${instructor['name']}'),
                            Text('Capacity: ${course['capacity']} students'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditCourseDialog(course),
                              tooltip: 'Edit Course',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteCourse(course['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
