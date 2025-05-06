import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import '../services/auth_service.dart';

/// Helper class for managing storage operations with Supabase RLS policies
class StorageRlsHelper {
  static final Logger _logger = Logger('StorageRlsHelper');
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final AuthService _authService = AuthService();

  /// Bucket name for profile images
  static const String profileImagesBucket = 'profile-images';

  /// Check if current user is an admin
  static Future<bool> isAdmin() async {
    return await _authService.isAdmin();
  }

  /// Check if the bucket exists
  static Future<bool> bucketExists(String bucketName) async {
    try {
      final buckets = await _supabase.storage.listBuckets();
      return buckets.any((bucket) => bucket.name == bucketName);
    } catch (e) {
      _logger.severe('Error checking if bucket exists: $e');
      return false;
    }
  }

  /// Ensure the bucket exists, create if not
  static Future<bool> ensureBucketExists(String bucketName,
      {bool isPublic = true}) async {
    try {
      if (!await bucketExists(bucketName)) {
        await _supabase.storage.createBucket(
          bucketName,
          BucketOptions(
            public: isPublic,
            fileSizeLimit: '5242880', // 5MB limit
          ),
        );

        // Wait for bucket creation to propagate
        await Future.delayed(const Duration(seconds: 1));
        return true;
      }
      return true;
    } catch (e) {
      _logger.severe('Error ensuring bucket exists: $e');
      return false;
    }
  }

  /// Clean up old profile pictures for a user
  static Future<void> cleanUpOldProfilePictures(
      String userId, String bucketName) async {
    try {
      final existingFiles =
          await _supabase.storage.from(bucketName).list(path: userId);
      _logger.info(
          'Found ${existingFiles.length} existing profile pictures for user $userId');

      if (existingFiles.isNotEmpty) {
        for (final file in existingFiles) {
          await _supabase.storage
              .from(bucketName)
              .remove(['$userId/${file.name}']);
        }
        _logger.info('Cleaned up existing profile pictures for user $userId');
      }
    } catch (e) {
      _logger.warning('Error checking for existing files: $e');
      // Don't throw, just log the error
    }
  }

  /// Use RPC to bypass RLS for admin operations
  static Future<void> bypassRlsForProfileUpload(
      String userId, String fileName) async {
    final isAdminUser = await isAdmin();
    if (!isAdminUser) {
      throw Exception('Only admins can perform this operation');
    }

    try {
      await _supabase.rpc('upload_profile_picture',
          params: {'user_id': userId, 'file_name': fileName});
    } catch (e) {
      _logger.severe('Error bypassing RLS for profile upload: $e');
      throw Exception('Failed to authorize admin operation: $e');
    }
  }

  /// Update user's profile picture URL in the database
  static Future<void> updateProfilePictureUrl(
      String userId, String imageUrl) async {
    try {
      await _supabase.from('users').update({
        'profile_picture_url': imageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      _logger.severe('Error updating profile picture URL: $e');
      throw Exception('Failed to update profile picture URL: $e');
    }
  }
}
