import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class HomeworkAssignmentScreen extends StatefulWidget {
  final String courseId;
  final String teacherId;

  const HomeworkAssignmentScreen({
    super.key,
    required this.courseId,
    required this.teacherId,
  });

  // Static method to check if the current user is a teacher
  static Future<bool> canAccess() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    final userData = await Supabase.instance.client
        .from('Users')
        .select('role')
        .eq('id', user.id)
        .single();

    return userData['role'] == 'teacher';
  }

  @override
  HomeworkAssignmentScreenState createState() =>
      HomeworkAssignmentScreenState();
}

class HomeworkAssignmentScreenState extends State<HomeworkAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  final _pointsController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _createAssignment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Add the assignment to the database
      await _supabase.from('Homework_Assignments').insert({
        'id': const Uuid().v4(),
        'course_id': widget.courseId,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'due_date': _dueDate.toIso8601String(),
        'total_points': double.parse(_pointsController.text),
        'created_by': widget.teacherId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Homework assignment created successfully!')),
      );

      // Navigate back to the previous screen
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creating assignment: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate),
      );
      if (time != null) {
        setState(() {
          _dueDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Homework Assignment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Assignment Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Assignment Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Due Date'),
                subtitle: Text(
                  '${_dueDate.toLocal().toString().split(' ')[0]} at ${TimeOfDay.fromDateTime(_dueDate).format(context)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDueDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pointsController,
                decoration: const InputDecoration(
                  labelText: 'Total Points',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter total points';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _createAssignment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Create Assignment'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
