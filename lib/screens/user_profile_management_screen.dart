import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import 'package:logging/logging.dart';

class UserProfileManagementScreen extends StatefulWidget {
  const UserProfileManagementScreen({super.key});

  @override
  State<UserProfileManagementScreen> createState() =>
      _UserProfileManagementScreenState();
}

class _UserProfileManagementScreenState
    extends State<UserProfileManagementScreen> {
  final _supabase = Supabase.instance.client;
  final _authService = AuthService();
  final _logger = Logger('UserProfileManagementScreen');

  bool _isLoading = false;
  List<Map<String, dynamic>> _users = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      // Check admin status first
      final isAdmin = await _authService.isAdmin();
      if (!isAdmin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('You do not have permission to access this feature'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      // Get all users
      final response = await _supabase
          .from('users')
          .select('*')
          .order('full_name', ascending: true);

      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      _logger.severe('Error loading users', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return _users;
    }
    return _users
        .where((user) =>
            (user['full_name']
                    ?.toString()
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false) ||
            (user['email']
                    ?.toString()
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false) ||
            (user['role']
                    ?.toString()
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false))
        .toList();
  }

  Future<void> _changeUserProfilePicture(Map<String, dynamic> user) async {
    final imagePicker = ImagePicker();
    final XFile? image =
        await imagePicker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      // Upload the image to Supabase Storage
      final userId = user['id'];
      final imageFile = File(image.path);
      final fileExt = image.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final storagePath = 'profile_pictures/$userId/$fileName';

      await _supabase.storage.from('avatars').upload(
            storagePath,
            imageFile,
          );

      // Get the public URL of the uploaded image
      final imageUrl =
          _supabase.storage.from('avatars').getPublicUrl(storagePath);

      // Update the user's profile_picture_url in the database
      await _supabase
          .from('users')
          .update({'profile_picture_url': imageUrl}).eq('id', userId);

      // Refresh the users list
      await _loadUsers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.severe('Error updating profile picture', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile picture: $e'),
            backgroundColor: Colors.red,
          ),
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
        title: const Text('User Profile Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _filteredUsers.isEmpty
                        ? const Center(child: Text('No users found'))
                        : ListView.builder(
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        _getRoleColor(user['role']),
                                    backgroundImage:
                                        user['profile_picture_url'] != null
                                            ? NetworkImage(
                                                user['profile_picture_url'])
                                            : null,
                                    child: user['profile_picture_url'] == null
                                        ? Text(
                                            (user['full_name'] as String?)
                                                        ?.isNotEmpty ==
                                                    true
                                                ? (user['full_name'] as String)
                                                    .substring(0, 1)
                                                    .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                  title: Text(user['full_name'] ?? 'No Name'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(user['email'] ?? 'No Email'),
                                      Text(
                                          'Role: ${(user['role'] as String?)?.toUpperCase() ?? 'Unknown'}'),
                                    ],
                                  ),
                                  isThreeLine: true,
                                  trailing: IconButton(
                                    icon: const Icon(Icons.photo_camera),
                                    onPressed: () =>
                                        _changeUserProfilePicture(user),
                                    tooltip: 'Change profile picture',
                                  ),
                                  onTap: () => _showUserDetailsDialog(user),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showUserDetailsDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user['full_name'] ?? 'User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (user['profile_picture_url'] != null)
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(user['profile_picture_url']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              _infoRow('Email', user['email'] ?? 'Not provided'),
              _infoRow('Role',
                  (user['role'] as String?)?.toUpperCase() ?? 'Unknown'),
              if (user['department_id'] != null)
                _infoRow('Department ID', user['department_id'].toString()),
              if (user['created_at'] != null)
                _infoRow('Joined', _formatDate(user['created_at'])),
              if (user['last_login'] != null)
                _infoRow('Last Login', _formatDate(user['last_login'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _changeUserProfilePicture(user);
            },
            child: const Text('Change Picture'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'supervisor':
        return Colors.teal;
      case 'teacher':
        return Colors.blue;
      case 'student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
