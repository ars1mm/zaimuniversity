import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../services/student_schedule_service.dart';

class StudentScheduleScreen extends StatefulWidget {
  static const String routeName = '/student_schedule';

  const StudentScheduleScreen({super.key});

  @override
  State<StudentScheduleScreen> createState() => _StudentScheduleScreenState();
}

class _StudentScheduleScreenState extends State<StudentScheduleScreen> {
  final Logger _logger = Logger('StudentScheduleScreen');
  final StudentScheduleService _scheduleService = StudentScheduleService();
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _scheduleByDay = {};
  int _selectedDayIndex = DateTime.now().weekday - 1; // Default to current day (0-based)
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
    _loadStudentSchedule();
  }

  Future<void> _loadStudentSchedule() async {
    setState(() => _isLoading = true);

    try {
      // Use the service to get the schedule
      final scheduleMap = await _scheduleService.getStudentSchedule();

      if (mounted) {
        setState(() {
          _scheduleByDay = scheduleMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.severe('Error loading student schedule', e);
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
        title: const Text('My Class Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudentSchedule,
            tooltip: 'Refresh Schedule',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Day selector
                Container(
                  height: 60,
                  color: Theme.of(context).primaryColor.withValues(alpha: 26, red: 0, green: 0, blue: 0),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _weekdays.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedDayIndex == index;
                      final day = _weekdays[index];
                      final hasClasses = _scheduleByDay[day]?.isNotEmpty ?? false;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedDayIndex = index),
                        child: Container(
                          width: MediaQuery.of(context).size.width / 4,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.secondary
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                day.substring(0, 3),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : null,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (hasClasses)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context).colorScheme.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Schedule for selected day
                Expanded(
                  child: _buildDaySchedule(_weekdays[_selectedDayIndex]),
                ),
              ],
            ),
    );
  }

  Widget _buildDaySchedule(String day) {
    final schedules = _scheduleByDay[day] ?? [];

    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No classes scheduled for $day',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        final startTime = schedule['start_time'] ?? '00:00';
        final endTime = schedule['end_time'] ?? '00:00';
        final courseTitle = schedule['course_title'] ?? 'Unknown Course';
        final courseCode = schedule['course_code'] ?? '';
        final room = schedule['room'] ?? 'TBA';
        final building = schedule['building'] ?? '';
        final teacherName = schedule['teacher_name'] ?? 'Unassigned';
        final location = [room, building].where((e) => e.isNotEmpty).join(', ');

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Time slot
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$startTime - $endTime',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Course code
                    if (courseCode.isNotEmpty)
                      Text(
                        courseCode,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Course title
                Text(
                  courseTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      location.isNotEmpty ? location : 'Location TBA',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Teacher
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      'Instructor: $teacherName',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
