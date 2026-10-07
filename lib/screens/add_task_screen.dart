import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _taskNameController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _rewardController = TextEditingController();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _children = [];
  bool _isLoadingChildren = true;
  String? _selectedChildId;

  String _frequency = 'Daily';
  bool _requirePhotoProof = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoadingChildren = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('parentId', isEqualTo: uid)
          .get();

      final children = snapshot.docs
          .map((doc) => {'id': doc.id, ...(doc.data())})
          .where((child) => child['deletionApproved'] != true)
          .toList();

      children.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return -1;
        if (bTime == null) return 1;
        return aTime.compareTo(bTime);
      });

      // Add the "Shared Family Task" option at the top
      children.insert(0, {'id': 'all', 'fullName': 'Anyone (Shared Task)'});

      if (mounted) {
        setState(() {
          _children = children;
          if (children.isNotEmpty) {
            _selectedChildId = children.first['id'];
          }
          _isLoadingChildren = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingChildren = false);
    }
  }

  Future<void> _createTask() async {
    if (_taskNameController.text.isEmpty ||
        _rewardController.text.isEmpty ||
        _selectedChildId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter task name, reward, and select a child'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Find child name for denormalization
      final child = _children.firstWhere((c) => c['id'] == _selectedChildId);
      final childName = child['fullName'] ?? 'Child';

      await FirebaseFirestore.instance.collection('tasks').add({
        'title': _taskNameController.text.trim(),
        'instructions': _instructionsController.text.trim(),
        'assignedTo': _selectedChildId,
        'assignedToName': childName,
        'parentId': FirebaseAuth.instance.currentUser?.uid,
        'reward': int.tryParse(_rewardController.text.trim()) ?? 0,
        'frequency': _frequency,
        'requirePhotoProof': _requirePhotoProof,
        'isCompleted': false,
        'status': 'Pending', // Pending, Pending Approval, Completed, Redo
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task assigned successfully!')),
      );
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Firebase Error: ${e.message}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to add task: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _instructionsController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Task')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Assign To', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              _isLoadingChildren
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor),
                        color: theme.colorScheme.surface,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedChildId,
                          hint: const Text('Select a child'),
                          items: _children.map((child) {
                            return DropdownMenuItem<String>(
                              value: child['id'],
                              child: Text(child['fullName'] ?? 'Unknown Child'),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() => _selectedChildId = newValue);
                            }
                          },
                        ),
                      ),
                    ),
              const SizedBox(height: 24),

              Text('Task Name', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _taskNameController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Clean your room',
                ),
              ),
              const SizedBox(height: 24),

              Text('Reward Amount (৳)', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _rewardController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'e.g., 50',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 24),

              Text('Frequency', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                  color: theme.colorScheme.surface,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _frequency,
                    items: const [
                      DropdownMenuItem(
                        value: 'One-time',
                        child: Text('One-time'),
                      ),
                      DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _frequency = newValue);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Instructions (Optional)',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _instructionsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add detailed instructions here...',
                ),
              ),
              const SizedBox(height: 24),

              SwitchListTile(
                title: Text(
                  'Require Photo Proof',
                  style: theme.textTheme.titleSmall,
                ),
                subtitle: Text(
                  'Child must upload a photo to complete',
                  style: theme.textTheme.bodySmall,
                ),
                value: _requirePhotoProof,
                activeThumbColor: theme.colorScheme.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (bool value) =>
                    setState(() => _requirePhotoProof = value),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _createTask,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Assign Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
