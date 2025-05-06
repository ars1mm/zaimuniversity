# Supabase Storage Implementation for Flutter

This document provides practical examples and implementation details for integrating Supabase Storage into the Campus Information System Flutter application.

## Table of Contents

1. [Initialization](#initialization)
2. [User Profile Picture Management](#user-profile-picture-management)
3. [Implementing Image Picker](#implementing-image-picker)
4. [Handling Image Upload](#handling-image-upload)
5. [Viewing and Displaying Images](#viewing-and-displaying-images)
6. [Error Handling](#error-handling)
7. [Storage Service](#storage-service)

## Initialization

Ensure your Supabase client is properly initialized in your app:

```dart
// In main.dart or initialization file
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> initializeSupabase() async {
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
}

// Global access to Supabase client
final supabase = Supabase.instance.client;
```

## User Profile Picture Management

### Create a Storage Service

Create a dedicated service for handling storage operations:

```dart
// lib/services/storage_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';  // For accessing the global supabase client

class StorageService {
  final _storage = supabase.storage;
  
  // Upload a profile picture for the current user
  Future<String?> uploadProfilePicture(File imageFile) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;
      
      // Generate a unique file name
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';
      
      // Upload file to Supabase Storage
      await _storage
          .from('profile_pictures')
          .upload(filePath, imageFile);
      
      // Get public URL for the uploaded image
      final imageUrl = _storage
          .from('profile_pictures')
          .getPublicUrl(filePath);
      
      // Update the user's profile with the new image URL
      await supabase
          .from('users')
          .update({'profile_picture_url': imageUrl})
          .eq('id', userId);
      
      return imageUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }
  
  // Delete a profile picture
  Future<bool> deleteProfilePicture(String imageUrl) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;
      
      // Extract the file path from the URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // The file path should be something like 'user_id/filename.jpg'
      final filePath = '${pathSegments[pathSegments.length - 2]}/${pathSegments.last}';
      
      // Delete the file from storage
      await _storage
          .from('profile_pictures')
          .remove([filePath]);
      
      // Update user profile to remove the image URL
      await supabase
          .from('users')
          .update({'profile_picture_url': null})
          .eq('id', userId);
      
      return true;
    } catch (e) {
      print('Error deleting profile picture: $e');
      return false;
    }
  }
}
```

## Implementing Image Picker

Use the `image_picker` package to select images from the device:

```dart
// Add to pubspec.yaml:
// dependencies:
//   image_picker: ^latest_version

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';

class ProfilePictureWidget extends StatefulWidget {
  final String? initialImageUrl;
  final Function(String?) onImageUpdated;
  
  const ProfilePictureWidget({
    Key? key,
    this.initialImageUrl,
    required this.onImageUpdated,
  }) : super(key: key);
  
  @override
  _ProfilePictureWidgetState createState() => _ProfilePictureWidgetState();
}

class _ProfilePictureWidgetState extends State<ProfilePictureWidget> {
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();
  String? _imageUrl;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _imageUrl = widget.initialImageUrl;
  }
  
  Future<void> _pickAndUploadImage() async {
    // Pick an image from the gallery
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
    
    if (image == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Upload the image to Supabase Storage
      final imageUrl = await _storageService.uploadProfilePicture(File(image.path));
      
      if (imageUrl != null) {
        setState(() {
          _imageUrl = imageUrl;
        });
        widget.onImageUpdated(imageUrl);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey[200],
          backgroundImage: _imageUrl != null ? NetworkImage(_imageUrl!) : null,
          child: _imageUrl == null
              ? const Icon(Icons.person, size: 50, color: Colors.grey)
              : null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: _isLoading
              ? const CircularProgressIndicator()
              : IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: _pickAndUploadImage,
                  color: Theme.of(context).primaryColor,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                  ),
                ),
        ),
      ],
    );
  }
}
```

## Handling Image Upload

Example of how to use the profile picture widget in a user profile screen:

```dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/profile_picture_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userData = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _userData = userData;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _handleProfilePictureUpdated(String? newImageUrl) {
    if (_userData != null && newImageUrl != null) {
      setState(() {
        _userData!['profile_picture_url'] = newImageUrl;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? const Center(child: Text('Failed to load profile data'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ProfilePictureWidget(
                        initialImageUrl: _userData!['profile_picture_url'],
                        onImageUpdated: _handleProfilePictureUpdated,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _userData!['full_name'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _userData!['email'] ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Other profile fields and information
                    ],
                  ),
                ),
    );
  }
}
```

## Viewing and Displaying Images

For consistent display of user avatars throughout the app, create a reusable avatar widget:

```dart
// lib/widgets/user_avatar.dart
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final Color backgroundColor;
  
  const UserAvatar({
    Key? key,
    this.imageUrl,
    required this.name,
    this.radius = 20,
    this.backgroundColor = Colors.blue,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: imageUrl != null 
          ? NetworkImage(imageUrl!)
          : null,
      child: imageUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.7,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}
```

## Error Handling

Create an extension for handling storage errors:

```dart
// lib/extensions/supabase_extensions.dart
import 'package:supabase_flutter/supabase_flutter.dart';

extension SupabaseStorageExtension on SupabaseStorageClient {
  Future<T> handleStorageOperation<T>({
    required Future<T> Function() operation,
    required Function(String) onError,
  }) async {
    try {
      return await operation();
    } on StorageException catch (e) {
      final errorMessage = _getReadableStorageError(e);
      onError(errorMessage);
      rethrow;
    } catch (e) {
      onError('An unexpected error occurred: $e');
      rethrow;
    }
  }
  
  String _getReadableStorageError(StorageException e) {
    switch (e.statusCode) {
      case 400:
        return 'Invalid request: ${e.message}';
      case 401:
        return 'Unauthorized: You don\'t have permission to access this file';
      case 403:
        return 'Forbidden: Access denied';
      case 404:
        return 'File not found';
      case 409:
        return 'File conflict: The file might already exist';
      case 413:
        return 'File too large: Please upload a smaller file';
      case 500:
        return 'Server error: Please try again later';
      default:
        return 'Error: ${e.message}';
    }
  }
}
```

## Storage Service

Create a comprehensive storage service that handles all storage operations:

```dart
// lib/services/storage_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../extensions/supabase_extensions.dart';

class StorageService {
  final _storage = supabase.storage;
  
  // Profile pictures methods
  Future<String?> uploadProfilePicture(File imageFile) async {
    return await _storage.handleStorageOperation(
      operation: () async {
        final userId = supabase.auth.currentUser?.id;
        if (userId == null) throw Exception('User not authenticated');
        
        final fileExt = imageFile.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final filePath = '$userId/$fileName';
        
        await _storage.from('profile_pictures').upload(filePath, imageFile);
        
        final imageUrl = _storage.from('profile_pictures').getPublicUrl(filePath);
        
        await supabase
            .from('users')
            .update({'profile_picture_url': imageUrl})
            .eq('id', userId);
        
        return imageUrl;
      }, 
      onError: (msg) => debugPrint(msg),
    );
  }
  
  Future<bool> deleteProfilePicture(String imageUrl) async {
    return await _storage.handleStorageOperation(
      operation: () async {
        final userId = supabase.auth.currentUser?.id;
        if (userId == null) throw Exception('User not authenticated');
        
        // Extract the file path from the URL
        final uri = Uri.parse(imageUrl);
        final pathSegments = uri.pathSegments;
        final filePath = '${pathSegments[pathSegments.length - 2]}/${pathSegments.last}';
        
        await _storage.from('profile_pictures').remove([filePath]);
        
        await supabase
            .from('users')
            .update({'profile_picture_url': null})
            .eq('id', userId);
        
        return true;
      },
      onError: (msg) => debugPrint(msg),
    );
  }
  
  // General file storage methods
  Future<String?> uploadFile(String bucketName, File file, String folder) async {
    return await _storage.handleStorageOperation(
      operation: () async {
        final userId = supabase.auth.currentUser?.id;
        if (userId == null) throw Exception('User not authenticated');
        
        final fileExt = file.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final filePath = '$folder/$fileName';
        
        await _storage.from(bucketName).upload(filePath, file);
        
        return _storage.from(bucketName).getPublicUrl(filePath);
      },
      onError: (msg) => debugPrint(msg),
    );
  }
  
  Future<bool> deleteFile(String bucketName, String fileUrl) async {
    return await _storage.handleStorageOperation(
      operation: () async {
        // Extract the file path from the URL
        final uri = Uri.parse(fileUrl);
        final pathSegments = uri.pathSegments;
        final filePath = pathSegments.sublist(pathSegments.length - 2).join('/');
        
        await _storage.from(bucketName).remove([filePath]);
        return true;
      },
      onError: (msg) => debugPrint(msg),
    );
  }
  
  // List files in a folder
  Future<List<FileObject>> listFiles(String bucketName, String folder) async {
    return await _storage.handleStorageOperation(
      operation: () async {
        final result = await _storage.from(bucketName).list(path: folder);
        return result;
      },
      onError: (msg) => debugPrint(msg),
    );
  }
}
```

---

This implementation guide provides a comprehensive approach to managing file storage in your Flutter application. By following these patterns and using the provided service classes, you can efficiently handle image uploads, display user avatars, and manage storage operations throughout your application.

For more information, refer to the [Supabase Storage Documentation](https://supabase.com/docs/guides/storage).
