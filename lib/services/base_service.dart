import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import 'logger_service.dart';

/// BaseService provides common functionality and resources for all service classes.
/// It maintains a central instance of the Supabase client and logging mechanisms.
abstract class BaseService {
  // Get the Supabase client from the main.dart file
  final SupabaseClient supabase = Supabase.instance.client;
  final GoTrueClient auth = Supabase.instance.client.auth;

  // Helper function to check if an email follows Supabase's requirements
  bool isValidEmail(String email) {
    // Basic email validation for Supabase compatibility
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email) && email.length <= 255;
  }

  // Helper method to verify if a user with the given ID exists in the users table
  Future<bool> verifyUserExists(String userId) async {
    try {
      final response = await supabase
          .from(AppConstants.tableUsers)
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      LoggerService.error(
          runtimeType.toString(), 'Error verifying user existence: $userId', e);
      return false;
    }
  }
}
