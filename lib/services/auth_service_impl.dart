import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_service.dart';
import 'logger_service.dart';

/// AuthServiceImpl handles all authentication related operations using Supabase.
class AuthServiceImpl extends BaseService {
  static const String _tag = 'AuthServiceImpl';

  /// Signs up a new user with the given email and password
  Future<AuthResponse> signUp(
      {required String email, required String password}) async {
    LoggerService.info(_tag, 'Creating new user account for: $email');
    try {
      // Clean email and ensure it's in proper format
      final cleanEmail = email.trim().toLowerCase();

      // Force email to be valid for Supabase by ensuring it has proper format
      // We'll use the original email in the users table, but a valid one for auth
      String authEmail;
      if (!isValidEmail(cleanEmail)) {
        // Create a valid email for auth purposes while preserving the original in metadata
        // This approach allows storing the user's intended email while satisfying Supabase
        String sanitizedPart =
            cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
        if (sanitizedPart.isEmpty) sanitizedPart = 'user';
        authEmail = '$sanitizedPart@zaim.edu.tr';
        LoggerService.warning(_tag,
            'Using fallback email for auth: $authEmail (original: $cleanEmail)');
      } else {
        authEmail = cleanEmail;
      }

      // Proceed with sign up using potentially modified email
      final result = await auth.signUp(
        email: authEmail,
        password: password,
        data: {
          'original_email': cleanEmail
        }, // Store original email in metadata
      );

      if (result.user != null) {
        LoggerService.info(
            _tag, 'Successfully created auth account for: $authEmail');
      } else {
        LoggerService.warning(
            _tag, 'Auth account creation returned null user for: $authEmail');
      }
      return result;
    } catch (e) {
      if (e is AuthException) {
        LoggerService.error(
            _tag, 'Auth error creating account for: $email - ${e.message}', e);

        // Special handling for common email issues
        if (e.message == 'email_address_invalid') {
          LoggerService.warning(
              _tag, 'Email address rejected by Supabase: $email');
          // Rethrow to let the calling code handle it appropriately
        } else if (e.message == 'user_already_exists') {
          LoggerService.warning(_tag, 'User already exists with email: $email');
        }
      } else {
        LoggerService.error(
            _tag, 'Failed to create auth account for: $email', e);
      }
      rethrow; // Let the calling code handle the error
    }
  }

  /// Signs in a user with email and password
  Future<AuthResponse> signIn(
      {required String email, required String password}) async {
    LoggerService.info(_tag, 'Attempting to sign in user: $email');
    try {
      final result =
          await auth.signInWithPassword(email: email, password: password);
      if (result.user != null) {
        LoggerService.info(_tag, 'Successfully signed in user: $email');
      } else {
        LoggerService.warning(_tag, 'Sign in returned null user for: $email');
      }
      return result;
    } catch (e) {
      LoggerService.error(_tag, 'Failed to sign in user: $email', e);
      rethrow;
    }
  }

  /// Signs out the current user
  Future<void> signOut() async {
    LoggerService.info(_tag, 'Signing out current user');
    try {
      await auth.signOut();
      LoggerService.info(_tag, 'User signed out successfully');
    } catch (e) {
      LoggerService.error(_tag, 'Error signing out user', e);
      rethrow;
    }
  }

  /// Gets the currently authenticated user
  Future<User?> getCurrentUser() async {
    try {
      final user = auth.currentUser;
      if (user != null) {
        LoggerService.debug(_tag, 'Current user retrieved: ${user.email}');
      } else {
        LoggerService.debug(_tag, 'No current user found');
      }
      return user;
    } catch (e) {
      LoggerService.error(_tag, 'Error getting current user', e);
      return null;
    }
  }
}
