// ignore: unused_import
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../main.dart';
import '../models/user.dart';
import 'logger_service.dart';
import 'supabase_service.dart';

class AuthService {
  final SupabaseService _supabaseService = SupabaseService();
  static const String _tag = 'AuthService';

  Future<bool> login(String email, String password) async {
    try {
      LoggerService.info(_tag, 'Attempting login for user: $email');
      final response = await _supabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Get user's role and additional data
        final userData = await supabase
            .from(AppConstants.tableUsers)
            .select()
            .eq('email', email)
            .single();

        // Store auth data in shared preferences for easier access
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            AppConstants.tokenKey, response.session?.accessToken ?? '');
        await prefs.setString(AppConstants.userIdKey, response.user?.id ?? '');
        await prefs.setString(AppConstants.userRoleKey, userData['role']);

        LoggerService.info(_tag,
            'Login successful for user: $email with role: ${userData['role']}');
        return true;
      }
      LoggerService.warning(
          _tag, 'Login failed for user: $email - No user returned');
      return false;
    } catch (e) {
      LoggerService.error(_tag, 'Login error for user: $email', e);
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      LoggerService.info(_tag, 'Attempting to log out user');
      await _supabaseService.signOut();

      // Clear stored auth data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.userIdKey);
      await prefs.remove(AppConstants.userRoleKey);

      LoggerService.info(_tag, 'Logout successful');
      return true;
    } catch (e) {
      LoggerService.error(_tag, 'Error during logout', e);
      return false;
    }
  }

  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      if (token == null) {
        LoggerService.debug(_tag, 'No token found in preferences');
      }
      return token;
    } catch (e) {
      LoggerService.error(_tag, 'Error retrieving authentication token', e);
      return null;
    }
  }

  Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString(AppConstants.userRoleKey);
      if (role == null) {
        LoggerService.debug(_tag, 'No user role found in preferences');
      }
      return role;
    } catch (e) {
      LoggerService.error(_tag, 'Error retrieving user role', e);
      return null;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      LoggerService.debug(_tag, 'Getting current user from Supabase');
      final supabaseUser = await _supabaseService.getCurrentUser();
      if (supabaseUser == null) {
        LoggerService.debug(_tag, 'No authenticated user found');
        return null;
      }

      final userData = await supabase
          .from(AppConstants.tableUsers)
          .select()
          .eq('id', supabaseUser.id)
          .single();

      LoggerService.debug(
          _tag, 'Current user retrieved: ${userData['full_name']}');
      return User.fromJson(userData);
    } catch (e) {
      LoggerService.error(_tag, 'Error retrieving current user', e);
      return null;
    }
  }

  Future<bool> isAdmin() async {
    return await _supabaseService.isAdmin();
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
