import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/announcement_service.dart';
import '../services/course_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final AnnouncementService _announcementService = AnnouncementService();
  final CourseService _courseService = CourseService();
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = true;
  bool _isLoadingCourses = true;
  String _userRole = '';
  String? _departmentId;
  String? _selectedCourseId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserDataAndAnnouncements();
    _loadCourses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDataAndAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _userRole = user['role'];
        _departmentId = user['department_id'];
      }

      // Initialize tab controller
      _tabController.addListener(() {
        if (!_tabController.indexIsChanging) {
          _refreshAnnouncements();
        }
      });

      await _refreshAnnouncements();
    } catch (e) {
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

  Future<void> _loadCourses() async {
    setState(() => _isLoadingCourses = true);
    try {
      if (_userRole == 'student') {
        _courses = await _courseService.getEnrolledCourses();
      } else if (_userRole == 'teacher') {
        _courses = await _courseService.getTeacherCourses();
      } else {
        _courses = await _courseService.getAllCourses();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading courses: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingCourses = false);
      }
    }
  }

  Future<void> _refreshAnnouncements() async {
    try {
      final announcements = await _announcementService.getAnnouncements(
        courseId: _tabController.index == 1 ? _selectedCourseId : null,
      );
      if (mounted) {
        setState(() => _announcements = announcements);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading announcements: $e')),
        );
      }
    }
  }

  Future<void> _showCreateAnnouncementDialog() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String importance = 'medium';
    DateTime? validUntil;
    List<String> selectedRoles = ['student', 'teacher', 'supervisor', 'admin'];
    String? selectedCourseId;
    bool isCourseAnnouncement = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Announcement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Content'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: importance,
                  decoration: const InputDecoration(labelText: 'Importance'),
                  items: ['low', 'medium', 'high', 'urgent']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => importance = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Course-specific announcement'),
                  value: isCourseAnnouncement,
                  onChanged: (value) {
                    setState(() => isCourseAnnouncement = value);
                    if (!value) {
                      selectedCourseId = null;
                    }
                  },
                ),
                if (isCourseAnnouncement && _courses.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCourseId,
                    decoration:
                        const InputDecoration(labelText: 'Select Course'),
                    items: _courses.map<DropdownMenuItem<String>>((course) {                      final String title = course['title'] ?? 'Untitled';
                      final String code = course['course_code'] ?? '';
                      return DropdownMenuItem<String>(
                        value: course['id'],
                        child: Text('$code: $title'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedCourseId = value);
                    },
                    hint: const Text('Select a course'),
                  ),
                ] else if (isCourseAnnouncement && _courses.isEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('No courses available to select',
                      style: TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                ListTile(
                  title: Text(validUntil == null
                      ? 'No expiration date'
                      : 'Expires: ${validUntil!.toLocal()}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => validUntil = date);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Target Roles:'),
                ...['student', 'teacher', 'supervisor', 'admin'].map((role) {
                  return CheckboxListTile(
                    title: Text(role),
                    value: selectedRoles.contains(role),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value ?? false) {
                          selectedRoles.add(role);
                        } else {
                          selectedRoles.remove(role);
                        }
                      });
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      try {
        await _announcementService.createAnnouncement(
          title: titleController.text,
          content: contentController.text,
          departmentId: _departmentId,
          targetRoles: selectedRoles,
          importance: importance,
          validUntil: validUntil,
          courseId: isCourseAnnouncement ? selectedCourseId : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement created successfully')),
          );
          _refreshAnnouncements();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating announcement: $e')),
          );
        }
      }
    }
  }

  bool _canCreateAnnouncements() {
    return ['admin', 'supervisor', 'teacher'].contains(_userRole);
  }

  bool _canDeleteAnnouncements() {
    return _userRole == 'admin';
  }

  Future<void> _deleteAnnouncement(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text(
            'Are you sure you want to permanently delete this announcement?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        await _announcementService.deleteAnnouncement(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement deleted successfully')),
          );
          _refreshAnnouncements();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting announcement: $e')),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    final createdAt = DateTime.parse(announcement['created_at']);
    final importance = announcement['importance'] as String;
    final creator = announcement['creator'] as Map<String, dynamic>?;
    final String creatorName = creator?['full_name'] ?? 'Unknown';
    final String? profilePictureUrl = creator?['profile_picture_url'];
    final course = announcement['course'] as Map<String, dynamic>?;

    Color importanceColor;
    switch (importance) {
      case 'urgent':
        importanceColor = Colors.red;
        break;
      case 'high':
        importanceColor = Colors.orange;
        break;
      case 'medium':
        importanceColor = Colors.blue;
        break;
      default:
        importanceColor = Colors.green;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: importanceColor.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with importance color
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: importanceColor.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 12,
                  color: importanceColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    announcement['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (_canDeleteAnnouncements())
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteAnnouncement(announcement['id']),
                    tooltip: 'Delete Announcement',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),

          // Content area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course info if available
                if (course != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Course: ${course['course_code'] ?? ''} ${course['title'] ?? ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Announcement content
                Text(
                  announcement['content'],
                  style: const TextStyle(height: 1.4),
                ),

                const SizedBox(height: 16),

                // Footer with poster info and dates
                Row(
                  children: [
                    // Creator profile picture
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: profilePictureUrl != null
                          ? NetworkImage(profilePictureUrl)
                          : null,
                      backgroundColor: Colors.grey.shade200,
                      child: profilePictureUrl == null
                          ? Text(
                              creatorName.isNotEmpty
                                  ? creatorName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),

                    // Creator name and post time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            creatorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Posted ${timeago.format(createdAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Expiration info if any
                    if (announcement['valid_until'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Expires ${timeago.format(DateTime.parse(announcement['valid_until']))}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        actions: [
          if (_canCreateAnnouncements())
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showCreateAnnouncementDialog,
              tooltip: 'Create Announcement',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() {
              // When switching to course tab, refresh with course filter
              if (index == 1 && _selectedCourseId != null) {
                _refreshAnnouncements();
              } else if (index == 0) {
                // When going to All tab, refresh without filter
                _refreshAnnouncements();
              }
            });
          },
          tabs: const [
            Tab(text: 'All Announcements'),
            Tab(text: 'Course Announcements'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // All Announcements Tab
                RefreshIndicator(
                  onRefresh: _refreshAnnouncements,
                  child: _announcements.isEmpty
                      ? const Center(child: Text('No announcements available'))
                      : ListView.builder(
                          itemCount: _announcements.length,
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) =>
                              _buildAnnouncementCard(_announcements[index]),
                        ),
                ),

                // Course Announcements Tab
                _isLoadingCourses
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          // Course selection dropdown
                          if (_courses.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Select Course',
                                  border: OutlineInputBorder(),
                                ),
                                value: _selectedCourseId,
                                items: _courses
                                    .map<DropdownMenuItem<String>>((course) {
                                  final String title =
                                      course['title'] ?? 'Untitled';                                  final String code = course['course_code'] ?? '';
                                  return DropdownMenuItem<String>(
                                    value: course['id'],
                                    child: Text('$code: $title'),
                                  );
                                }).toList(),
                                onChanged: (String? value) {
                                  setState(() {
                                    _selectedCourseId = value;
                                    _refreshAnnouncements();
                                  });
                                },
                                hint: const Text(
                                    'Select a course to view announcements'),
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: Text('No courses available'),
                              ),
                            ),

                          // Course announcements list
                          Expanded(
                            child: _selectedCourseId == null
                                ? const Center(
                                    child: Text('Please select a course'))
                                : RefreshIndicator(
                                    onRefresh: _refreshAnnouncements,
                                    child: _announcements.isEmpty
                                        ? const Center(
                                            child: Text(
                                                'No course announcements available'))
                                        : ListView.builder(
                                            itemCount: _announcements.length,
                                            padding: const EdgeInsets.all(16),
                                            itemBuilder: (context, index) =>
                                                _buildAnnouncementCard(
                                                    _announcements[index]),
                                          ),
                                  ),
                          ),
                        ],
                      ),
              ],
            ),
    );
  }
}
