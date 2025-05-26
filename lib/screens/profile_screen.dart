import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      // Get the current authenticated user data safely
      final user = await _authService.getCurrentUser();
      if (user == null) {
        return;
      }

      if (mounted) {
        // Make sure we have a valid user object with required fields
        setState(() {
          _userData = user;

          // Set default values for any potentially missing fields to prevent null errors
          if (_userData!['full_name'] == null) {
            _userData!['full_name'] = 'User';
          }
          if (_userData!['email'] == null) {
            _userData!['email'] = 'No email provided';
          }
          if (_userData!['role'] == null) {
            _userData!['role'] = 'unknown';
          }
          if (_userData!['status'] == null) {
            _userData!['status'] = 'Active';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
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
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserProfile,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? const Center(child: Text('No profile information available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: _getProfileColor(_userData!['role']),
                        backgroundImage: _userData!['profile_picture_url'] !=
                                null
                            ? NetworkImage(_userData!['profile_picture_url'])
                            : null,
                        child: _userData!['profile_picture_url'] == null
                            ? Text(
                                (_userData!['full_name'] != null &&
                                        _userData!['full_name']
                                            .toString()
                                            .isNotEmpty)
                                    ? _userData!['full_name']
                                        .toString()
                                        .substring(0, 1)
                                        .toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _userData!['full_name'] ?? 'Unnamed User',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getProfileColor(_userData!['role']),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _userData!['role']?.toString().toUpperCase() ??
                              'UNKNOWN',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildProfileCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileCard() {
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
              'Profile Information',
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
            _buildInfoRow(
                'Account created', _formatDate(_userData!['created_at'])),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Note: Profile information is read-only. Contact administration for any changes.',
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

  Color _getProfileColor(String? role) {
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
