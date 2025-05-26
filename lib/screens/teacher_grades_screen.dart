// filepath: lib/screens/teacher_grades_screen.dart
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../constants/app_constants.dart';
import '../services/teacher_grades_service.dart';

class TeacherGradesScreen extends StatefulWidget {
  static const String routeName = '/teacher_grades';

  const TeacherGradesScreen({super.key});
  @override
  TeacherGradesScreenState createState() => TeacherGradesScreenState();
}

class TeacherGradesScreenState extends State<TeacherGradesScreen> {
  final TeacherGradesService _gradesService = TeacherGradesService();
  final Logger _logger = Logger('TeacherGradesScreen');

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _courses = [];

  // Track the currently selected course and student
  String? _selectedCourseId;
  Map<String, dynamic>? _selectedCourse;
  List<Map<String, dynamic>> _enrolledStudents = [];

  // For student details view
  String? _selectedStudentId;
  Map<String, dynamic>? _selectedStudent;
  List<Map<String, dynamic>> _examScores = [];
  List<Map<String, dynamic>> _homeworkSubmissions = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final courses = await _gradesService.getTeacherCourses();

      if (mounted) {
        setState(() {
          _courses = courses;
          _isLoading = false;

          // Reset selections
          _selectedCourseId = null;
          _selectedCourse = null;
          _enrolledStudents = [];
          _selectedStudentId = null;
          _selectedStudent = null;
        });
      }
    } catch (e) {
      _logger.severe('Error loading teacher courses', e);
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load courses: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadEnrolledStudents(String courseId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedCourseId = courseId;
      _selectedCourse =
          _courses.firstWhere((course) => course['id'] == courseId);
    });

    try {
      final students = await _gradesService.getCourseStudents(courseId);

      if (mounted) {
        setState(() {
          _enrolledStudents = students;
          _isLoading = false;

          // Reset student selection
          _selectedStudentId = null;
          _selectedStudent = null;
        });
      }
    } catch (e) {
      _logger.severe('Error loading enrolled students', e);
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load students: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadStudentDetails(
      String studentId, Map<String, dynamic> student) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedStudentId = studentId;
      _selectedStudent = student;
    });

    try {
      // Load both exam scores and homework submissions in parallel
      final examScoresFuture =
          _gradesService.getStudentExamScores(studentId, _selectedCourseId!);
      final homeworkSubmissionsFuture = _gradesService
          .getStudentHomeworkSubmissions(studentId, _selectedCourseId!);

      final results =
          await Future.wait([examScoresFuture, homeworkSubmissionsFuture]);

      if (mounted) {
        setState(() {
          _examScores = results[0];
          _homeworkSubmissions = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.severe('Error loading student details', e);
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load student details: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateFinalGrade(
      String enrollmentId, double currentGrade) async {
    // Show dialog to enter new grade
    final TextEditingController gradeController =
        TextEditingController(text: currentGrade.toString());

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Final Grade'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: gradeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Final Grade',
                    hintText: 'Enter grade (0-100)',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FilledButton(
              child: const Text('Update'),
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  final newGrade = double.parse(gradeController.text);
                  if (newGrade < 0 || newGrade > 100) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Grade must be between 0 and 100')),
                    );
                    return;
                  }

                  setState(() => _isLoading = true);

                  await _gradesService.updateStudentFinalGrade(
                      enrollmentId, newGrade);

                  // Refresh the students list
                  if (_selectedCourseId != null) {
                    await _loadEnrolledStudents(_selectedCourseId!);
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Grade updated successfully')),
                  );
                } catch (e) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Failed to update grade: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateExamScore(String examId, double currentScore) async {
    final TextEditingController scoreController =
        TextEditingController(text: currentScore.toString());

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Exam Score'),
          content: TextField(
            controller: scoreController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Score',
              hintText: 'Enter score (0-100)',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FilledButton(
              child: const Text('Update'),
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  final newScore = double.parse(scoreController.text);
                  if (newScore < 0 || newScore > 100) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Score must be between 0 and 100')),
                    );
                    return;
                  }

                  setState(() => _isLoading = true);

                  await _gradesService.updateExamScore(examId, newScore);

                  // Refresh student details
                  if (_selectedStudentId != null && _selectedStudent != null) {
                    await _loadStudentDetails(
                        _selectedStudentId!, _selectedStudent!);
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Exam score updated successfully')),
                  );
                } catch (e) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Failed to update score: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateHomeworkSubmission(
      String submissionId, double currentScore, String currentFeedback) async {
    final TextEditingController scoreController =
        TextEditingController(text: currentScore.toString());
    final TextEditingController feedbackController =
        TextEditingController(text: currentFeedback);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Grade Homework'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: scoreController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Score',
                    hintText: 'Enter score (0-100)',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: feedbackController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Feedback',
                    hintText: 'Enter feedback for student',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FilledButton(
              child: const Text('Submit'),
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  final newScore = double.parse(scoreController.text);
                  if (newScore < 0 || newScore > 100) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Score must be between 0 and 100')),
                    );
                    return;
                  }

                  setState(() => _isLoading = true);

                  await _gradesService.updateHomeworkSubmission(
                      submissionId, newScore, feedbackController.text);

                  // Refresh student details
                  if (_selectedStudentId != null && _selectedStudent != null) {
                    await _loadStudentDetails(
                        _selectedStudentId!, _selectedStudent!);
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Homework graded successfully')),
                  );
                } catch (e) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Failed to grade homework: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCourseId == null
            ? 'Student Grades'
            : (_selectedStudentId == null
                ? (_selectedCourse?['title'] ?? 'Course')
                : 'Student Details')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_selectedStudentId != null && _selectedStudent != null) {
                _loadStudentDetails(_selectedStudentId!, _selectedStudent!);
              } else if (_selectedCourseId != null) {
                _loadEnrolledStudents(_selectedCourseId!);
              } else {
                _loadCourses();
              }
            },
            tooltip: 'Refresh',
          ),
        ],
        // Show back button if viewing a course or student
        leading: (_selectedCourseId != null)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (_selectedStudentId != null) {
                    // Go back to students list
                    setState(() {
                      _selectedStudentId = null;
                      _selectedStudent = null;
                    });
                  } else {
                    // Go back to courses list
                    setState(() {
                      _selectedCourseId = null;
                      _selectedCourse = null;
                      _enrolledStudents = [];
                    });
                  }
                },
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _selectedStudentId != null
                  ? _buildStudentDetailsView()
                  : _selectedCourseId != null
                      ? _buildStudentListView()
                      : _buildCourseListView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_selectedStudentId != null && _selectedStudent != null) {
                _loadStudentDetails(_selectedStudentId!, _selectedStudent!);
              } else if (_selectedCourseId != null) {
                _loadEnrolledStudents(_selectedCourseId!);
              } else {
                _loadCourses();
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseListView() {
    if (_courses.isEmpty) {
      return const Center(
        child: Text(
          'You are not teaching any courses yet.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        final course = _courses[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text('${index + 1}'),
            ),
            title: Text(course['title'] ?? 'Untitled Course'),
            subtitle: Text(
                'Code: ${course['course_code'] ?? 'N/A'} · Semester: ${course['semester'] ?? 'N/A'}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _loadEnrolledStudents(course['id']),
          ),
        );
      },
    );
  }

  Widget _buildStudentListView() {
    if (_enrolledStudents.isEmpty) {
      return const Center(
        child: Text(
          'No students are enrolled in this course.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: _enrolledStudents.length,
      itemBuilder: (context, index) {
        final enrollment = _enrolledStudents[index];
        final student = enrollment['students'];
        final user = student['users'];

        // Extract final grade or default to 0.0
        final finalGrade = enrollment['final_grade'] ?? 0.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: Text((index + 1).toString()),
            ),
            title: Text(user['full_name'] ?? 'Unknown Student'),
            subtitle: Text('Student ID: ${student['student_id'] ?? 'N/A'}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Grade: $finalGrade',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () =>
                          _updateFinalGrade(enrollment['id'], finalGrade),
                      child: const Text('Update'),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _loadStudentDetails(student['id'], student),
          ),
        );
      },
    );
  }

  Widget _buildStudentDetailsView() {
    if (_selectedStudent == null) {
      return const Center(child: Text('No student selected'));
    }

    final userName =
        _selectedStudent!['users']['full_name'] ?? 'Unknown Student';
    final studentId = _selectedStudent!['student_id'] ?? 'N/A';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student info card
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.green,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                          style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Student ID: $studentId',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Exams section
          const Text(
            'Exam Scores',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _examScores.isEmpty
              ? const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No exam scores available'),
                  ),
                )
              : Card(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _examScores.length,
                    itemBuilder: (context, index) {
                      final exam = _examScores[index];
                      final examScore = exam['exams_score'][0];

                      return ListTile(
                        title: Text('Exam on ${exam['exam_date']}'),
                        subtitle: Text('Duration: ${exam['duration']} minutes'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Score: ${examScore['score'] ?? 'Not graded'}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _updateExamScore(
                                  examScore['id'], examScore['score'] ?? 0.0),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

          const SizedBox(height: 24),

          // Homework section
          const Text(
            'Homework Submissions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _homeworkSubmissions.isEmpty
              ? const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No homework submissions available'),
                  ),
                )
              : Card(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _homeworkSubmissions.length,
                    itemBuilder: (context, index) {
                      final homework = _homeworkSubmissions[index];
                      final submission = homework['homework_submissions'][0];

                      return ExpansionTile(
                        title: Text(homework['title']),                        subtitle: Text(
                          'Due: ${homework['due_date']} · '
                              'Submitted: ${submission['submitted_at'] ?? 'Not submitted'}',
                        ),
                        trailing: Text(
                          'Score: ${submission['score'] ?? 'Not graded'}/${homework['total_points']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Feedback:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text(submission['feedback'] ??
                                    'No feedback provided'),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Grade Submission'),
                                    onPressed: () => _updateHomeworkSubmission(
                                      submission['id'],
                                      submission['score'] ?? 0.0,
                                      submission['feedback'] ?? '',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
