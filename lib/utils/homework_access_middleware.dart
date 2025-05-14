import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zaimuniversity/screens/homework_assignment_screen.dart';
import 'package:zaimuniversity/screens/homework_submission_screen.dart';

class HomeworkAccessMiddleware {
  // Check if user can access the homework submission screen
  static Future<bool> canAccessSubmissionScreen(BuildContext context) async {
    bool canAccess = await HomeworkSubmissionScreen.canAccess();

    if (!canAccess) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only students can submit homework!')));

      // Navigate back
      Navigator.of(context).pop();
    }

    return canAccess;
  }

  // Check if user can access the homework assignment screen
  static Future<bool> canAccessAssignmentScreen(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    final userData = await Supabase.instance.client
        .from('Users')
        .select('role')
        .eq('id', user.id)
        .single();

    bool isTeacher = userData['role'] == 'teacher';

    if (!isTeacher) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Only teachers can create homework assignments!')));

      // Navigate back
      Navigator.of(context).pop();
    }

    return isTeacher;
  }

  // Navigate to the appropriate homework screen based on user role
  static Future<void> navigateToHomeworkScreen(BuildContext context,
      {required String courseId}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final userData = await Supabase.instance.client
        .from('Users')
        .select('role, id')
        .eq('id', user.id)
        .single();

    if (userData['role'] == 'teacher') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomeworkAssignmentScreen(
            courseId: courseId,
            teacherId: userData['id'],
          ),
        ),
      );
    } else if (userData['role'] == 'student') {
      // Show available homework assignments for this course
      _showHomeworkAssignments(context, courseId, userData['id']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('You don\'t have permission to access homework features!')));
    }
  }

  // Helper method to show homework assignments for students
  static Future<void> _showHomeworkAssignments(
      BuildContext context, String courseId, String studentId) async {
    // Navigate to a homework listing screen or show dialog with available assignments
    // For now, we'll just show a message
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Showing available homework assignments...')));

    // Implementation for showing assignments would go here
    // This would typically navigate to a homework listing screen filtered by courseId
  }
}
