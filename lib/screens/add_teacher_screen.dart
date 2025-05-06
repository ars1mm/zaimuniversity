// filepath: c:\Users\Windows 10 PRO\Desktop\Fakulltet\Instanbul\Mobile Applications\project\zaimuniversity\lib\screens\add_teacher_screen.dart
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../main.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddTeacherScreen extends StatefulWidget {
  static const String routeName = '/add_teacher';

  const AddTeacherScreen({super.key});

  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final Logger _logger = Logger('AddTeacherScreen');
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _specializationController = TextEditingController();
  final _bioController = TextEditingController();
  final _departmentController = TextEditingController();
  final _phoneController = TextEditingController();
  List<Map<String, dynamic>> _departments = [];
  String _selectedStatus = 'active';
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _specializationController.dispose();
    _bioController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
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

  Future<void> _addTeacher() async {
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
            'role': AppConstants.roleTeacher,
            'autoconfirm': true,
          },
          emailRedirectTo: null, // Skip email confirmation
        );

        // Check if the signup was successful
        if (authResponse.user == null) {
          throw Exception('Failed to create teacher account');
        }

        userId = authResponse.user!.id;
      } catch (e) {
        // If we get "user already exists" error, try to get the user ID
        if (e.toString().contains('user_already_exists')) {
          _logger.info('User already exists, checking for existing record');
          isNewUser = false;

          // Find the user by email to get their ID from our users table
          final List<dynamic> existingUsers = await supabase
              .from(AppConstants.tableUsers)
              .select('id')
              .eq('email', _emailController.text)
              .limit(1);

          if (existingUsers.isNotEmpty) {
            userId = existingUsers[0]['id'];
            _logger.info('Found existing user with ID: $userId');

            // Check if this user already has a teacher record            final List<dynamic> existingTeacher = await supabase
                .from(AppConstants.tableTeachers)
                .select('id')
                .eq('id', userId.toString())
                .limit(1);

            if (existingTeacher.isNotEmpty) {
              throw Exception('A teacher with this email already exists');
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
      }

      // Get the password hash from the auth.users table
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
          'role': AppConstants.roleTeacher,
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
            'role': AppConstants.roleTeacher,
            'status': _selectedStatus,
            'password_hash': passwordHash,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } else {
          // Optionally update the existing user record if needed
          await supabase.from(AppConstants.tableUsers).update({
            'full_name': _nameController.text,
            'role': AppConstants.roleTeacher,
            'status': _selectedStatus,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', userId);
        }
      }      // Now create the teacher record with the same userId
      await supabase.from(AppConstants.tableTeachers).insert({
        'id': userId, // Use the ID from the auth user
        'department_id': _departmentController.text,
        'specialization': _specializationController.text,
        'bio': _bioController.text,
        'status': _selectedStatus,
        'contact_info': {
          'email': _emailController.text,
          'phone': _phoneController.text,
        },
      });
      
      // Bypass RLS by using an RPC function for storage operations      try {
        // This function should be created in Supabase to enable admin operations
        // that bypass RLS policies for storage
        await supabase.rpc('admin_ensure_bucket_exists', params: {
          'bucket_name': 'profile-images'
        });
        
        _logger.info('Successfully ensured profile pictures bucket exists');
      } catch (rpcError) {
        // Log the error but continue - the bucket may already exist
        _logger.warning('Error ensuring bucket exists: $rpcError');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teacher added successfully with login credentials'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear the form
        _formKey.currentState!.reset();
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _specializationController.clear();
        _bioController.clear();
        _departmentController.clear();
        _phoneController.clear();
        _selectedStatus = 'active';

        // Navigate back to teacher management screen with success result
        Navigator.of(context).pop(true); // true indicates a teacher was added
      }
    } catch (e) {
      _logger.severe('Error adding teacher', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add teacher: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Teacher'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Enter teacher\'s full name',
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
                          hintText: 'Enter teacher\'s email',
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
                          hintText: 'Enter password for login',
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
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
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
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Enter teacher\'s phone number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Academic Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                      TextFormField(
                        controller: _specializationController,
                        decoration: const InputDecoration(
                          labelText: 'Specialization',
                          hintText: 'Enter teacher\'s specialization',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a specialization';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bioController,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                          hintText: 'Enter teacher\'s bio',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
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
                            value: 'on_leave',
                            child: Text('On Leave'),
                          ),
                          DropdownMenuItem(
                            value: 'retired',
                            child: Text('Retired'),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _addTeacher,
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
                      : const Text('Add Teacher'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
