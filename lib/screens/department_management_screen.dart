import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../main.dart';
import 'package:logging/logging.dart';

class DepartmentManagementScreen extends StatefulWidget {
  static const String routeName = '/manage_departments';

  const DepartmentManagementScreen({super.key});

  @override
  State<DepartmentManagementScreen> createState() =>
      _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState
    extends State<DepartmentManagementScreen> {
  final Logger _logger = Logger('DepartmentManagementScreen');
  List<Map<String, dynamic>> _departments = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  Future<void> _loadDepartments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await supabase
          .from(AppConstants.tableDepartments)
          .select()
          .order('name');

      if (!mounted) return;

      setState(() {
        _departments = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      _logger.severe('Error loading departments', e);
      if (!mounted) return;

      // Use local variable to avoid BuildContext across async gap
      final errorMessage = 'Error loading departments: ${e.toString()}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredDepartments {
    if (_searchQuery.isEmpty) {
      return _departments;
    }

    final query = _searchQuery.toLowerCase();
    return _departments.where((dept) {
      return dept['name'].toString().toLowerCase().contains(query) ||
          dept['description'].toString().toLowerCase().contains(query);
    }).toList();
  }
  Future<void> _showAddDepartmentDialog() async {
    _nameController.clear();
    _descriptionController.clear();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Department'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Department Name',
                    hintText: 'e.g. Computer Science',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a department name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter department description',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                // Store form values in local variables
                final deptName = _nameController.text;
                final deptDescription = _descriptionController.text;
                
                Navigator.of(context).pop();
                
                setState(() => _isLoading = true);

                try {
                  await supabase.from(AppConstants.tableDepartments).insert({
                    'name': deptName,
                    'description': deptDescription,
                    'created_at': DateTime.now().toIso8601String(),
                    'updated_at': DateTime.now().toIso8601String(),
                  });

                  if (!mounted) return;

                  _loadDepartments();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Department added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  
                  final errorMessage = 'Failed to add department: ${e.toString()}';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: Colors.red,
                    ),
                  );
                }

                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Add Department'),
          ),
        ],
      ),
    );
  }
  void _showEditDepartmentDialog(int index) {
    final department = _filteredDepartments[index];
    _nameController.text = department['name'];
    _descriptionController.text = department['description'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Department'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Department Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a department name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                // Store form values in local variables
                final deptName = _nameController.text;
                final deptDescription = _descriptionController.text;
                final deptId = department['id'].toString();

                Navigator.of(context).pop();
                setState(() => _isLoading = true);

                try {
                  await supabase.from(AppConstants.tableDepartments).update({
                    'name': deptName,
                    'description': deptDescription,
                    'updated_at': DateTime.now().toIso8601String(),
                  }).eq('id', deptId);

                  if (!mounted) return;

                  _loadDepartments();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Department updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  final errorMessage = 'Failed to update department: ${e.toString()}';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: Colors.red,
                    ),
                  );
                }

                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
  void _confirmDeleteDepartment(int index) {
    final department = _filteredDepartments[index];
    final departmentId = department['id'];
    final departmentName = department['name'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Department'),
        content: Text(
          'Are you sure you want to delete "$departmentName"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red),
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() => _isLoading = true);              try {                await supabase
                    .from(AppConstants.tableDepartments)
                    .delete()
                    .eq('id', departmentId.toString());

                if (!mounted) return;

                setState(() {
                  _departments.removeWhere((d) => d['id'] == departmentId);
                  _isLoading = false;
                });

                // Use ScaffoldMessenger safely after checking mounted
                if (mounted) {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Department deleted successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;

                final errorMessage = 'Failed to delete department: ${e.toString()}';
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.red,
                  ),
                );
                
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Department Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDepartments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search departments...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _showAddDepartmentDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Department'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredDepartments.isEmpty
                      ? const Center(
                          child: Text(
                            'No departments found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredDepartments.length,
                          itemBuilder: (context, index) {
                            final department = _filteredDepartments[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text(
                                  department['name'] ?? 'Unknown Department',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: department['description'] != null &&
                                        department['description'].isNotEmpty
                                    ? Text(
                                        department['description'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () =>
                                          _showEditDepartmentDialog(index),
                                      color: Colors.blue,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () =>
                                          _confirmDeleteDepartment(index),
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDepartmentDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
