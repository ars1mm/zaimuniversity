import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_service.dart';
import 'logger_service.dart';

/// AuthServiceImpl handles all authentication related operations using Supabase.
class AuthServiceImpl extends BaseService {
  static const String _tag = 'AuthServiceImpl';
  final _logger = LoggerService();
  

  /// Signs up a new user with the given email and password
  Future<AuthResponse> signUp(
      {required String email, required String password}) async {
    _logger.info('Creating new user account for: $email', tag: _tag);
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
        _logger.warning('Using fallback email for auth: $authEmail (original: $cleanEmail)', tag: _tag);
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
        _logger.info('Successfully created auth account for: $authEmail', tag: _tag);
      } else {
        _logger.warning('Auth account creation returned null user for: $authEmail', tag: _tag);
      }
      return result;
    } catch (e, stackTrace) {
      if (e is AuthException) {
        _logger.error('Auth error creating account for: $email - ${e.message}', tag: _tag, error: e, stackTrace: stackTrace);

        // Special handling for common email issues
        if (e.message == 'email_address_invalid') {
          _logger.warning('Email address rejected by Supabase: $email', tag: _tag);
          // Rethrow to let the calling code handle it appropriately
        } else if (e.message == 'user_already_exists') {
          _logger.warning('User already exists with email: $email', tag: _tag);
        }
      } else {
        _logger.error('Failed to create auth account for: $email', tag: _tag, error: e, stackTrace: stackTrace);
      }
      rethrow; // Let the calling code handle the error
    }
  }

  /// Signs in a user with email and password
  Future<AuthResponse> signIn(
      {required String email, required String password}) async {
    _logger.info('Attempting to sign in user: $email', tag: _tag);
    try {
      final result =
          await auth.signInWithPassword(email: email, password: password);
      if (result.user != null) {
        _logger.info('Successfully signed in user: $email', tag: _tag);
      } else {
        _logger.warning('Sign in returned null user for: $email', tag: _tag);
      }
      return result;
    } catch (e, stackTrace) {
      _logger.error('Failed to sign in user: $email', tag: _tag, error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Signs out the current user
  Future<void> signOut() async {
    _logger.info('Signing out current user', tag: _tag);
    try {
      await auth.signOut();
      _logger.info('User signed out successfully', tag: _tag);
    } catch (e, stackTrace) {
      _logger.error('Error signing out user', tag: _tag, error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Gets the currently authenticated user
  Future<User?> getCurrentUser() async {
    try {
      final user = auth.currentUser;
      if (user != null) {
        _logger.debug('Current user retrieved: ${user.email}', tag: _tag);
      } else {
        _logger.debug('No current user found', tag: _tag);
      }
      return user;
    } catch (e, stackTrace) {
      _logger.error('Error getting current user', tag: _tag, error: e, stackTrace: stackTrace);
      return null;
    }
  }
}
