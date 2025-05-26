import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import 'package:logger/logger.dart';

class AssignSupervisorScreen extends StatefulWidget {
  static const routeName = '/assign_supervisor';

  const AssignSupervisorScreen({super.key});

  @override
  State<AssignSupervisorScreen> createState() => _AssignSupervisorScreenState();
}

class _AssignSupervisorScreenState extends State<AssignSupervisorScreen> {
  final _supabase = Supabase.instance.client;
  final _authService = AuthService();
  final _logger = Logger();

  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _supervisors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
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

  Future<void> _loadDepartments() async {
    try {
      final response = await _supabase
          .from(AppConstants.tableDepartments)
          .select(
              'id, name, description, supervisor_id, users!departments_supervisor_id_fkey(id, full_name, email)')
          .order('name');

      if (mounted) {
        setState(() {
          _departments = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      _logger.e('Error loading departments: $e');
      rethrow;
    }
  }

  Future<void> _loadSupervisors() async {
    try {
      final response = await _supabase
          .from(AppConstants.tableUsers)
          .select('id, full_name, email')
          .eq('role', 'supervisor')
          .order('full_name');

      if (mounted) {
        setState(() {
          _supervisors = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      _logger.e('Error loading supervisors: $e');
      rethrow;
    }
  }

  Future<void> _assignSupervisor(
      String departmentId, String? supervisorId) async {
    try {
      await _supabase.from(AppConstants.tableDepartments).update({
        'supervisor_id': supervisorId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', departmentId);

      // Reload data to reflect changes
      await _loadDepartments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(supervisorId != null
                ? 'Supervisor assigned successfully'
                : 'Supervisor removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error assigning supervisor: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAssignDialog(Map<String, dynamic> department) {
    String? selectedSupervisorId = department['supervisor_id'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Supervisor to ${department['name']}'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Department: ${department['name']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (department['description'] != null)
                  Text(
                    'Description: ${department['description']}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: selectedSupervisorId,
                  decoration: const InputDecoration(
                    labelText: 'Select Supervisor',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No Supervisor (Remove Assignment)'),
                    ),
                    ..._supervisors.map((supervisor) {
                      return DropdownMenuItem<String>(
                        value: supervisor['id'],
                        child: Text(
                            '${supervisor['full_name']} (${supervisor['email']})'),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedSupervisorId = value;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _assignSupervisor(department['id'], selectedSupervisorId);
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Supervisors'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Department Supervisor Assignments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Assign or update supervisors for university departments. Each department can have one supervisor.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Departments: ${_departments.length}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Available Supervisors: ${_supervisors.length}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _departments.isEmpty
                          ? const Center(
                              child: Text('No departments found'),
                            )
                          : ListView.builder(
                              itemCount: _departments.length,
                              itemBuilder: (context, index) {
                                final department = _departments[index];
                                final supervisor = department['users'];

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(
                                      department['name'] ??
                                          'Unknown Department',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (department['description'] != null)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child:
                                                Text(department['description']),
                                          ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              supervisor != null
                                                  ? Icons.person
                                                  : Icons.person_off,
                                              size: 16,
                                              color: supervisor != null
                                                  ? Colors.green
                                                  : Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                supervisor != null
                                                    ? '${supervisor['full_name']} (${supervisor['email']})'
                                                    : 'No supervisor assigned',
                                                style: TextStyle(
                                                  color: supervisor != null
                                                      ? Colors.green[700]
                                                      : Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () =>
                                          _showAssignDialog(department),
                                      tooltip: 'Assign/Change Supervisor',
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
