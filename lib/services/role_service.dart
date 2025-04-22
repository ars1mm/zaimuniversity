import '../constants/app_constants.dart';
import 'base_service.dart';
import 'logger_service.dart';

/// RoleService handles role-checking operations for different user types
class RoleService extends BaseService {
  static const String _tag = 'RoleService';
  final _logger = LoggerService();

  /// Checks if the current user has admin role
  Future<bool> isAdmin() async {
    _logger.debug('Checking if current user is admin', tag: _tag);
    final user = auth.currentUser;
    if (user == null) {
      _logger.debug('No current user found during admin check', tag: _tag);
      return false;
    }

    try {
      final userData = await supabase
          .from(AppConstants.tableUsers)
          .select('role')
          .eq('id', user.id)
          .single();

      final isAdmin = userData['role'] == AppConstants.roleAdmin;
      _logger.debug('User ${user.email} admin status: $isAdmin', tag: _tag);
      return isAdmin;
    } catch (e, stackTrace) {
      _logger.error('Error checking admin status for user: ${user.email}', tag: _tag, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Checks if the current user has teacher role
  Future<bool> isTeacher() async {
    _logger.debug('Checking if current user is teacher', tag: _tag);
    final user = auth.currentUser;
    if (user == null) {
      _logger.debug('No current user found during teacher check', tag: _tag);
      return false;
    }

    try {
      final userData = await supabase
          .from(AppConstants.tableUsers)
          .select('role')
          .eq('id', user.id)
          .single();

      final isTeacher = userData['role'] == AppConstants.roleTeacher;
      _logger.debug('User ${user.email} teacher status: $isTeacher', tag: _tag);
      return isTeacher;
    } catch (e, stackTrace) {
      _logger.error('Error checking teacher status for user: ${user.email}', tag: _tag, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Checks if the current user has supervisor role
  Future<bool> isSupervisor() async {
    _logger.debug('Checking if current user is supervisor', tag: _tag);
    final user = auth.currentUser;
    if (user == null) {
      _logger.debug('No current user found during supervisor check', tag: _tag);
      return false;
    }

    try {
      final userData = await supabase
          .from(AppConstants.tableUsers)
          .select('role')
          .eq('id', user.id)
          .single();

      final isSupervisor = userData['role'] == AppConstants.roleSupervisor;
      _logger.debug('User ${user.email} supervisor status: $isSupervisor', tag: _tag);
      return isSupervisor;
    } catch (e, stackTrace) {
      _logger.error('Error checking supervisor status for user: ${user.email}', tag: _tag, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Checks if the current user has student role
  Future<bool> isStudent() async {
    _logger.debug('Checking if current user is student', tag: _tag);
    final user = auth.currentUser;
    if (user == null) {
      _logger.debug('No current user found during student check', tag: _tag);
      return false;
    }

    try {
      final userData = await supabase
          .from(AppConstants.tableUsers)
          .select('role')
          .eq('id', user.id)
          .single();

      final isStudent = userData['role'] == AppConstants.roleStudent;
      _logger.debug('User ${user.email} student status: $isStudent', tag: _tag);
      return isStudent;
    } catch (e, stackTrace) {
      _logger.error('Error checking student status for user: ${user.email}', tag: _tag, error: e, stackTrace: stackTrace);
      return false;
    }
  }
}
