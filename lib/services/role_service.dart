import '../constants/app_constants.dart';
import 'base_service.dart';
import 'logger_service.dart';

/// RoleService handles role-checking operations for different user types
class RoleService extends BaseService {
  static const String _tag = 'RoleService';

  /// Checks if the current user has admin role
  Future<bool> isAdmin() async {
    LoggerService.debug(_tag, 'Checking if current user is admin');
    final user = auth.currentUser;
    if (user == null) {
      LoggerService.debug(_tag, 'No current user found during admin check');
      return false;
    }

    try {
      final userData = await supabase
          .from(AppConstants.tableUsers)
          .select('role')
          .eq('id', user.id)
          .single();

      final isAdmin = userData['role'] == AppConstants.roleAdmin;
      LoggerService.debug(_tag, 'User ${user.email} admin status: $isAdmin');
      return isAdmin;
    } catch (e) {
      LoggerService.error(
          _tag, 'Error checking admin status for user: ${user.email}', e);
      return false;
    }
  }

  /// Checks if the current user has teacher role
  Future<bool> isTeacher() async {
    LoggerService.debug(_tag, 'Checking if current user is teacher');
    final user = auth.currentUser;
    if (user == null) {
      LoggerService.debug(_tag, 'No current user found during teacher check');
      return false;
    }

    try {
      final userData = await supabase
          .from(AppConstants.tableUsers)
          .select('role')
          .eq('id', user.id)
          .single();

      final isTeacher = userData['role'] == AppConstants.roleTeacher;
      LoggerService.debug(
          _tag, 'User ${user.email} teacher status: $isTeacher');
      return isTeacher;
    } catch (e) {
      LoggerService.error(
          _tag, 'Error checking teacher status for user: ${user.email}', e);
      return false;
    }
  }

  /// Checks if the current user has supervisor role
  Future<bool> isSupervisor() async {
    LoggerService.debug(_tag, 'Checking if current user is supervisor');
    final user = auth.currentUser;
    if (user == null) {
      LoggerService.debug(
          _tag, 'No current user found during supervisor check');
      return false;
    }

    try {
      final userData = await supabase
          .from(AppConstants.tableUsers)
          .select('role')
          .eq('id', user.id)
          .single();

      final isSupervisor = userData['role'] == AppConstants.roleSupervisor;
      LoggerService.debug(
          _tag, 'User ${user.email} supervisor status: $isSupervisor');
      return isSupervisor;
    } catch (e) {
      LoggerService.error(
          _tag, 'Error checking supervisor status for user: ${user.email}', e);
      return false;
    }
  }

  /// Checks if the current user has student role
  Future<bool> isStudent() async {
    LoggerService.debug(_tag, 'Checking if current user is student');
    final user = auth.currentUser;
    if (user == null) {
      LoggerService.debug(_tag, 'No current user found during student check');
      return false;
    }

    try {
      final userData = await supabase
          .from(AppConstants.tableUsers)
          .select('role')
          .eq('id', user.id)
          .single();

      final isStudent = userData['role'] == AppConstants.roleStudent;
      LoggerService.debug(
          _tag, 'User ${user.email} student status: $isStudent');
      return isStudent;
    } catch (e) {
      LoggerService.error(
          _tag, 'Error checking student status for user: ${user.email}', e);
      return false;
    }
  }
}
