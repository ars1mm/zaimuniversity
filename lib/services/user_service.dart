import '../constants/app_constants.dart';
import 'base_service.dart';
import 'logger_service.dart';

/// UserService handles all user-related database operations
class UserService extends BaseService {
  static const String _tag = 'UserService';
  final _logger = LoggerService();

  /// Creates a new user record in the database
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String fullName,
    required String role,
    required String userId,
    String status = 'active',
  }) async {
    _logger.info('Creating user record for: $email with role: $role',
        tag: _tag);
    try {
      final Map<String, dynamic> userData = {
        'id': userId, // Explicitly set the ID to match the auth user ID
        'email': email,
        'full_name': fullName,
        'role': role,
        'status': status,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await supabase
          .from(AppConstants.tableUsers)
          .insert(userData)
          .select('id')
          .single();

      _logger.info('Created user record with ID: ${response['id']}', tag: _tag);
      return {
        'success': true,
        'message': 'User created successfully',
        'data': response
      };
    } catch (e, stackTrace) {
      _logger.error('Failed to create user record for: $email',
          tag: _tag, error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Failed to create user: ${e.toString()}',
      };
    }
  }

  /// Updates an existing user record
  Future<Map<String, dynamic>> updateUser({
    required String userId,
    String? email,
    String? fullName,
    String? role,
    String? status,
  }) async {
    _logger.info('Updating user record for ID: $userId', tag: _tag);
    try {
      final Map<String, dynamic> userData = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (email != null) userData['email'] = email;
      if (fullName != null) userData['full_name'] = fullName;
      if (role != null) userData['role'] = role;
      if (status != null) userData['status'] = status;

      await supabase
          .from(AppConstants.tableUsers)
          .update(userData)
          .eq('id', userId.toString());

      _logger.info('Updated user record with ID: $userId', tag: _tag);
      return {
        'success': true,
        'message': 'User updated successfully',
      };
    } catch (e, stackTrace) {
      _logger.error('Failed to update user record for ID: $userId',
          tag: _tag, error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Failed to update user: ${e.toString()}',
      };
    }
  }

  /// Retrieves a user by their ID
  Future<Map<String, dynamic>> getUserById(String userId) async {
    _logger.info('Retrieving user with ID: $userId', tag: _tag);
    try {
      final response = await supabase
          .from(AppConstants.tableUsers)
          .select()
          .eq('id', userId.toString())
          .single();

      return {
        'success': true,
        'message': 'User retrieved successfully',
        'data': response,
      };
    } catch (e, stackTrace) {
      _logger.error('Failed to retrieve user with ID: $userId',
          tag: _tag, error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Failed to retrieve user: ${e.toString()}',
      };
    }
  }

  /// Deletes a user by their ID
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    _logger.info('Deleting user with ID: $userId', tag: _tag);
    try {
      await supabase
          .from(AppConstants.tableUsers)
          .delete()
          .eq('id', userId.toString());

      return {
        'success': true,
        'message': 'User deleted successfully',
      };
    } catch (e, stackTrace) {
      _logger.error('Failed to delete user with ID: $userId',
          tag: _tag, error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Failed to delete user: ${e.toString()}',
      };
    }
  }
}
