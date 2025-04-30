import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/logger_service.dart';

class UserProfileEditScreen extends StatefulWidget {
  final String userId;
  
  const UserProfileEditScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfileEditScreen> createState() => _UserProfileEditScreenState();
}

class _UserProfileEditScreenState extends State<UserProfileEditScreen> {
  final _supabase = Supabase.instance.client;
  final _authService = AuthService();
  final _storageService = StorageService();
  final _logger = LoggerService.getLoggerForName('UserProfileEditScreen');
  
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isAdmin = false;
  File? _selectedImage;
  String? _profilePictureUrl;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkAdminStatus();
  }
  
  Future<void> _checkAdminStatus() async {
    final isAdmin = await _authService.isAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }
  
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get user data
      final response = await _supabase
          .from('users')
          .select('*')
          .eq('id', widget.userId)
          .single();
          
      if (mounted) {
        setState(() {
          _userData = response;
          _profilePictureUrl = response['profile_picture_url'];
        });
      }    } catch (e) {
      _logger.severe('Error loading user data', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user data: $e'),
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
  
  Future<void> _selectAndUploadImage() async {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only administrators can upload profile pictures'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image == null) return;
      
      setState(() {
        _selectedImage = File(image.path);
        _isUploading = true;
      });
      
      // Upload the image
      final result = await _storageService.uploadProfilePicture(
        _selectedImage!,
        widget.userId,
      );
      
      if (result['success']) {
        if (mounted) {
          setState(() {
            _profilePictureUrl = result['url'];
            _isUploading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? const Center(child: Text('User not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Profile picture section
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          // Profile picture
                          CircleAvatar(
                            radius: 80,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _profilePictureUrl != null
                                ? NetworkImage(_profilePictureUrl!)
                                : null,
                            child: _profilePictureUrl == null
                                ? Text(
                                    _userData?['full_name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                                    style: const TextStyle(
                                      fontSize: 60,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  )
                                : null,
                          ),
                          // Upload button - only for admins
                          if (_isAdmin)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: _isUploading
                                  ? const CircularProgressIndicator()
                                  : Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Theme.of(context).primaryColor,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onPressed: _selectAndUploadImage,
                                        ),
                                      ),
                                    ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _userData?['full_name'] ?? 'Unnamed User',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getRoleColor(_userData?['role']),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _userData?['role']?.toString().toUpperCase() ?? 'UNKNOWN',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // User details
                      _buildDetailsCard(),
                      const SizedBox(height: 16),
                      if (!_isAdmin)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Only administrators can modify user profiles.',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildDetailsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Email', _userData!['email'] ?? 'Not provided'),
            const Divider(),
            _buildInfoRow('Status', _userData!['status'] ?? 'Unknown'),
            const Divider(),
            _buildInfoRow('Account created', _formatDate(_userData!['created_at'])),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'supervisor':
        return Colors.teal;
      case 'teacher':
        return Colors.blue;
      case 'student':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
  
  String _formatDate(dynamic dateString) {
    if (dateString == null) return 'Unknown';
    
    try {
      final date = DateTime.parse(dateString.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString.toString();
    }
  }
}
