import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:math';

import 'parent_main_screen.dart';
import 'child_main_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;
  final TextEditingController _inviteCodeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _completeOnboarding() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role to continue.')),
      );
      return;
    }

    if (_selectedRole == 'Child' && _inviteCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Family Invite Code.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No authenticated user found.");

      String familyId = '';
      String? parentId;

      if (_selectedRole == 'Parent') {
        const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        final rnd = Random();
        familyId = String.fromCharCodes(Iterable.generate(
            6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
      } else {
        // Child flow: Verify the invite code
        final code = _inviteCodeController.text.trim().toUpperCase();
        
        final parentCheck = await FirebaseFirestore.instance
            .collection('users')
            .where('familyId', isEqualTo: code)
            .limit(1)
            .get();

        if (parentCheck.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid Family Invite Code.')),
          );
          setState(() => _isLoading = false);
          return;
        }

        parentId = parentCheck.docs.first.id;
        familyId = code;
      }

      // Save user to Firestore
      final userData = {
        'fullName': user.displayName ?? 'Google User',
        'email': user.email,
        'role': _selectedRole,
        'familyId': familyId,
        'balance': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_selectedRole == 'Child') {
        userData['parentId'] = parentId;
        userData['level'] = 1;
        userData['points'] = 0;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(userData);

      if (!mounted) return;
      
      if (_selectedRole == 'Parent') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome! Your Family Invite Code is $familyId')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ParentMainScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChildMainScreen()),
        );
      }

    } catch (e) {
      debugPrint('Firestore Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing setup: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildRoleCard(String role, IconData icon, String description) {
    final theme = Theme.of(context);
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary.withValues(alpha: 0.1) 
              : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon, 
              size: 48, 
              color: isSelected ? theme.colorScheme.primary : Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              role,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? theme.colorScheme.primary : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Setup'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Are you a Parent or a Child?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _buildRoleCard(
                      'Parent',
                      Icons.admin_panel_settings,
                      'Manage tasks and approve allowances',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildRoleCard(
                      'Child',
                      Icons.face,
                      'Complete tasks and earn rewards',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_selectedRole == 'Child') ...[
                const Text(
                  'Family Invite Code',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _inviteCodeController,
                  decoration: const InputDecoration(
                    hintText: 'Ask your parent for the code',
                    prefixIcon: Icon(Icons.vpn_key),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 48),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _completeOnboarding,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Continue', style: TextStyle(fontSize: 16)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
