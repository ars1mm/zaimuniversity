import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import 'package:logger/logger.dart';

class AnnouncementService {
  final _supabase = Supabase.instance.client;
  final _logger = Logger();

  // Get announcements for the current user
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    try {
      final response = await _supabase.from('announcements').select('''
            id,
            title,
            content,
            importance,
            created_at,
            valid_until,
            department:department_id (
              id,
              name
            ),
            creator:created_by (
              full_name,
              role
            )
          ''').eq('status', 'active').order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.e('Error fetching announcements: $e');
      rethrow;
    }
  }

  // Create a new announcement (admin/supervisor only)
  Future<String> createAnnouncement({
    required String title,
    required String content,
    String? departmentId,
    required List<String> targetRoles,
    String importance = 'medium',
    DateTime? validUntil,
  }) async {
    try {
      final response = await _supabase.rpc(
        'create_announcement',
        params: {
          'p_title': title,
          'p_content': content,
          'p_department_id': departmentId,
          'p_target_roles': targetRoles,
          'p_importance': importance,
          'p_valid_until': validUntil?.toIso8601String(),
        },
      );

      return response as String;
    } catch (e) {
      _logger.e('Error creating announcement: $e');
      rethrow;
    }
  }

  // Update an existing announcement
  Future<void> updateAnnouncement({
    required String id,
    required String title,
    required String content,
    required List<String> targetRoles,
    required String importance,
    DateTime? validUntil,
  }) async {
    try {
      await _supabase.rpc(
        'update_announcement',
        params: {
          'p_announcement_id': id,
          'p_title': title,
          'p_content': content,
          'p_target_roles': targetRoles,
          'p_importance': importance,
          'p_valid_until': validUntil?.toIso8601String(),
        },
      );
    } catch (e) {
      _logger.e('Error updating announcement: $e');
      rethrow;
    }
  }

  // Archive an announcement (soft delete)
  Future<void> archiveAnnouncement(String id) async {
    try {
      await _supabase
          .from('announcements')
          .update({'status': 'archived'}).eq('id', id);
    } catch (e) {
      _logger.e('Error archiving announcement: $e');
      rethrow;
    }
  }
}
