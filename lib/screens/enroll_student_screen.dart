import 'package:flutter/material.dart';
import '../services/enrollment_service.dart';
import '../services/auth_service.dart';
import '../constants/app_constants.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EnrollStudentScreen extends StatefulWidget {
  static const routeName = '/enroll-student';
  final String? courseId;

  const EnrollStudentScreen({super.key, this.courseId});

  @override
  State<EnrollStudentScreen> createState() => _EnrollStudentScreenState();
}

class _EnrollStudentScreenState extends State<EnrollStudentScreen> {
  final _enrollmentService = EnrollmentService();
  final _authService = AuthService();
  final _logger = Logger();
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _availableStudents = [];
  List<Map<String, dynamic>> _availableCourses = [];
  String? _selectedStudentId;
  String? _selectedCourseId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Verify admin or supervisor role
      final role = await _authService.getUserRole();
      if (role != AppConstants.roleAdmin &&
          role != AppConstants.roleSupervisor) {
        throw Exception('Insufficient permissions');
      }

      await Future.wait([
        _loadStudents(),
        if (widget.courseId == null) _loadCourses(),
      ]);

      if (widget.courseId != null) {
        setState(() => _selectedCourseId = widget.courseId);
      }
    } catch (e) {
      _logger.e('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadStudents() async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, full_name, email')
          .eq('role', AppConstants.roleStudent)
          .eq('status', 'active')
          .order('full_name');

      setState(() {
        _availableStudents = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _logger.e('Error loading students: $e');
      rethrow;
    }
  }

  Future<void> _loadCourses() async {
    try {
      final response = await _supabase.from('courses').select('''
            id,
            title,
            department:department_id (
              name
            )
          ''').eq('status', 'active').order('title');

      setState(() {
        _availableCourses = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _logger.e('Error loading courses: $e');
      rethrow;
    }
  }

  Future<void> _enrollStudent() async {
    if (_selectedStudentId == null ||
        (_selectedCourseId == null && widget.courseId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both student and course')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _enrollmentService.enrollStudent(
        _selectedStudentId!,
        _selectedCourseId ?? widget.courseId!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student enrolled successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _logger.e('Error enrolling student: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error enrolling student: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enroll Student'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Student',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedStudentId,
                    items: _availableStudents
                        .map<DropdownMenuItem<String>>((student) {
                      return DropdownMenuItem<String>(
                        value: student['id'],
                        child: Text(
                          '${student['full_name']} (${student['email']})',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedStudentId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (widget.courseId == null) ...[
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Course',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCourseId,
                      items: _availableCourses
                          .map<DropdownMenuItem<String>>((course) {
                        return DropdownMenuItem<String>(
                          value: course['id'],
                          child: Text(
                            '${course['title']} (${course['department']['name']})',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCourseId = value);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton(
                    onPressed: _enrollStudent,
                    child: const Text('Enroll Student'),
                  ),
                ],
              ),
            ),
    );
  }
}
