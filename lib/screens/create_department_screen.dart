import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import 'package:logger/logger.dart';

class CreateDepartmentScreen extends StatefulWidget {
  static const routeName = '/create_department';

  const CreateDepartmentScreen({super.key});

  @override
  State<CreateDepartmentScreen> createState() => _CreateDepartmentScreenState();
}

class _CreateDepartmentScreenState extends State<CreateDepartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedSupervisorId;

  final _supabase = Supabase.instance.client;
  final _authService = AuthService();
  final _logger = Logger();

  List<Map<String, dynamic>> _supervisors = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSupervisors();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSupervisors() async {
    setState(() => _isLoading = true);

    try {
      // Get only users with supervisor role
      final response = await _supabase
          .from('users')
          .select('id, full_name')
          .eq('role', 'supervisor')
          .order('full_name');

      setState(() {
        _supervisors = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _logger.e('Error loading supervisors: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load supervisors: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveDepartment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // First check if the user is an admin
      final isAdmin = await _authService.isAdmin();
      if (!isAdmin) {
        throw Exception('Only administrators can create departments');
      }

      // Create the department
      final departmentData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'supervisor_id': _selectedSupervisorId,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('departments').insert(departmentData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Department created successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear the form or navigate back
        Navigator.pop(context);
      }
    } catch (e) {
      _logger.e('Error creating department: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create department: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Department'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Department Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Department Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a department name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a department description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Department Supervisor',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      hint: const Text('Select a supervisor'),
                      value: _selectedSupervisorId,
                      items: _supervisors.map((supervisor) {
                        return DropdownMenuItem<String>(
                          value: supervisor['id'],
                          child: Text(
                              supervisor['full_name'] ?? 'Unknown Supervisor'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSupervisorId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a supervisor';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _saveDepartment,
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Create Department'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
