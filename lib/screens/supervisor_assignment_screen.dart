import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import 'package:logger/logger.dart';

class SupervisorAssignmentScreen extends StatefulWidget {
  static const routeName = '/assign_supervisor';

  const SupervisorAssignmentScreen({super.key});

  @override
  State<SupervisorAssignmentScreen> createState() =>
      _SupervisorAssignmentScreenState();
}

class _SupervisorAssignmentScreenState
    extends State<SupervisorAssignmentScreen> {
  final _supabase = Supabase.instance.client;
  final _authService = AuthService();
  final _logger = Logger();

  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _supervisors = [];
  String? _selectedDepartment;
  String? _selectedSupervisor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Check if user is admin
      final isAdmin = await _authService.isAdmin();
      if (!isAdmin) {
        throw Exception('Only administrators can assign supervisors');
      }

      await Future.wait([
        _loadDepartments(),
        _loadSupervisors(),
      ]);
    } catch (e) {
      _logger.e('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadDepartments() async {
    try {
      final response =
          await _supabase.from('departments').select('id, name').order('name');

      if (!mounted) return;

      setState(() {
        _departments = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _logger.e('Error loading departments: $e');
      rethrow;
    }
  }

  Future<void> _loadSupervisors() async {
    try {
      // First verify the user has admin role
      final isAdmin = await _authService.isAdmin();
      if (!isAdmin) {
        throw Exception('Only administrators can view and assign supervisors');
      }

      // Query users table directly with role filter
      final response = await _supabase
          .from('users')
          .select('id, full_name, role')
          .eq('role', AppConstants.roleSupervisor)
          .not('full_name', 'is', null) // Ensure full_name is not null
          .order('full_name');

      if (!mounted) return;

      setState(() {
        _supervisors = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _logger.e('Error loading supervisors: $e');
      if (e.toString().contains('does not exist')) {
        // Handle the specific column not found error
        _logger.e(
            'Database schema error: Check if users table has full_name column');
      }
      rethrow;
    }
  }

  Future<void> _assignSupervisor() async {
    if (_selectedDepartment == null || _selectedSupervisor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select both department and supervisor')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update the department with the new supervisor
      await _supabase
          .from('departments')
          .update({'supervisor_id': _selectedSupervisor!}).eq(
              'id', _selectedDepartment!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Supervisor assigned successfully')),
        );
      }
    } catch (e) {
      _logger.e('Error assigning supervisor: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error assigning supervisor: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Supervisor'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedDepartment,
                    items: _departments.map((department) {
                      return DropdownMenuItem(
                        value: department['id'].toString(),
                        child: Text(department['name'].toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDepartment = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Supervisor',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedSupervisor,
                    items: _supervisors.map((supervisor) {
                      return DropdownMenuItem(
                        value: supervisor['id'].toString(),
                        child: Text(supervisor['full_name'].toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSupervisor = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _assignSupervisor,
                    child: const Text('Assign Supervisor'),
                  ),
                ],
              ),
            ),
    );
  }
}
