import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../main.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  List<Map<String, dynamic>> _departments = [];
  String _selectedStatus = 'active';
  String _selectedAcademicStanding = 'good';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
          _departments = departments
              .map((dept) => {
                    'id': dept['id'].toString(),
                    'name': dept['name']?.toString() ?? 'Unknown Department'
                  })
              .toList();
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
      // Variable to store the user ID (needs to be late to handle initialization in catch blocks)
      late String userId;
      bool isNewUser = true;

      try {
        // First attempt to sign up the user
        final AuthResponse authResponse = await supabase.auth.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          data: {
            'full_name': _nameController.text,
            'role': AppConstants.roleStudent,
            'autoconfirm': true,
          },
          emailRedirectTo: null, // Skip email confirmation
        );

        // Check if the signup was successful
        if (authResponse.user == null) {
          throw Exception('Failed to create student account');
        }

        userId = authResponse.user!.id;
      } catch (e) {
        // If we get "user already exists" error, try to get the user ID
        if (e.toString().contains('user_already_exists')) {
          _logger.info('User already exists, checking for existing record');
          isNewUser = false;

          // Find the user by email to get their ID from our users table
          final List<dynamic> existingUsers = await supabase
              .from('users')
              .select('id')
              .eq('email', _emailController.text)
              .limit(1);

          if (existingUsers.isNotEmpty) {
            userId = existingUsers[0]['id'];
            _logger.info('Found existing user with ID: $userId');

            // Check if this user already has a student record
            final List<dynamic> existingStudent = await supabase
                .from(AppConstants.tableStudents)
                .select('id')
                .eq('id', userId)
                .limit(1);

            if (existingStudent.isNotEmpty) {
              throw Exception('A student with this email already exists');
            }
          } else {
            // Try to sign in with the credentials to get the user ID
            try {
              final AuthResponse signInResponse =
                  await supabase.auth.signInWithPassword(
                email: _emailController.text,
                password: _passwordController.text,
              );

              if (signInResponse.user != null) {
                userId = signInResponse.user!.id;
                _logger.info('Retrieved user ID through sign in: $userId');

                // Sign out since we're just using this to get the ID
                await supabase.auth.signOut();
              } else {
                throw Exception('Could not retrieve user ID');
              }
            } catch (signInError) {
              throw Exception(
                  'User exists but credentials don\'t match. Please try a different email or contact admin.');
            }
          }
        } else {
          // If it's not a user already exists error, rethrow
          rethrow;
        }
      }      // Get the password hash from the auth.users table
      final authUserResponse =
          await supabase.rpc('get_auth_user_hash', params: {'user_id': userId});

      // Check if we got the hash
      String? passwordHash;
      if (authUserResponse != null && authUserResponse.isNotEmpty) {
        passwordHash = authUserResponse[0]['encrypted_password'];
      }

      // Check if we need to add or update the user record
      if (isNewUser) {
        // Create new user record in the users table with the password hash
        await supabase.from(AppConstants.tableUsers).insert({
          'id': userId, // Use the ID from the auth user
          'email': _emailController.text,
          'full_name': _nameController.text,
          'role': AppConstants.roleStudent,
          'status': _selectedStatus,
          'password_hash': passwordHash, // Include the password hash
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        // Check if user exists in the users table first
        final List<dynamic> existingUsers = await supabase
            .from(AppConstants.tableUsers)
            .select('id')
            .eq('id', userId)
            .limit(1);
            
        if (existingUsers.isEmpty) {
          // Create the missing user record
          await supabase.from(AppConstants.tableUsers).insert({
            'id': userId,
            'email': _emailController.text,
            'full_name': _nameController.text,
            'role': AppConstants.roleStudent,
            'status': _selectedStatus,
            'password_hash': passwordHash,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } else {
          // Optionally update the existing user record if needed
          await supabase.from(AppConstants.tableUsers).update({
            'full_name': _nameController.text,
            'role': AppConstants.roleStudent,
            'status': _selectedStatus,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', userId);
        }
      }

      // Now create the student record with the same userId returned by Supabase
      await supabase.from(AppConstants.tableStudents).insert({
        'id': userId, // Use the ID from the auth user
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

      if (mounted) {
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
        _passwordController.clear();
        _confirmPasswordController.clear();
        _studentIdController.clear();
        _addressController.clear();
        _phoneController.clear();
        _departmentController.clear();
        _selectedStatus = 'active';
        _selectedAcademicStanding = 'good';
      }
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
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Confirm password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm the password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
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
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
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
