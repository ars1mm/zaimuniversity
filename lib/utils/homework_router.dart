import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/homework_assignment_screen.dart';

class HomeworkRouter {
  // Navigate to the appropriate screen based on user role
  static Future<void> routeToHomeworkScreen(BuildContext context,
      {required String courseId}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }

    try {
      final userData = await Supabase.instance.client
          .from('Users')
          .select('role, id')
          .eq('id', user.id)
          .single();

      if (userData['role'] == 'teacher') {
        final bool canAccess = await HomeworkAssignmentScreen.canAccess();
        if (canAccess) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomeworkAssignmentScreen(
                courseId: courseId,
                teacherId: userData['id'],
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('You don\'t have permission to access this feature')));
        }
      } else if (userData['role'] == 'student') {
        // For students, implement a homework list view that shows all assignments for the course
        // From there, they can select one and be taken to HomeworkSubmissionScreen
        _navigateToHomeworkList(context, courseId, userData['id']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Your role does not have access to homework features')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  // Helper method to navigate to homework list for students
  static Future<void> _navigateToHomeworkList(
      BuildContext context, String courseId, String studentId) async {
    // This would typically navigate to a homework listing screen
    // For now, we'll just show a message
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Homework assignments would be listed here')));

    // Implementation would look something like this:
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => HomeworkListScreen(
    //       courseId: courseId,
    //       studentId: studentId,
    //     ),
    //   ),
    // );
  }
}
