import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/announcement_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final AuthService _authService = AuthService();
  final AnnouncementService _announcementService = AnnouncementService();
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;
  String _userRole = '';
  String? _departmentId;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndAnnouncements();
  }

  Future<void> _loadUserDataAndAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _userRole = user['role'];
        _departmentId = user['department_id'];
      }
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

  Future<void> _refreshAnnouncements() async {
    try {
      final announcements = await _announcementService.getAnnouncements();
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
                ListTile(
                  title: Text(validUntil == null
                      ? 'No expiration date'
                      : 'Expires: ${validUntil!.toLocal()}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshAnnouncements,
              child: _announcements.isEmpty
                  ? const Center(child: Text('No announcements available'))
                  : ListView.builder(
                      itemCount: _announcements.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final announcement = _announcements[index];
                        final createdAt =
                            DateTime.parse(announcement['created_at']);
                        final importance =
                            announcement['importance'] as String;

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
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
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
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(announcement['content']),
                                const SizedBox(height: 8),
                                Text(
                                  'Posted ${timeago.format(createdAt)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (announcement['valid_until'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Expires: ${DateTime.parse(announcement['valid_until']).toLocal()}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(color: Colors.red),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
