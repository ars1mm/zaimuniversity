import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../main.dart';
import 'package:logging/logging.dart';

class AddStudentScreen extends StatefulWidget {
  static const String routeName = '/add_student';

  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final Logger _logger = Logger('AddStudentScreen');
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  List<Map<String, dynamic>> _departments = [];
  String _selectedStatus = 'active';
  String _selectedAcademicStanding = 'good';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    try {
      final response = await supabase
          .from(AppConstants.tableDepartments)
          .select()
          .order('name');

      final List<dynamic> departments = response as List<dynamic>;
      if (mounted) {
        setState(() {
          _departments = departments.map((dept) => {
            'id': dept['id'].toString(),
            'name': dept['name']?.toString() ?? 'Unknown Department'
          }).toList();
        });
      }
    } catch (e) {
      _logger.severe('Error loading departments', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading departments: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // First create the user record
      final userResponse = await supabase
          .from(AppConstants.tableUsers)
          .insert({
            'email': _emailController.text,
            'full_name': _nameController.text,
            'role': AppConstants.roleStudent,
            'status': _selectedStatus,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      if (!mounted) return;

      // Then create the student record with the user's ID
      await supabase
          .from(AppConstants.tableStudents)
          .insert({
            'id': userResponse['id'], // This is the foreign key to users table
            'student_id': _studentIdController.text,
            'department_id': _departmentController.text,
            'address': _addressController.text,
            'contact_info': {
              'phone': _phoneController.text,
            },
            'enrollment_date': DateTime.now().toIso8601String(),
            'academic_standing': _selectedAcademicStanding,
            'preferences': {},
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student added successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear the form
      _formKey.currentState!.reset();
      _nameController.clear();
      _emailController.clear();
      _studentIdController.clear();
      _addressController.clear();
      _phoneController.clear();
      _departmentController.clear();
      _selectedStatus = 'active';
      _selectedAcademicStanding = 'good';
    } catch (e) {
      _logger.severe('Error adding student', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add student: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Student'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter student\'s full name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter student\'s email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  labelText: 'Student ID',
                  hintText: 'Enter student ID',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a student ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter student\'s address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter student\'s phone number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
                items: _departments.map((department) {
                  return DropdownMenuItem<String>(
                    value: department['id'],
                    child: Text(department['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _departmentController.text = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a department';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                value: _selectedStatus,
                items: const [
                  DropdownMenuItem(
                    value: 'active',
                    child: Text('Active'),
                  ),
                  DropdownMenuItem(
                    value: 'inactive',
                    child: Text('Inactive'),
                  ),
                  DropdownMenuItem(
                    value: 'suspended',
                    child: Text('Suspended'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Academic Standing',
                  border: OutlineInputBorder(),
                ),
                value: _selectedAcademicStanding,
                items: const [
                  DropdownMenuItem(
                    value: 'good',
                    child: Text('Good'),
                  ),
                  DropdownMenuItem(
                    value: 'warning',
                    child: Text('Warning'),
                  ),
                  DropdownMenuItem(
                    value: 'probation',
                    child: Text('Probation'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedAcademicStanding = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _addStudent,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Add Student'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
