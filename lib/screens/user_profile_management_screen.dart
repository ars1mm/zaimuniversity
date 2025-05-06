import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:typed_data';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import 'package:logging/logging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserProfileManagementScreen extends StatefulWidget {
  const UserProfileManagementScreen({Key? key}) : super(key: key);

  // Adding a factory constructor to ensure this class can be properly instantiated
  factory UserProfileManagementScreen.create() {
    return const UserProfileManagementScreen();
  }

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
    _logger.info(
        'S3 Secret Key from env: ${dotenv.env['SUPABASE_S3_SECRET_KEY']?.substring(0, 5)}...');
  }

  // Helper methods
  String _getFileExtension(XFile file) {
    final extension = file.name.split('.').last.toLowerCase();
    // Normalize the extension to ensure compatibility
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      default:
        return 'jpeg'; // Default to jpeg for unknown types
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
    try {
      final imagePicker = ImagePicker();
      final XFile? image =
          await imagePicker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      setState(() => _isLoading = true); // Upload the image to Supabase Storage
      final userId = user['id'];
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.${_getFileExtension(image)}';

      // Use 'profile-images' bucket to match RLS policies
      const bucketName = 'profile-images';

      // Simplify the storage path to avoid deep nesting
      final storagePath = '$userId/$fileName';

      // Get image bytes
      final Uint8List fileBytes = await image.readAsBytes();

      // Get mime type
      final String contentType =
          'image/${_getFileExtension(image).toLowerCase()}';
      _logger.info(
          'Uploading image to $storagePath with content type $contentType');

      // For RLS purposes, ensure the user is authenticated
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to upload profile pictures');
      }

      // Log authentication info for debugging
      _logger.info('Admin User ID: ${currentUser.id}');
      _logger.info('Target User ID for upload: $userId');

      try {
        // Check if storage service is accessible
        await _supabase.storage.listBuckets();
        _logger.info('Storage service is accessible');

        // Check if bucket exists
        final buckets = await _supabase.storage.listBuckets();
        bool bucketExists = buckets.any((bucket) => bucket.name == bucketName);

        if (!bucketExists) {
          // Create the bucket with public access and proper RLS policies
          _logger.info('Creating bucket: $bucketName');
          await _supabase.storage.createBucket(
            bucketName,
            const BucketOptions(
              public: true,
              fileSizeLimit: '5242880', // 5MB limit
            ),
          );

          // Wait a moment for bucket creation to propagate
          await Future.delayed(const Duration(seconds: 1));
        }

        // Check for existing files and remove them to avoid clutter
        try {
          final existingFiles =
              await _supabase.storage.from(bucketName).list(path: userId);
          _logger
              .info('Found ${existingFiles.length} existing profile pictures');

          // Delete existing files if there are any
          if (existingFiles.isNotEmpty) {
            for (final file in existingFiles) {
              await _supabase.storage
                  .from(bucketName)
                  .remove(['$userId/${file.name}']);
            }
            _logger.info('Cleaned up existing profile pictures');
          }
        } catch (e) {
          // Just log this error, don't throw - we'll continue with upload
          _logger.warning('Error checking for existing files: $e');
        }

        // Important: Use RPC call to authenticate as service role for admin operations
        // This bypasses RLS policies for the admin user
        await _supabase.rpc('upload_profile_picture',
            params: {'user_id': userId, 'file_name': fileName});

        // Now that the policy is temporarily bypassed for this operation, upload the file
        await _supabase.storage.from(bucketName).uploadBinary(
              storagePath,
              fileBytes,
              fileOptions: FileOptions(
                contentType: contentType,
                upsert: true, // Override if exists
              ),
            );

        // Get the public URL of the uploaded image
        final imageUrl =
            _supabase.storage.from(bucketName).getPublicUrl(storagePath);

        // Update the user's profile_picture_url in the database
        await _supabase
            .from(AppConstants.tableUsers)
            .update({'profile_picture_url': imageUrl}).eq('id', userId);

        _logger.info('Updated profile picture URL in database: $imageUrl');

        // Refresh the users list
        await _loadUsers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (storageError) {
        _logger.severe('Error in storage operations: $storageError');
        throw storageError; // Re-throw to be caught by the outer catch
      }
    } catch (e) {
      _logger.severe('Error updating profile picture', e);

      // Provide specific error messages based on the error type
      String errorMessage = 'Error updating profile picture';
      if (e.toString().contains('row-level security policy')) {
        errorMessage =
            'Permission denied: Admin role requires additional storage permissions. Please check Supabase RLS policies.';
      } else if (e.toString().contains('bucket not found')) {
        errorMessage = 'Bucket not found: The storage bucket does not exist';
      } else if (e.toString().contains('401')) {
        errorMessage = 'Authentication error: Please sign in again';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
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
}
