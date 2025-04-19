import 'package:flutter/material.dart';
import '../services/course_service.dart';
import '../constants/app_constants.dart';
import 'create_course_screen.dart';

class ManageCoursesScreen extends StatefulWidget {
  static const routeName = '/manage_courses';

  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  final _courseService = CourseService();
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
        await _courseService.deleteCourseById(courseId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Course deleted successfully')),
          );
          _loadCourses();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting course: ${e.toString()}')),
          );
        }
      }
    }
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
                    final course = _courses[index];
                    final department = course['departments'] as Map<String, dynamic>?;
                    final instructor = course['users'] as Map<String, dynamic>?;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(course['title'] ?? 'Untitled Course'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (department != null)
                              Text('Department: ${department['name']}'),
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
                              onPressed: () {
                                // TODO: Implement edit course functionality
                              },
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