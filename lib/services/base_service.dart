import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';

/// BaseService provides common functionality and resources for all service classes.
/// It maintains a central instance of the Supabase client and logging mechanisms.
abstract class BaseService {
  final Logger _logger = Logger('BaseService');
  static const String _tag = 'BaseService';
  final SupabaseClient supabase = Supabase.instance.client;
  final GoTrueClient auth = Supabase.instance.client.auth;

  // Helper function to check if an email follows Supabase's requirements
  bool isValidEmail(String email) {
    return email.isNotEmpty && email.contains('@');
  }

  // Helper function to verify if a user exists
  Future<bool> verifyUserExists(String userId) async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return response != null;
    } catch (e, stackTrace) {
      _logger.severe('[$_tag] Error verifying user existence: $userId', e, stackTrace);
      return false;
    }
  }
}
