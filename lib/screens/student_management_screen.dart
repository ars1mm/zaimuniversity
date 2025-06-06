import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../main.dart';
import 'package:logging/logging.dart';

class StudentManagementScreen extends StatefulWidget {
  static const String routeName = '/manage_students';

  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final Logger _logger = Logger('StudentManagementScreen');
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  String _searchQuery = '';
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
  DateTime _selectedEnrollmentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _logger.info('Initializing StudentManagementScreen');
    _loadStudents();
    _loadDepartments();
  }

  @override
  void dispose() {
    _logger.info('Disposing StudentManagementScreen');
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    _logger.info('Loading students from database');
    setState(() {
      _isLoading = true;
    });

    try {
      _logger.fine('Executing Supabase query for students');
      final response = await supabase
          .from(AppConstants.tableUsers)
          .select('''
            id,
            email,
            full_name,
            role,
            status,
            created_at,
            updated_at,
            students!inner (
              student_id,
              department_id,
              address,
              contact_info,
              enrollment_date,
              academic_standing,
              preferences,
              departments!inner (
                id,
                name,
                description
              )
            )
          ''')
          .eq('role', AppConstants.roleStudent)
          .order('full_name');

      _logger.fine('Received response from Supabase: ${response.toString()}');

      _logger.fine('Processing student data');
      final List<dynamic> students = response as List<dynamic>;
      final List<Map<String, dynamic>> studentMaps = students.cast<Map<String, dynamic>>();
      
      if (mounted) {
        setState(() {
          _students = studentMaps.map((student) {
            _logger.finer('Processing student: ${student['full_name']}');
            final studentData = student['students'] as Map<String, dynamic>?;
            _logger.finer('Student data: ${studentData?.toString()}');
            
            return {
              'id': student['id'],
              'email': student['email'],
              'full_name': student['full_name'],
              'role': student['role'],
              'status': student['status'],
              'created_at': student['created_at'],
              'updated_at': student['updated_at'],
              'students': {
                'student_id': studentData?['student_id'],
                'department_id': studentData?['department_id'],
                'address': studentData?['address'],
                'contact_info': studentData?['contact_info'] ?? {},
                'enrollment_date': studentData?['enrollment_date'],
                'academic_standing': studentData?['academic_standing'],
                'preferences': studentData?['preferences'] ?? {},
                'departments': studentData?['departments'],
              },
            };
          }).toList();
          _logger.info('Successfully loaded ${_students.length} students');
        });
      }
    } catch (e, stackTrace) {
      _logger.severe('Error loading students', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading students: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDepartments() async {
    _logger.info('Loading departments from database');
    try {
      _logger.fine('Executing Supabase query for departments');
      final response = await supabase
          .from(AppConstants.tableDepartments)
          .select()
          .order('name');

      _logger.fine('Received response from Supabase: ${response.toString()}');

      _logger.fine('Processing department data');
      final List<dynamic> departments = response as List<dynamic>;
      setState(() {
        _departments = departments.map((dept) {
          _logger.finer('Processing department: ${dept['name']}');
          return {
            'id': dept['id'].toString(),
            'name': dept['name']?.toString() ?? 'Unknown Department'
          };
        }).toList();
        _logger.info('Successfully loaded ${_departments.length} departments');
      });
    } catch (e, stackTrace) {
      _logger.severe('Error loading departments', e, stackTrace);
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

  List<Map<String, dynamic>> get _filteredStudents {
    _logger.fine('Filtering students with query: $_searchQuery');
    if (_searchQuery.isEmpty) {
      _logger.fine('No search query, returning all students');
      return _students;
    }

    final query = _searchQuery.toLowerCase();
    final filtered = _students.where((student) {
      final studentData = student['students'] as Map<String, dynamic>?;
      final matches = student['full_name'].toString().toLowerCase().contains(query) ||
          student['email'].toString().toLowerCase().contains(query) ||
          (studentData?['student_id']?.toString().toLowerCase().contains(query) ?? false);
      _logger.finer('Student ${student['full_name']} matches query: $matches');
      return matches;
    }).toList();
    
    _logger.fine('Found ${filtered.length} matching students');
    return filtered;
  }

  Future<void> _showAddStudentDialog() async {
    _logger.info('Showing add student dialog');
    _nameController.clear();
    _emailController.clear();
    _studentIdController.clear();
    _addressController.clear();
    _phoneController.clear();
    _departmentController.clear();
    _selectedStatus = 'active';
    _selectedAcademicStanding = 'good';

    final currentContext = context;
    
    await showDialog(
      context: currentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add New Student'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter student\'s full name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter student\'s email',
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: _studentIdController,
                  decoration: const InputDecoration(
                    labelText: 'Student ID',
                    hintText: 'Enter student ID',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a student ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    hintText: 'Enter student\'s address',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter student\'s phone number',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Department',
                  ),
                  items: _departments.map((department) {
                    return DropdownMenuItem<String>(
                      value: department['id'].toString(),
                      child: Text(department['name']?.toString() ?? 'Unknown Department'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    _logger.fine('Selected department: $value');
                    _departmentController.text = value ?? '';
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a department';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Status',
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
                    _logger.fine('Selected status: $value');
                    if (value != null) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Academic Standing',
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
                    _logger.fine('Selected academic standing: $value');
                    if (value != null) {
                      setState(() {
                        _selectedAcademicStanding = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _logger.info('Cancelled adding student');
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _logger.info('Form validated, proceeding with student creation');
                Navigator.of(dialogContext).pop();
                setState(() => _isLoading = true);

                try {
                  _logger.fine('Creating user record');
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

                  _logger.fine('User record created: ${userResponse.toString()}');

                  _logger.fine('Creating student record');
                  await supabase
                      .from(AppConstants.tableStudents)
                      .insert({
                        'id': userResponse['id'],
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

                  _logger.info('Student created successfully');
                  _loadStudents();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Student added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e, stackTrace) {
                  _logger.severe('Error adding student', e, stackTrace);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add student: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }

                if (mounted) {
                  setState(() => _isLoading = false);
                }
              } else {
                _logger.warning('Form validation failed');
              }
            },
            child: const Text('Add Student'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditStudentDialog(int index) async {
    _logger.info('Showing edit dialog for student at index $index');
    final student = _filteredStudents[index];
    final studentData = student['students'] as Map<String, dynamic>?;
    final contactInfo = studentData?['contact_info'] as Map<String, dynamic>?;
    final departmentData = studentData?['departments'] as Map<String, dynamic>?;
    
    _logger.fine('Student data for editing: ${student.toString()}');
    
    _nameController.text = student['full_name'] ?? '';
    _emailController.text = student['email'] ?? '';
    _studentIdController.text = studentData?['student_id'] ?? '';
    _addressController.text = studentData?['address'] ?? '';
    _phoneController.text = contactInfo?['phone'] ?? '';
    _departmentController.text = departmentData?['id']?.toString() ?? '';
    _selectedStatus = student['status'] ?? 'active';
    _selectedAcademicStanding = studentData?['academic_standing'] ?? 'good';
    _selectedEnrollmentDate = studentData?['enrollment_date'] != null 
        ? DateTime.parse(studentData!['enrollment_date']).toLocal()
        : DateTime.now();

    if (!mounted) return;
    
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Edit Student'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      hintText: 'Enter student\'s full name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      hintText: 'Enter student\'s email',
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _studentIdController,
                    decoration: const InputDecoration(
                      labelText: 'Student ID *',
                      hintText: 'Enter unique student ID',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a student ID';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Department *',
                    ),
                    value: _departmentController.text.isNotEmpty ? _departmentController.text : null,
                    items: _departments.map((department) {
                      return DropdownMenuItem<String>(
                        value: department['id'].toString(),
                        child: Text(department['name']?.toString() ?? 'Unknown Department'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      _logger.fine('Selected department: $value');
                      _departmentController.text = value ?? '';
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a department';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      hintText: 'Enter student\'s address',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter student\'s phone number',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Status *',
                    ),
                    value: _selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                      DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => _selectedStatus = value);
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a status';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Academic Standing *',
                    ),
                    value: _selectedAcademicStanding,
                    items: const [
                      DropdownMenuItem(value: 'good', child: Text('Good')),
                      DropdownMenuItem(value: 'warning', child: Text('Warning')),
                      DropdownMenuItem(value: 'probation', child: Text('Probation')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => _selectedAcademicStanding = value);
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select academic standing';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Enrollment Date'),
                    subtitle: Text(_formatDate(_selectedEnrollmentDate.toIso8601String())),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: _selectedEnrollmentDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null && picked != _selectedEnrollmentDate) {
                        setDialogState(() {
                          _selectedEnrollmentDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _logger.info('Form validated, proceeding with student update');
                  Navigator.of(dialogContext).pop();
                  if (!mounted) return;
                  setState(() => _isLoading = true);

                  try {
                    _logger.fine('Starting database update transaction');
                    
                    // Update user data first
                    _logger.fine('Updating user data');
                    final userUpdateResponse = await supabase
                        .from(AppConstants.tableUsers)
                        .update({
                          'email': _emailController.text.trim(),
                          'full_name': _nameController.text.trim(),
                          'status': _selectedStatus,
                          'updated_at': DateTime.now().toIso8601String(),
                        })
                        .eq('id', student['id'])
                        .select()
                        .single();
                    
                    _logger.fine('User update response: $userUpdateResponse');

                    // Update student data
                    _logger.fine('Updating student data');
                    final studentUpdateResponse = await supabase
                        .from(AppConstants.tableStudents)
                        .update({
                          'student_id': _studentIdController.text.trim(),
                          'department_id': _departmentController.text.trim(),
                          'address': _addressController.text.trim(),
                          'contact_info': {
                            'phone': _phoneController.text.trim(),
                          },
                          'enrollment_date': _selectedEnrollmentDate.toIso8601String(),
                          'academic_standing': _selectedAcademicStanding,
                        })
                        .eq('id', student['id'])
                        .select()
                        .single();
                    
                    _logger.fine('Student update response: $studentUpdateResponse');

                    _logger.info('Student updated successfully in database');
                    await _loadStudents();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Student updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                                    } catch (e, stackTrace) {
                    _logger.severe('Error updating student', e, stackTrace);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating student: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                } else {
                  _logger.warning('Form validation failed');
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteStudent(int index) async {
    _logger.info('Showing delete confirmation for student at index $index');
    final student = _filteredStudents[index];
    final studentData = student['students'] as Map<String, dynamic>?;
    final currentContext = context;

    final bool? confirm = await showDialog<bool>(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text(
          'Are you sure you want to delete "${student['full_name']}" (${studentData?['student_id']})?\n\n'
          'This will permanently delete all student data and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isLoading = true);
      try {
        // Delete student record first (due to foreign key constraint)
        await supabase
            .from(AppConstants.tableStudents)
            .delete()
            .eq('id', student['id']);

        // Then delete user record
        await supabase
            .from(AppConstants.tableUsers)
            .delete()
            .eq('id', student['id']);

        _logger.info('Student deleted successfully from database');
        await _loadStudents();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e, stackTrace) {
        _logger.severe('Error deleting student', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting student: ${e.toString()}'),
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
  }

  @override
  Widget build(BuildContext context) {
    _logger.fine('Building StudentManagementScreen');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _logger.info('Manual refresh triggered');
              _loadStudents();
            },
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
                      hintText: 'Search students...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _logger.fine('Search query changed: $value');
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () {
                    _logger.info('Add student button pressed');
                    _showAddStudentDialog();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Student'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredStudents.isEmpty
                      ? const Center(
                          child: Text(
                            'No students found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            final studentData = student['students'] as Map<String, dynamic>?;
                            final contactInfo = studentData?['contact_info'] as Map<String, dynamic>?;
                            final departmentData = studentData?['departments'] as Map<String, dynamic>?;
                            
                            _logger.finer('Building student card for: ${student['full_name']}');
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      student['full_name'] ?? 'Unknown Student',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                  ),
                                                  _buildStatusChip(student['status']?.toString() ?? 'Unknown'),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                student['email'] ?? '',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              onPressed: () {
                                                _logger.info('Edit button pressed for student: ${student['full_name']}');
                                                _showEditStudentDialog(index);
                                              },
                                              color: Colors.blue,
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () {
                                                _logger.info('Delete button pressed for student: ${student['full_name']}');
                                                _confirmDeleteStudent(index);
                                              },
                                              color: Colors.red,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    if (studentData != null) ...[
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _buildInfoRow(
                                                  'Student ID',
                                                  studentData['student_id']?.toString() ?? 'Not assigned',
                                                  Icons.badge,
                                                ),
                                                const SizedBox(height: 8),
                                                _buildInfoRow(
                                                  'Department',
                                                  departmentData?['name']?.toString() ?? 'Not assigned',
                                                  Icons.business,
                                                ),
                                                const SizedBox(height: 8),
                                                _buildInfoRow(
                                                  'Address',
                                                  studentData['address']?.toString() ?? 'Not provided',
                                                  Icons.location_on,
                                                ),
                                                if (contactInfo != null) ...[
                                                  const SizedBox(height: 8),
                                                  _buildInfoRow(
                                                    'Phone',
                                                    contactInfo['phone']?.toString() ?? 'Not provided',
                                                    Icons.phone,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _buildInfoRow(
                                                  'Academic Standing',
                                                  studentData['academic_standing']?.toString() ?? 'Unknown',
                                                  Icons.school,
                                                  color: _getAcademicStandingColor(studentData['academic_standing']?.toString() ?? 'Unknown'),
                                                ),
                                                const SizedBox(height: 8),
                                                _buildInfoRow(
                                                  'Enrollment Date',
                                                  _formatDate(studentData['enrollment_date']?.toString()),
                                                  Icons.calendar_today,
                                                ),
                                                if (studentData['preferences'] != null) ...[
                                                  const SizedBox(height: 8),
                                                  _buildInfoRow(
                                                    'Preferences',
                                                    _formatPreferences(studentData['preferences'] as Map<String, dynamic>),
                                                    Icons.settings,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
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
        onPressed: () {
          _logger.info('Floating action button pressed');
          _showAddStudentDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor(status)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'suspended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getAcademicStandingColor(String standing) {
    switch (standing.toLowerCase()) {
      case 'good':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'probation':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Not available';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      _logger.warning('Error formatting date: $dateString', e);
      return 'Invalid date';
    }
  }

  String _formatPreferences(Map<String, dynamic>? preferences) {
    if (preferences == null || preferences.isEmpty) return 'No preferences set';
    return preferences.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
  }
}
