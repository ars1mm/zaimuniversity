import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import './auth_service.dart';
import 'logger_service.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();
  final _logger = LoggerService.getLoggerForName('StorageService');
  static const String _tag = 'StorageService';

  // // Use storage URL from environment variables
  // final String _storageUrl = dotenv.env['SUPABASE_STORAGE_URL'] ??
  //     'https://uvurktstrcbcqzzuupeq.supabase.co/storage/v1/s3';
  // The bucket where user profile pictures will be stored
  static const String profileBucket = 'profile-images';

  // Ensure the bucket exists
  Future<void> _initializeBucket() async {
    try {
      await _supabase.storage.createBucket(
        profileBucket,
        const BucketOptions(
          public: true, // Public bucket to match our RLS policies
          fileSizeLimit: '5242880', // 5MB limit as string
        ),
      );
      _logger.info('[$_tag] Bucket initialized successfully');
    } catch (e) {
      // Bucket might already exist, which is fine
      _logger.fine('[$_tag] Bucket may already exist: $e');
    }
  }

  // Upload a profile picture for a user - admin only
  Future<Map<String, dynamic>> uploadProfilePicture(
      File imageFile, String userId) async {
    try {
      // Check if current user is admin
      final isAdmin = await _authService.isAdmin();

      if (!isAdmin) {
        _logger
            .warning('[$_tag] Non-admin attempted to upload profile picture');
        return {
          'success': false,
          'message': 'Only administrators can upload profile pictures',
          'url': null,
        };
      }

      // Initialize bucket if not exists
      await _initializeBucket();

      // Generate a unique filename for the image
      final fileExt = path.extension(imageFile.path);
      final fileName = '${const Uuid().v4()}$fileExt';

      // Upload the file to Supabase storage
      await _supabase.storage
          .from(profileBucket)
          .upload('$userId/$fileName', imageFile);

      // Get the public URL of the uploaded image
      final String imageUrl = _supabase.storage.from(profileBucket).getPublicUrl(
          '$userId/$fileName'); // Update the user's profile with the image URL
      // Cast userId to UUID to avoid "operator does not exist: text = uuid" error
      await _supabase.from('users').update(
          {'profile_picture_url': imageUrl}).eq('id', userId.toString());

      _logger.info(
          '[$_tag] Profile picture uploaded successfully for user $userId');
      return {
        'success': true,
        'message': 'Profile picture uploaded successfully',
        'url': imageUrl,
      };
    } catch (e) {
      _logger.severe('[$_tag] Error uploading profile picture', e);
      return {
        'success': false,
        'message': 'Error uploading profile picture: $e',
        'url': null,
      };
    }
  }

  // Get the profile picture URL for a user
  Future<String?> getProfilePictureUrl(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('profile_picture_url')
          .eq('id', userId)
          .single();

      return response['profile_picture_url'] as String?;
    } catch (e) {
      _logger.severe('[$_tag] Error getting profile picture URL', e);
      return null;
    }
  }

  // Delete a user's profile picture - admin only
  Future<bool> deleteProfilePicture(String userId, String fileName) async {
    try {
      // Check if current user is admin
      final isAdmin = await _authService.isAdmin();

      if (!isAdmin) {
        _logger
            .warning('[$_tag] Non-admin attempted to delete profile picture');
        return false;
      }

      // Delete the file from storage
      await _supabase.storage.from(profileBucket).remove(['$userId/$fileName']);

      // Update the user record
      await _supabase
          .from('users')
          .update({'profile_picture_url': null}).eq('id', userId.toString());

      _logger.info('[$_tag] Profile picture deleted for user $userId');
      return true;
    } catch (e) {
      _logger.severe('[$_tag] Error deleting profile picture', e);
      return false;
    }
  }
}
