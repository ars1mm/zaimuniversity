import 'package:flutter/material.dart';
import '../services/enrollment_service.dart';
import '../services/auth_service.dart';
import '../constants/app_constants.dart';
import 'package:logger/logger.dart';

class EnrollmentManagementScreen extends StatefulWidget {
  static const routeName = '/enrollment-management';

  const EnrollmentManagementScreen({super.key});

  @override
  State<EnrollmentManagementScreen> createState() =>
      _EnrollmentManagementScreenState();
}

class _EnrollmentManagementScreenState
    extends State<EnrollmentManagementScreen> {
  final _enrollmentService = EnrollmentService();
  final _authService = AuthService();
  final _logger = Logger();
  List<Map<String, dynamic>> _enrollments = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = true;
  String _userRole = '';
  String? _selectedCourseId;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final role = await _authService.getUserRole();
      final id = await _authService.getCurrentUser();
      final userId = id?.toString() ?? '';
      if (role == null || userId.isEmpty) {
        throw Exception('User role or ID not found');
      }
      setState(() {
        _userRole = role;
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
      // For admin/supervisor, load all available data
      if (_userRole == AppConstants.roleAdmin ||
          _userRole == AppConstants.roleSupervisor) {
        // Load available students
        _students = await _enrollmentService.getAvailableStudents();

        // Load available courses
        _courses = await _enrollmentService.getAvailableCourses();

        // Load current enrollments for selected course if any
        if (_selectedCourseId != null) {
          _enrollments =
              await _enrollmentService.getCourseEnrollments(_selectedCourseId!);
        }
      }
    } catch (e) {
      _logger.e('Error loading enrollment data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading enrollment data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showEnrollmentDetails(Map<String, dynamic> enrollment) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enrollment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Course: ${enrollment['course']['title']}'),
              Text('Status: ${enrollment['status']}'),
              Text('Enrolled: ${enrollment['enrollment_date']}'),
              if (enrollment['final_grade'] != null)
                Text('Final Grade: ${enrollment['final_grade']}'),
              if (enrollment['course']['instructor'] != null)
                Text(
                    'Instructor: ${enrollment['course']['instructor']['full_name']}'),
            ],
          ),
        ),
        actions: [
          if (_userRole != AppConstants.roleStudent) ...[
            TextButton(
              onPressed: () => _updateStatus(enrollment),
              child: const Text('Update Status'),
            ),
            TextButton(
              onPressed: () => _updateGrade(enrollment),
              child: const Text('Update Grade'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
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

  Future<void> _showEnrollStudentDialog() async {
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course first')),
      );
      return;
    }

    // Get the course details
    final course = _courses.firstWhere((c) => c['id'] == _selectedCourseId);

    // Show dialog to select student
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enroll Student in ${course['title']}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select a student to enroll:'),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    return ListTile(
                      title: Text(student['full_name']),
                      subtitle: Text('ID: ${student['student_id']}'),
                      onTap: () => Navigator.of(context).pop(student),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    // If a student was selected, create the enrollment
    if (result != null && mounted) {
      try {
        await _enrollmentService.createEnrollment(
          studentId: result['id'],
          courseId: _selectedCourseId!,
        );

        // Reload the enrollments
        await _loadEnrollments();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student enrolled successfully')),
          );
        }
      } catch (e) {
        _logger.e('Error enrolling student: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error enrolling student: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Enrollments'),
        actions: [
          if (_userRole == AppConstants.roleAdmin ||
              _userRole == AppConstants.roleSupervisor)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showEnrollStudentDialog,
              tooltip: 'Enroll Student',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Course Selection Dropdown
                if (_courses.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Course',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCourseId,
                      items: _courses.map<DropdownMenuItem<String>>((course) {
                        return DropdownMenuItem<String>(
                          value: course['id']?.toString() ?? '',
                          child: Text(
                              course['title']?.toString() ?? 'Untitled Course'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCourseId = value;
                          _loadEnrollments();
                        });
                      },
                    ),
                  ),

                // Enrollments List
                Expanded(
                  child: _selectedCourseId == null
                      ? const Center(child: Text('Please select a course'))
                      : _enrollments.isEmpty
                          ? const Center(
                              child: Text('No enrollments for this course'))
                          : ListView.builder(
                              itemCount: _enrollments.length,
                              itemBuilder: (context, index) {
                                final enrollment = _enrollments[index];
                                return Card(
                                  margin: const EdgeInsets.all(8.0),
                                  child: ListTile(
                                    title: Text(
                                        enrollment['student']['full_name']),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Status: ${enrollment['status']}'),
                                        if (enrollment['final_grade'] != null)
                                          Text(
                                              'Grade: ${enrollment['final_grade']}'),
                                      ],
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () =>
                                        _showEnrollmentDetails(enrollment),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}
