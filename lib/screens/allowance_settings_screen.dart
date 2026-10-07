import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class AllowanceSettingsScreen extends StatefulWidget {
  const AllowanceSettingsScreen({super.key});

  @override
  State<AllowanceSettingsScreen> createState() => _AllowanceSettingsScreenState();
}

class _AllowanceSettingsScreenState extends State<AllowanceSettingsScreen> {
  String _selectedChild = 'Rima';
  String _frequency = 'Weekly';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Allowance Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Set Default Allowance', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Configure base pay and bonus structures',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            Text('Select Child', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
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
                  return Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text(
                    'No children linked to your account.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  );
                }

                var children = snapshot.data!.docs.toList();
                children.removeWhere((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['deletionApproved'] == true;
                });
                children.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['createdAt'] as Timestamp?;
                  final bTime = bData['createdAt'] as Timestamp?;
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return -1;
                  if (bTime == null) return 1;
                  return aTime.compareTo(bTime);
                });
                
                // If the selected child is not in the list (e.g. initial load), select the first one
                if (_selectedChild == 'Rima' || _selectedChild == 'Siam' || !children.any((doc) => doc.id == _selectedChild)) {
                  // We delay this to avoid setState during build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _selectedChild = children.first.id);
                  });
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: children.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      String name = data['fullName'] ?? 'Child';
                      bool isSelected = _selectedChild == doc.id;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _selectedChild = doc.id);
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isSelected 
                                ? theme.colorScheme.primary.withValues(alpha: 0.1) 
                                : Colors.transparent,
                            side: BorderSide(
                              color: isSelected 
                                  ? theme.colorScheme.primary 
                                  : theme.dividerColor,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            name,
                            style: TextStyle(
                              color: isSelected 
                                  ? theme.colorScheme.primary 
                                  : theme.textTheme.bodyMedium?.color,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            Text('Amount (৳)', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g., 100',
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
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _frequency,
                  items: const [
                    DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                    DropdownMenuItem(
                      value: 'Bi-Weekly',
                      child: Text('Bi-Weekly'),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _frequency = newValue);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {},
              child: const Text('Save Allowance Rule'),
            ),
          ],
        ),
      ),
    );
  }
}
