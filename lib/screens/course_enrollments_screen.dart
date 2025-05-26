import 'package:flutter/material.dart';
import '../services/enrollment_service.dart';
import '../services/auth_service.dart';
import '../constants/app_constants.dart';
import 'enroll_student_screen.dart';
import 'package:logger/logger.dart';

class CourseEnrollmentsScreen extends StatefulWidget {
  static const routeName = '/course-enrollments';
  final String courseId;
  final String courseTitle;

  const CourseEnrollmentsScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<CourseEnrollmentsScreen> createState() =>
      _CourseEnrollmentsScreenState();
}

class _CourseEnrollmentsScreenState extends State<CourseEnrollmentsScreen> {
  final _enrollmentService = EnrollmentService();
  final _authService = AuthService();
  final _logger = Logger();

  List<Map<String, dynamic>> _enrollments = [];
  bool _isLoading = true;
  String _userRole = '';
  bool _canManageEnrollments = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final role = await _authService.getUserRole();
      setState(() {
        _userRole = role ?? '';
        _canManageEnrollments = role == AppConstants.roleAdmin ||
            role == AppConstants.roleSupervisor;
      });
      await _loadEnrollments();
    } catch (e) {
      _logger.e('Error loading user info: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user information: $e')),
        );
      }
    }
  }

  Future<void> _loadEnrollments() async {
    setState(() => _isLoading = true);

    try {
      final enrollments =
          await _enrollmentService.getCourseEnrollments(widget.courseId);
      if (mounted) {
        setState(() => _enrollments = enrollments);
      }
    } catch (e) {
      _logger.e('Error loading enrollments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading enrollments: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showEnrollmentActions(Map<String, dynamic> enrollment) async {
    if (!_canManageEnrollments && _userRole != AppConstants.roleTeacher) return;

    await showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_canManageEnrollments) ...[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Update Status'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus(enrollment);
              },
            ),
          ],
          if (_canManageEnrollments ||
              _userRole == AppConstants.roleTeacher) ...[
            ListTile(
              leading: const Icon(Icons.grade),
              title: const Text('Update Grade'),
              onTap: () {
                Navigator.pop(context);
                _updateGrade(enrollment);
              },
            ),
          ],
          if (_canManageEnrollments) ...[
            ListTile(
              leading: const Icon(Icons.person_remove),
              title: const Text('Withdraw Student'),
              onTap: () {
                Navigator.pop(context);
                _withdrawStudent(enrollment);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Remove Enrollment',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteEnrollment(enrollment);
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updateStatus(Map<String, dynamic> enrollment) async {
    final status = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Update Status'),
        children: [
          'active',
          'withdrawn',
          'completed',
        ]
            .map((status) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, status),
                  child: Text(status),
                ))
            .toList(),
      ),
    );

    if (status != null) {
      try {
        await _enrollmentService.updateEnrollmentStatus(
          enrollment['id'],
          status,
        );
        await _loadEnrollments();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating status: $e')),
          );
        }
      }
    }
  }

  Future<void> _updateGrade(Map<String, dynamic> enrollment) async {
    final controller = TextEditingController(
      text: enrollment['final_grade']?.toString(),
    );

    final grade = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Final Grade'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Grade (0-100)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final grade = double.tryParse(controller.text);
              if (grade != null && grade >= 0 && grade <= 100) {
                Navigator.pop(context, grade);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid grade value')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (grade != null) {
      try {
        await _enrollmentService.updateFinalGrade(
          enrollment['id'],
          grade,
        );
        await _loadEnrollments();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating grade: $e')),
          );
        }
      }
    }
  }

  Future<void> _withdrawStudent(Map<String, dynamic> enrollment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Student'),
        content: const Text(
            'Are you sure you want to withdraw this student from the course?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _enrollmentService.updateEnrollmentStatus(
          enrollment['id'],
          'withdrawn',
        );
        await _loadEnrollments();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error withdrawing student: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteEnrollment(Map<String, dynamic> enrollment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Enrollment',
            style: TextStyle(color: Colors.red)),
        content: Text(
            'Are you sure you want to completely remove ${enrollment['student']['full_name']}\'s enrollment from this course? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final result = await _enrollmentService.deleteEnrollment(
          enrollmentId: enrollment['id'],
          courseId: widget.courseId,
          studentId: enrollment['student']['id'],
        );

        if (result['success']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'])),
            );
          }
          await _loadEnrollments();
        } else {
          throw Exception(result['message']);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing enrollment: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.courseTitle} - Enrollments'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _enrollments.isEmpty
              ? const Center(child: Text('No students enrolled'))
              : ListView.builder(
                  itemCount: _enrollments.length,
                  itemBuilder: (context, index) {
                    final enrollment = _enrollments[index];
                    final student = enrollment['student'];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(student['full_name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(student['email']),
                            Text('Status: ${enrollment['status']}'),
                            if (enrollment['final_grade'] != null)
                              Text('Grade: ${enrollment['final_grade']}'),
                          ],
                        ),
                        trailing: _canManageEnrollments ||
                                _userRole == AppConstants.roleTeacher
                            ? const Icon(Icons.more_vert)
                            : null,
                        onTap: () => _showEnrollmentActions(enrollment),
                      ),
                    );
                  },
                ),
      floatingActionButton: _canManageEnrollments
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EnrollStudentScreen(
                      courseId: widget.courseId,
                    ),
                  ),
                );

                if (result == true) {
                  await _loadEnrollments();
                }
              },
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }
}
