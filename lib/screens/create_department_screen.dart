import 'package:flutter/material.dart';

class CreateDepartmentScreen extends StatefulWidget {
  static const routeName = '/create_department';

  const CreateDepartmentScreen({super.key});

  @override
  State<CreateDepartmentScreen> createState() => _CreateDepartmentScreenState();
}

class _CreateDepartmentScreenState extends State<CreateDepartmentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Department'),
      ),
      body: const Center(
        child: Text('Department creation form will be implemented here'),
      ),
    );
  }
} 