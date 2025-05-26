import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import 'package:logger/logger.dart';

class CreateSupervisorScreen extends StatefulWidget {
  static const routeName = '/create_supervisor';

  const CreateSupervisorScreen({super.key});

  @override
  State<CreateSupervisorScreen> createState() => _CreateSupervisorScreenState();
}

class _CreateSupervisorScreenState extends State<CreateSupervisorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _departmentController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specializationController = TextEditingController();
  final _bioController = TextEditingController();

  final _supabase = Supabase.instance.client;
  final _authService = AuthService();
  final _logger = Logger();

  List<Map<String, dynamic>> _departments = [];
  String? _selectedDepartmentId;
  String _selectedStatus = 'active';

  bool _isLoading = false;
  bool _isFetchingDepartments = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    setState(() => _isFetchingDepartments = true);

    try {
      // Get all departments
      final response =
          await _supabase.from('departments').select('id, name').order('name');

      setState(() {
        _departments = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _logger.e('Error loading departments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load departments: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingDepartments = false);
      }
    }
  }

  Future<void> _createSupervisor() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    // Save current admin data before proceeding
    final adminEmail = _supabase.auth.currentUser?.email;
    //final adminId = _supabase.auth.currentUser?.id;
    String? adminRefreshToken;

    if (_supabase.auth.currentSession != null) {
      adminRefreshToken = _supabase.auth.currentSession!.refreshToken;
      _logger.d('Stored admin credentials for later restoration');
    }

    try {
      // First check if the user is an admin
      final isAdmin = await _authService.isAdmin();
      if (!isAdmin) {
        throw Exception('Only administrators can create supervisor accounts');
      }

      // Create auth user account with auto confirmation
      final AuthResponse authResponse = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'full_name': _fullNameController.text.trim(),
          'role': AppConstants.roleSupervisor
        },
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create supervisor account');
      }
      final userId = authResponse.user!.id;

      // Create user record with supervisor role
      await _supabase.from(AppConstants.tableUsers).insert({
        'id': userId,
        'email': _emailController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'role': AppConstants.roleSupervisor, // Set role to supervisor
        'status': _selectedStatus,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Create supervisor record with additional details
      await _supabase.from('supervisors').insert({
        'id': userId,
        'department_id': _selectedDepartmentId,
        'specialization': _specializationController.text.trim(),
        'bio': _bioController.text.trim(),
        'contact_info': {
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
        },
        'created_at': DateTime.now().toIso8601String(),
      });
      // Sign out to prevent being logged in as the newly created supervisor
      await _supabase.auth
          .signOut(); // Manually restore the admin session if we had a refresh token
      if (adminRefreshToken != null) {
        try {
          // Attempt to set the session with the stored refresh token
          await _supabase.auth.setSession(adminRefreshToken);
          _logger.d('Admin session restored successfully');

          // Verify if we're logged in as admin again
          final currentUser = _supabase.auth.currentUser;
          if (currentUser?.email == adminEmail) {
            _logger.d('Admin session verified successfully');
          }
        } catch (e) {
          _logger.e('Failed to restore admin session: $e');
          if (adminEmail != null) {
            _logger
                .d('Admin session restore failed, will need to log in again');
            // Show a message that the admin needs to log in again
            if (mounted) {
              // Show login message after a short delay so it doesn't overlap with success message
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Session changed. Please log in again as admin to continue.'),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 8),
                      action: SnackBarAction(
                        label: 'Login',
                        onPressed: () {
                          // Navigate to login screen
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                      ),
                    ),
                  );
                }
              });
            }
          }
        }
      }

      // Always show the success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supervisor account created successfully'),
            backgroundColor: Colors.green,
          ),
        ); // Clear the form
        _formKey.currentState?.reset();
        _fullNameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _phoneController.clear();
        _specializationController.clear();
        _bioController.clear();
        setState(() {
          _selectedDepartmentId = null;
          _selectedStatus = 'active';
        });
      }
    } catch (e) {
      _logger.e('Error creating supervisor: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create supervisor: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Supervisor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create New Supervisor Account',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fill in the details to create a new supervisor in the system. Supervisors have department-level oversight and can manage teachers and courses.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter supervisor\'s full name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter supervisor\'s full name';
                  }
                  if (value.trim().length < 3) {
                    return 'Name must be at least 3 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter supervisor\'s email address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an email address';
                  }
                  // Basic email validation
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Please enter a valid email address';
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
                  prefixIcon: const Icon(Icons.lock),
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
                  prefixIcon: const Icon(Icons.lock_outline),
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
                    return 'Please confirm your password';
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
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter supervisor\'s phone number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _specializationController,
                decoration: const InputDecoration(
                  labelText: 'Specialization',
                  hintText: 'Enter supervisor\'s specialization',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Enter supervisor\'s bio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                value: _selectedDepartmentId,
                items: _isFetchingDepartments
                    ? [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Loading departments...'),
                        )
                      ]
                    : _departments
                        .map((department) => DropdownMenuItem(
                              value: department['id'].toString(),
                              child: Text(department['name']),
                            ))
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDepartmentId = value;
                  });
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
                  prefixIcon: Icon(Icons.toggle_on),
                ),
                value: _selectedStatus,
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _createSupervisor,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Supervisor Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
