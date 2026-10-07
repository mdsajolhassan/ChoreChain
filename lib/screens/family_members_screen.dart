import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'add_child_screen.dart';
import '../core/app_translations.dart';
import 'package:flutter/services.dart';

class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  final AuthService _authService = AuthService();
  String _parentName = 'Parent';
  bool _isLoading = true;
  String _familyCode = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userData = await _authService.getCurrentUserData();
    if (userData != null) {
      _familyCode = userData['familyId'] ?? '';
      _parentName = userData['fullName'] ?? 'Parent';
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Family Members')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Family Members')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_familyCode.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Family Code', style: theme.textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text(
                          _familyCode,
                          style: theme.textTheme.titleMedium?.copyWith(
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _familyCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Family code copied to clipboard!'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseAuth.instance.currentUser?.uid == null 
                  ? const Stream<QuerySnapshot>.empty() 
                  : FirebaseFirestore.instance
                      .collection('users')
                      .where('parentId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final children = snapshot.data?.docs
                    .map((doc) => {'id': doc.id, ...(doc.data() as Map<String, dynamic>)})
                    .where((child) => child['deletionApproved'] != true)
                    .toList() ?? [];
                
                children.sort((a, b) {
                  final aTime = a['createdAt'] as Timestamp?;
                  final bTime = b['createdAt'] as Timestamp?;
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return -1;
                  if (bTime == null) return 1;
                  return aTime.compareTo(bTime);
                });
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Parents', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildMemberCard(
                        _parentName,
                        theme.colorScheme.primary,
                        theme,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Children', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (children.isEmpty)
                      Text(
                        'No children in this family yet.',
                        style: theme.textTheme.bodyMedium,
                      )
                    else
                      ...children.map(
                        (c) {
                          bool wantsDeletion = c['deletionRequested'] == true;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildMemberCard(
                              c['fullName'] ?? 'Child',
                              theme.colorScheme.secondary,
                              theme,
                              wantsDeletion 
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () async {
                                          try {
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(c['id'])
                                                .update({'deletionRequested': false});
                                            if (!context.mounted) return;
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error: $e')),
                                            );
                                          }
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.grey[700],
                                          side: BorderSide(color: Colors.grey[400]!),
                                        ),
                                        child: Text('Reject Deletion'.tr),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () async {
                                          try {
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(c['id'])
                                                .update({'deletionApproved': true});
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Deletion Approved'.tr)),
                                            );
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error: $e')),
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                        ),
                                        child: Text('Approve Deletion'.tr),
                                      ),
                                    ],
                                  )
                                : null,
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddChildScreen(familyId: _familyCode),
                  ),
                ).then((_) => _loadData()); // Refresh list when returning
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add Child'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                foregroundColor: theme.colorScheme.primary,
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(String name, Color accent, ThemeData theme, [Widget? trailing]) {
    String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: accent.withValues(alpha: 0.1),
          child: Text(
            initial,
            style: TextStyle(color: accent, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name, style: theme.textTheme.titleMedium),
        trailing: trailing,
      ),
    );
  }
}
