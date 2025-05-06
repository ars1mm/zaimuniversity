// ignore: unused_import
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../main.dart';
import 'logger_service.dart';
import 'supabase_service.dart';
import 'base_service.dart';

/// AuthService handles all authentication-related operations
class AuthService extends BaseService {
  final SupabaseService _supabaseService = SupabaseService();
  final _logger = LoggerService();
  static const String _tag = 'AuthService';

  /// Gets the user's role from the database
  Future<String?> getUserRole() async {
    try {
      final user = await getCurrentUser();
      if (user == null) {
        _logger.warning('No authenticated user found', tag: _tag);
        return null;
      }
      return user['role'] as String?;
    } catch (e, stackTrace) {
      _logger.error('Error getting user role',
          tag: _tag, error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Checks if a user is currently logged in
  Future<bool> isLoggedIn() async {
    try {
      _logger.info('Checking if user is logged in', tag: _tag);
      final currentUser = await getCurrentUser();
      return currentUser != null;
    } catch (e) {
      _logger.error('Error checking login status', tag: _tag, error: e);
      return false;
    }
  }

  /// Refreshes and returns the current session (used to restore admin sessions)
  Future<bool> refreshSession() async {
    try {
      _logger.info('Refreshing user session', tag: _tag);

      // Try to restore session from local storage or server
      if (auth.currentSession == null) {
        _logger.info('No current session, login required', tag: _tag);
        return false;
      }

      // Attempt to refresh token
      await supabase.auth.refreshSession();
      return auth.currentSession != null;
    } catch (e, stackTrace) {
      _logger.error('Error refreshing session',
          tag: _tag, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Gets the current user's data
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final user = auth.currentUser;
      if (user == null) {
        _logger.warning('No user is currently logged in', tag: _tag);
        return null;
      }
      final userData = await supabase
          .from('users')
          .select()
          .eq('id', user.id.toString())
          .single();

      _logger.info('Retrieved current user data', tag: _tag);
      return userData;
    } catch (e, stackTrace) {
      _logger.error('Error getting current user',
          tag: _tag, error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Logs in a user with email and password
  Future<bool> login(String email, String password) async {
    try {
      _logger.info('Attempting login for user: $email', tag: _tag);

      final response = await auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        _logger.warning('Login failed - no user returned', tag: _tag);
        return false;
      }

      _logger.info('User logged in successfully', tag: _tag);
      return true;
    } catch (e, stackTrace) {
      _logger.error('Login error', tag: _tag, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Logs out the current user
  Future<bool> logout() async {
    try {
      _logger.debug('Attempting to log out user', tag: _tag);
      await auth.signOut();
      _logger.debug('User logged out successfully', tag: _tag);
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error during logout',
          tag: _tag, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Checks if the current user has admin role
  Future<bool> isAdmin() async {
    try {
      _logger.debug('Checking if user has admin role', tag: _tag);
      final user = await getCurrentUser();
      if (user == null) {
        _logger.debug('No user found when checking admin role', tag: _tag);
        return false;
      }

      final role = user['role'];
      _logger.debug('User role: $role', tag: _tag);
      return role == 'admin';
    } catch (e, stackTrace) {
      _logger.error('Error checking admin role',
          tag: _tag, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> isTeacher() async {
    return await _supabaseService.isTeacher();
  }

  Future<bool> isSupervisor() async {
    return await _supabaseService.isSupervisor();
  }

  Future<bool> isStudent() async {
    return await _supabaseService.isStudent();
  }
}
