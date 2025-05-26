import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../constants/app_constants.dart';
import '../services/teacher_schedule_service.dart';
import '../services/auth_service.dart';

class TeacherScheduleScreen extends StatefulWidget {
  static const String routeName = '/teacher_schedule';

  const TeacherScheduleScreen({super.key});

  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen> {
  final Logger _logger = Logger('TeacherScheduleScreen');
  final TeacherScheduleService _scheduleService = TeacherScheduleService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _canCreateSchedule = false;
  Map<String, List<Map<String, dynamic>>> _scheduleByDay = {};
  final List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _loadTeacherSchedule();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      // Only admins and supervisors can create schedules
      final isAdmin = await _authService.isAdmin();
      final isSupervisor = await _authService.isSupervisor();
      
      if (mounted) {
        setState(() {
          _canCreateSchedule = isAdmin || isSupervisor;
        });
      }
      
      _logger.info('Schedule creation permission: $_canCreateSchedule');
    } catch (e) {
      _logger.severe('Error checking permissions', e);
    }
  }

  Future<void> _loadTeacherSchedule() async {
    setState(() => _isLoading = true);

    try {
      // Use the service to get the schedule
      final scheduleMap = await _scheduleService.getTeacherSchedule();

      if (mounted) {
        setState(() {
          _scheduleByDay = scheduleMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.severe('Error loading teacher schedule', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading schedule: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Teaching Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeacherSchedule,
            tooltip: 'Reload Schedule',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildScheduleContent(),
      // Only show floating action button for admins and supervisors
      floatingActionButton: _canCreateSchedule
          ? FloatingActionButton(
              onPressed: _showAddScheduleDialog,
              tooltip: 'Add Schedule Entry',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildScheduleContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _weekdays.map((day) {
          final coursesForDay = _scheduleByDay[day] ?? [];
          return _buildDaySchedule(day, coursesForDay);
        }).toList(),
      ),
    );
  }

  Widget _buildDaySchedule(String day, List<Map<String, dynamic>> courses) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            width: double.infinity,
            child: Text(
              day,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (courses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No classes scheduled',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: courses.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final course = courses[index];
                return _buildScheduleItem(course);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(Map<String, dynamic> course) {
    return ListTile(
      title: Text(
        course['course_title'],
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('Time: ${course['start_time']} - ${course['end_time']}'),
          Text(
              'Location: ${course['room']}${course['building'].isNotEmpty ? ' (${course['building']})' : ''}'),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Future<void> _showAddScheduleDialog() async {
    // This method will only be called if the user has permission to create schedules
    final formKey = GlobalKey<FormState>();
    String selectedCourseId = '';
    String selectedDay = 'Monday';
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay.now().replacing(
        hour: TimeOfDay.now().hour + 1, minute: TimeOfDay.now().minute);
    final roomController = TextEditingController();
    final buildingController = TextEditingController();
    List<Map<String, dynamic>> teacherCourses = [];
    bool isLoadingCourses = true;

    // Check permission again before proceeding
    final hasPermission = await _authService.isAdmin() || await _authService.isSupervisor();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to create schedules'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Load teacher's courses for the dropdown
    try {
      teacherCourses = await _scheduleService.getTeacherCourses();
      if (teacherCourses.isNotEmpty) {
        selectedCourseId = teacherCourses[0]['id'];
      }
      isLoadingCourses = false;
    } catch (e) {
      _logger.severe('Error loading teacher courses', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading courses: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Format time for display
    String formatTimeOfDay(TimeOfDay time) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    // Handle time picker
    Future<TimeOfDay?> selectTime(BuildContext context) async {
      return showTimePicker(
        context: context,
        initialTime: startTime,
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          );
        },
      );
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Schedule Entry'),
              content: isLoadingCourses
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (teacherCourses.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 16.0),
                                child: Text(
                                  'No courses available to schedule. Please create a course first.',
                                  style: TextStyle(color: Colors.red),
                                ),
                              )
                            else
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Course',
                                  border: OutlineInputBorder(),
                                ),
                                value: selectedCourseId,
                                items: teacherCourses.map((course) {
                                  return DropdownMenuItem<String>(
                                    value: course['id'],
                                    child: Text(course['title']),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedCourseId = value;
                                    });
                                  }
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a course';
                                  }
                                  return null;
                                },
                              ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Day of Week',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedDay,
                              items: _weekdays.map((day) {
                                return DropdownMenuItem<String>(
                                  value: day,
                                  child: Text(day),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    selectedDay = value;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await selectTime(context);
                                      if (picked != null) {
                                        setState(() {
                                          startTime = picked;
                                        });
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Start Time',
                                        border: OutlineInputBorder(),
                                      ),
                                      child: Text(formatTimeOfDay(startTime)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await selectTime(context);
                                      if (picked != null) {
                                        setState(() {
                                          endTime = picked;
                                        });
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'End Time',
                                        border: OutlineInputBorder(),
                                      ),
                                      child: Text(formatTimeOfDay(endTime)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: roomController,
                              decoration: const InputDecoration(
                                labelText: 'Room',
                                hintText: 'e.g. A101',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a room';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: buildingController,
                              decoration: const InputDecoration(
                                labelText: 'Building (Optional)',
                                hintText: 'e.g. Engineering Building',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                if (!isLoadingCourses && teacherCourses.isNotEmpty)
                  FilledButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        // Check permission again before submitting
                        final hasPermission = await _authService.isAdmin() || 
                                              await _authService.isSupervisor();
                        if (!hasPermission) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You do not have permission to create schedules'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          Navigator.pop(context);
                          return;
                        }

                        // Check if end time is after start time
                        final startMinutes =
                            startTime.hour * 60 + startTime.minute;
                        final endMinutes = endTime.hour * 60 + endTime.minute;

                        if (endMinutes <= startMinutes) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('End time must be after start time'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        Navigator.pop(context);

                        // Show loading indicator
                        setState(() => _isLoading = true);

                        // Add schedule entry
                        final result = await _scheduleService.addScheduleEntry(
                          courseId: selectedCourseId,
                          dayOfWeek: selectedDay,
                          startTime: formatTimeOfDay(startTime),
                          endTime: formatTimeOfDay(endTime),
                          room: roomController.text,
                          building: buildingController.text.isEmpty
                              ? null
                              : buildingController.text,
                        );

                        setState(() => _isLoading = false);

                        if (result['success']) {
                          // Reload schedule
                          _loadTeacherSchedule();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Schedule entry added successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Error adding schedule entry: ${result['message']}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Add Schedule'),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
