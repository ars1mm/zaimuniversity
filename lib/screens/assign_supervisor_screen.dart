import 'package:flutter/material.dart';

class AssignSupervisorScreen extends StatefulWidget {
  static const routeName = '/assign_supervisor';

  const AssignSupervisorScreen({super.key});

  @override
  State<AssignSupervisorScreen> createState() => _AssignSupervisorScreenState();
}

class _AssignSupervisorScreenState extends State<AssignSupervisorScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Supervisor'),
      ),
      body: const Center(
        child: Text('Supervisor creation form will be implemented here'),
      ),
    );
  }
} 