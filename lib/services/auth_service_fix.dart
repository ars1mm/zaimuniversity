import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'logger_service.dart';
import 'base_service.dart';
import '../constants/app_constants.dart';

/// Fixed AuthService that properly handles role checking
class AuthService extends BaseService {
  final _logger = LoggerService();
  static const String _tag = 'AuthService';

  /// Gets the user's role from the database
  Future<String?> getUserRole() async {
    try {
      _logger.info('Getting user role from database', tag: _tag);
      
      // First try to get the role using our custom DB function
      try {
        final roleResponse = await supabase.rpc('get_current_user_role');
        if (roleResponse != null) {
          _logger.debug('Retrieved role from get_current_user_role(): "$roleResponse"', tag: _tag);
          return roleResponse;
        }
      } catch (e) {
        _logger.warning('Error calling get_current_user_role RPC: ${e.toString()}', tag: _tag);
        // Continue to fallback methods - don't return here
      }
      
      // Fall back to getting from the users table directly
      final user = await getCurrentUser();
      if (user == null) {
        _logger.warning('No authenticated user found', tag: _tag);
        return null;
      }

      final role = user['role'] as String?;
      _logger.debug('Retrieved role from database: "$role"', tag: _tag);

      return role;
    } catch (e, stackTrace) {
      _logger.error('Error getting user role',
          tag: _tag, error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Checks if the current user has a specific role
  Future<bool> hasRole(String roleName) async {
    try {
      _logger.debug('Checking if user has role: $roleName', tag: _tag);
      
      // Try RPC method first
      try {
        final response = await supabase.rpc('user_has_role', params: {
          'role_name': roleName
        });
        _logger.debug('user_has_role($roleName) response: $response', tag: _tag);
        if (response == true) return true;
      } catch (e) {
        _logger.warning('Error calling user_has_role RPC: ${e.toString()}', tag: _tag);
        // Continue to fallback method
      }

      // Fallback: Check role directly
      final userRole = await getUserRole();
      if (userRole == null) return false;
      
      return userRole == roleName;
    } catch (e, stackTrace) {
      _logger.error('Error checking if user has role: $roleName',
          tag: _tag, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Checks if the current user has any of the specified roles
  Future<bool> hasAnyRole(List<String> roles) async {
    try {
      _logger.debug('Checking if user has any roles: $roles', tag: _tag);
      
      // Try RPC method first
      try {
        final response = await supabase.rpc('user_has_any_role', params: {
          'roles': roles
        });
        _logger.debug('user_has_any_role($roles) response: $response', tag: _tag);
        if (response == true) return true;
      } catch (e) {
        _logger.warning('Error calling user_has_any_role RPC: ${e.toString()}', tag: _tag);
        // Continue to fallback method
      }

      // Fallback: Check role directly
      final userRole = await getUserRole();
      if (userRole == null) return false;
      
      return roles.contains(userRole);
    } catch (e, stackTrace) {
      _logger.error('Error checking if user has any roles: $roles',
          tag: _tag, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Checks if a user is currently logged in
  Future<bool> isLoggedIn() async {
    try {
      _logger.info('Checking if user is logged in', tag: _tag);
      final currentUser = await getCurrentUser();
      return currentUser != null;
    } catch (e) {
      _logger.error('Error checking login status: ${e.toString()}', tag: _tag);
      return false;
    }
  }

  /// Logs in a user with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      _logger.info('Attempting login for user: $email', tag: _tag);

      // Sanitize email input
      final sanitizedEmail = email.trim().toLowerCase();
      
      final response = await auth.signInWithPassword(
        email: sanitizedEmail,
        password: password,
      );

      if (response.user == null) {
        _logger.warning('Login failed - no user returned', tag: _tag);
        return {
          'success': false,
          'message': 'Invalid credentials',
          'user': null
        };
      }

      // Attempt to refresh user session to ensure we have correct permissions
      try {
        await supabase.auth.refreshSession();
      } catch (e) {
        _logger.warning('Session refresh failed, using existing session: ${e.toString()}', tag: _tag);
      }

      final userData = await getCurrentUser();
      final role = userData?['role'] as String?;
      
      _logger.info('User logged in successfully with role: $role', tag: _tag);

      return {
        'success': true,
        'message': 'Login successful',
        'user': userData,
        'role': role
      };
    } catch (e, stackTrace) {
      _logger.error('Login error', tag: _tag, error: e, stackTrace: stackTrace);
      
      String errorMessage = 'Login failed';
      if (e is AuthException) {
        switch(e.message) {
          case 'Invalid login credentials':
            errorMessage = 'Incorrect email or password';
            break;
          case 'Email not confirmed':
            errorMessage = 'Please confirm your email first';
            break;
          default:
            errorMessage = e.message;
        }
      }
      
      return {
        'success': false,
        'message': errorMessage,
        'error': e.toString()
      };
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
      
      // Use properly parameterized query to avoid SQL injection
      try {
        final userData = await supabase
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (userData != null) {
          _logger.info('Retrieved current user data from users table', tag: _tag);
          return userData;
        }
      } catch (e) {
        _logger.warning('Error getting user from users table: ${e.toString()}', tag: _tag);
        // Continue to fallback
      }
      
      // Fallback: Return data from auth.currentUser
      _logger.warning('User not found in users table, using auth data', tag: _tag);
      return {
        'id': user.id,
        'email': user.email,
        'role': user.userMetadata?['role'] ?? 'authenticated',
        'full_name': user.userMetadata?['full_name'] ?? user.email,
      };
    } catch (e, stackTrace) {
      _logger.error('Error getting current user',
          tag: _tag, error: e, stackTrace: stackTrace);
      return null;
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

  /// Checks if the current user has admin role
  Future<bool> isAdmin() async {
    return await hasRole(AppConstants.roleAdmin);
  }

  /// Checks if the current user has teacher role  
  Future<bool> isTeacher() async {
    return await hasRole(AppConstants.roleTeacher);
  }

  /// Checks if the current user has supervisor role
  Future<bool> isSupervisor() async {
    return await hasRole(AppConstants.roleSupervisor);
  }

  /// Checks if the current user has student role
  Future<bool> isStudent() async {
    return await hasRole(AppConstants.roleStudent);
  }
} 