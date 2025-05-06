import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:typed_data';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import 'package:logging/logging.dart';
import '../utils/storage_rls_helper.dart';

class ProfileManagementScreen extends StatefulWidget {
  static const String routeName = '/profile_management';

  const ProfileManagementScreen({Key? key}) : super(key: key);

  @override
  State<ProfileManagementScreen> createState() =>
      _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> {
  final _supabase = Supabase.instance.client;
  final _authService = AuthService();
  final _logger = Logger('ProfileManagementScreen');

  bool _isLoading = false;
  List<Map<String, dynamic>> _users = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Constants
  static const String profileImagesBucket = 'profile-images';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      case 'bmp':
        return 'bmp';
      default:
        return 'jpeg'; // Default to JPEG for unknown formats
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _getRoleBadgeColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'FF5733'; // Red
      case 'teacher':
        return '33A8FF'; // Blue
      case 'student':
        return '33FF57'; // Green
      case 'staff':
        return 'FF33F6'; // Purple
      case 'supervisor':
        return 'F7CA18'; // Yellow
      default:
        return 'CCCCCC'; // Gray for undefined roles
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _viewUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user['full_name']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: user['profile_picture_url'] != null
                      ? NetworkImage(user['profile_picture_url'])
                      : null,
                  child: user['profile_picture_url'] == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              _infoRow('ID', user['id'] ?? 'N/A'),
              _infoRow('Email', user['email'] ?? 'N/A'),
              _infoRow('Role', user['role'] ?? 'N/A'),
              _infoRow('Status', user['status'] ?? 'N/A'),
              _infoRow('Created', _formatDate(user['created_at'])),
              _infoRow('Last Updated', _formatDate(user['updated_at'])),
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
        // If not admin, just load the current user
        final currentUser = _supabase.auth.currentUser;
        if (currentUser == null) {
          throw Exception('User not authenticated');
        }

        // Get current user's details
        final response = await _supabase
            .from(AppConstants.tableUsers)
            .select()
            .eq('id', currentUser.id)
            .limit(1)
            .single();

        if (response != null) {
          setState(() {
            _users = [response];
            _isLoading = false;
          });
        } else {
          throw Exception('Failed to load user profile');
        }
        return;
      }

      // For admins, load all users
      final response = await _supabase
          .from(AppConstants.tableUsers)
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      _logger.severe('Error loading users', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredUsers() {
    if (_searchQuery.isEmpty) return _users;

    return _users
        .where((user) =>
            (user['full_name']
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false) ||
            (user['email']
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false) ||
            (user['role']?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                false))
        .toList();
  }

  Future<void> _changeUserProfilePicture(Map<String, dynamic> user) async {
    try {
      final imagePicker = ImagePicker();
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      // Upload the image to Supabase Storage
      final userId = user['id'];
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.${_getFileExtension(image)}';

      // Use the specified bucket name
      const bucketName = profileImagesBucket;

      // Storage path: userId/fileName
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
      _logger.info('Current User ID: ${currentUser.id}');
      _logger.info('Target User ID for upload: $userId');

      try {
        // Check if bucket exists and create if needed
        try {
          final buckets = await _supabase.storage.listBuckets();
          bool bucketExists =
              buckets.any((bucket) => bucket.name == bucketName);

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
        } catch (e) {
          // Log this but continue - admin might still have access
          _logger.warning('Error checking/creating bucket: $e');
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
        } // Upload mechanism depends on user role
        final isAdmin = await _authService.isAdmin();
        final isOwnProfile = currentUser.id == userId;

        // First ensure the bucket exists using our admin function
        try {
          // This will create the bucket with proper RLS if it doesn't exist
          await _supabase.rpc('admin_ensure_bucket_exists',
              params: {'bucket_name': bucketName});
          _logger.info('Bucket existence checked and ensured via RPC');
        } catch (rpcError) {
          _logger.warning('Error in bucket creation RPC: $rpcError');
          // Continue anyway - the bucket might already exist
        }

        if (isAdmin && !isOwnProfile) {
          // For admin uploading someone else's picture, try using the enhanced RPC function
          try {
            await _supabase.rpc('upload_profile_picture',
                params: {'user_id': userId, 'file_name': fileName});
            _logger.info('Admin privileges applied for upload operation');
          } catch (adminError) {
            _logger.warning('Error in admin RPC call: $adminError');
            // Will continue with normal upload below
          }
        }

        // Upload the file using standard method
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
      String errorMessage;
      final errorStr = e.toString();

      if (errorStr.contains('row-level security policy')) {
        errorMessage =
            'Permission denied: Check Supabase RLS policies for profile images.\n'
            'Make sure to run the SQL setup in the docs folder to configure proper RLS policies.';
        _logger.severe(
            'RLS policy violation. Make sure the SQL in docs/supabase_rls_profiles.sql '
            'and docs/supabase_admin_functions.sql has been executed in Supabase SQL Editor.');
      } else if (errorStr.contains('bucket not found')) {
        errorMessage =
            'Bucket not found: Please ensure the "profile-images" bucket exists in Supabase Storage.';
        _logger.severe(
            'Bucket not found. Try running the admin_ensure_bucket_exists RPC function.');
      } else if (errorStr.contains('401') ||
          errorStr.contains('authentication')) {
        errorMessage =
            'Authentication error: Please sign in again with appropriate permissions.';
      } else if (errorStr.contains('permission') || errorStr.contains('403')) {
        errorMessage =
            'Permission denied: Your account does not have the required permissions for this action.';
      } else if (errorStr.contains('storage') || errorStr.contains('upload')) {
        errorMessage =
            'Storage error: There was a problem uploading the image. Please try again.';
      } else {
        final maxLength = errorStr.length > 100 ? 100 : errorStr.length;
        errorMessage = 'Error: ${errorStr.substring(0, maxLength)}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'DETAILS',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Error Details'),
                    content: SingleChildScrollView(
                      child: Text(errorStr),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('CLOSE'),
                      ),
                    ],
                  ),
                );
              },
            ),
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
    final filteredUsers = _getFilteredUsers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Management'),
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search Users',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: filteredUsers.isEmpty
                      ? const Center(child: Text('No users found'))
                      : ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];

                            // Get role badge color
                            final badgeColor = Color(int.parse(
                                    _getRoleBadgeColor(user['role'] ?? ''),
                                    radix: 16) |
                                0xFF000000);

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                vertical: 4.0,
                                horizontal: 8.0,
                              ),
                              elevation: 2.0,
                              child: ListTile(
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage:
                                          user['profile_picture_url'] != null
                                              ? NetworkImage(
                                                  user['profile_picture_url'])
                                              : null,
                                      child: user['profile_picture_url'] == null
                                          ? const Icon(Icons.person)
                                          : null,
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 15,
                                        height: 15,
                                        decoration: BoxDecoration(
                                          color: user['status'] == 'active'
                                              ? Colors.green
                                              : Colors.grey,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                title:
                                    Text(user['full_name'] ?? 'Unknown User'),
                                subtitle: Text(user['email'] ?? 'No email'),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    user['role'] ?? 'Unknown Role',
                                    style: TextStyle(
                                      color: badgeColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                onTap: () => _viewUserDetails(user),
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
