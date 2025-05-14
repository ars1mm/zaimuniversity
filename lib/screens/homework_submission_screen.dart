import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class HomeworkSubmissionScreen extends StatefulWidget {
  final String homeworkId;
  final String studentId;

  const HomeworkSubmissionScreen({
    Key? key,
    required this.homeworkId,
    required this.studentId,
  }) : super(key: key);

  // Static method to check if the current user is a student
  static Future<bool> canAccess() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    final userData = await Supabase.instance.client
        .from('Users')
        .select('role')
        .eq('id', user.id)
        .single();

    return userData['role'] == 'student';
  }

  @override
  _HomeworkSubmissionScreenState createState() =>
      _HomeworkSubmissionScreenState();
}

class _HomeworkSubmissionScreenState extends State<HomeworkSubmissionScreen> {
  String? _selectedFilePath;
  String? _selectedFileName;
  bool _isUploading = false;
  String? _errorMessage;
  final SupabaseClient _supabase = Supabase.instance.client;

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _selectedFileName = result.files.single.name;
        _errorMessage = null;
      });
    } else {
      // User canceled the picker
    }
  }

  Future<void> _submitHomework() async {
    if (_selectedFilePath == null) {
      setState(() {
        _errorMessage = 'Please select a file first';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // Generate a unique filename to avoid conflicts
      final String fileExtension = path.extension(_selectedFileName!);
      final String uniqueFileName =
          '${widget.homeworkId}_${widget.studentId}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';

      // Upload file to Supabase Storage
      final File file = File(_selectedFilePath!);
      final response = await _supabase.storage
          .from('homework_submissions')
          .upload(uniqueFileName, file);

      // Get the public URL of the uploaded file
      final String fileUrl = _supabase.storage
          .from('homework_submissions')
          .getPublicUrl(uniqueFileName);

      // Create a record in the Homework_Submissions table
      await _supabase.from('Homework_Submissions').insert({
        'id': const Uuid().v4(),
        'homework_id': widget.homeworkId,
        'student_id': widget.studentId,
        'submission_url': fileUrl,
        'submitted_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Homework submitted successfully!')),
      );

      // Navigate back
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error submitting homework: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Helper methods for file display
  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'PDF Document';
      case 'doc':
        return 'Word Document';
      case 'docx':
        return 'Word Document (DOCX)';
      default:
        return 'Unknown File Type';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Submit Homework'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Upload your homework (PDF or Word files only):',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickFile,
              icon: Icon(Icons.upload_file),
              label: Text('Choose File'),
            ),
            if (_selectedFileName != null) ...[
              SizedBox(height: 20),
              Card(
                child: ListTile(
                  leading: Icon(_getFileIcon(_selectedFileName!)),
                  title: Text(_selectedFileName!),
                  subtitle: Text(_getFileType(_selectedFileName!)),
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              SizedBox(height: 20),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            ],
            Spacer(),
            _isUploading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed:
                        _selectedFilePath != null ? _submitHomework : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Submit Homework'),
                  ),
          ],
        ),
      ),
    );
  }
}
