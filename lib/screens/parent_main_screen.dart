import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_screen.dart';
import '../services/auth_service.dart';
import 'add_task_screen.dart';
import 'parent_approval_screen.dart';

import 'family_members_screen.dart';
import 'allowance_settings_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import '../core/app_translations.dart';
class ParentMainScreen extends StatefulWidget {
  const ParentMainScreen({super.key});

  @override
  State<ParentMainScreen> createState() => _ParentMainScreenState();
}

class _ParentMainScreenState extends State<ParentMainScreen> {
  final AuthService _authService = AuthService();
  String userName = "Loading...";
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _checkWeeklyReset();
  }

  Future<void> _loadUserName() async {
    Map<String, dynamic>? userData = await _authService.getCurrentUserData();
    if (userData != null && mounted) {
      setState(() {
        userName = userData['fullName'] ?? "Parent";
      });
    } else {
      setState(() {
        userName = "Parent";
      });
    }
  }

  Future<void> _checkWeeklyReset() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final parentDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!parentDoc.exists) return;
      
      final data = parentDoc.data()!;
      final lastReset = data['lastResetDate'] as Timestamp?;
      final now = DateTime.now();
      
      // Calculate the most recent Saturday at 00:00:00
      // DateTime.weekday: Monday=1, ..., Friday=5, Saturday=6, Sunday=7
      int daysSinceSaturday = (now.weekday - DateTime.saturday) % 7;
      if (daysSinceSaturday < 0) daysSinceSaturday += 7;
      
      DateTime mostRecentSaturday = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: daysSinceSaturday));

      final batch = FirebaseFirestore.instance.batch();

      if (lastReset == null) {
        // Safe initialization to prevent wiping current funds
        batch.update(parentDoc.reference, {'lastResetDate': FieldValue.serverTimestamp()});
        await batch.commit();
      } else {
        final lastResetDateTime = lastReset.toDate();
        if (lastResetDateTime.isBefore(mostRecentSaturday)) {
          // Trigger the Firestore batch reset
          batch.update(parentDoc.reference, {'lastResetDate': FieldValue.serverTimestamp()});
          
          final childrenSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('parentId', isEqualTo: user.uid)
              .get();
              
          for (var childDoc in childrenSnapshot.docs) {
            batch.update(childDoc.reference, {'balance': 0});
          }

          // Reset chore progress
          final tasksSnapshot = await FirebaseFirestore.instance
              .collection('tasks')
              .where('parentId', isEqualTo: user.uid)
              .get();
              
          for (var taskDoc in tasksSnapshot.docs) {
            final data = taskDoc.data();
            if (data['status'] == 'Completed' || data['isCompleted'] == true) {
              if (data['frequency'] == 'One-time') {
                batch.delete(taskDoc.reference);
              } else {
                // Reset recurring tasks
                batch.update(taskDoc.reference, {
                  'status': 'Pending',
                  'isCompleted': false,
                });
              }
            }
          }
          
          await batch.commit();
        }
      }
    } catch (e) {
      debugPrint('Error during weekly reset: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> tabs = [
      _buildHomeTab(context, theme),
      const FamilyMembersScreen(),
      const AllowanceSettingsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: 'Home'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.family_restroom_outlined),
            activeIcon: const Icon(Icons.family_restroom),
            label: 'Family'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            activeIcon: const Icon(Icons.account_balance_wallet),
            label: 'Allowance', // Or 'Allowance'.tr if added
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: 'Settings'.tr,
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTaskScreen(),
                  ),
                );
              },
              backgroundColor: theme.colorScheme.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Task',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHomeTab(BuildContext context, ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back,', style: theme.textTheme.bodySmall),
            Text(userName, style: theme.textTheme.titleMedium),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseAuth.instance.currentUser?.uid == null
            ? const Stream<DocumentSnapshot>.empty()
            : FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots(),
        builder: (context, parentSnapshot) {
          int totalBudget = 500;
          if (parentSnapshot.hasData && parentSnapshot.data!.exists) {
            final pData = parentSnapshot.data!.data() as Map<String, dynamic>;
            totalBudget = pData['weeklyBudget'] ?? 500;
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseAuth.instance.currentUser?.uid == null
                ? const Stream<QuerySnapshot>.empty()
                : FirebaseFirestore.instance
                    .collection('users')
                    .where('parentId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
            builder: (context, childrenSnapshot) {
              int sumEarnings = 0;
              List<Widget> childrenCards = [];

              if (childrenSnapshot.hasData) {
                var childrenDocs = childrenSnapshot.data!.docs.toList();
                childrenDocs.removeWhere((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['deletionApproved'] == true;
                });
                childrenDocs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['createdAt'] as Timestamp?;
                  final bTime = bData['createdAt'] as Timestamp?;
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return -1;
                  if (bTime == null) return 1;
                  return aTime.compareTo(bTime);
                });

                for (var i = 0; i < childrenDocs.length; i++) {
                  var doc = childrenDocs[i];
                  var child = doc.data() as Map<String, dynamic>;
                  String childId = doc.id;
                  String name = child['fullName'] ?? 'Child';
                  String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                  int earned = child['balance'] ?? 0;
                  
                  sumEarnings += earned;

                  Color accentColor = i % 2 == 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.secondary;

                  childrenCards.add(
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildChildProgressCard(
                        childId,
                        name,
                        initial,
                        earned,
                        theme,
                        accentColor,
                      ),
                    ),
                  );
                }
              }

              int remaining = totalBudget - sumEarnings;
              if (remaining < 0) remaining = 0;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Total Family Allowance Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Remaining Weekly Allowance'.tr,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '৳$remaining',
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Out of ৳$totalBudget budget',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('tasks')
                          .where('status', isEqualTo: 'Pending Approval')
                          .snapshots(),
                      builder: (context, snapshot) {
                        int pendingCount = 0;
                        if (snapshot.hasData) {
                          pendingCount = snapshot.data!.docs.length;
                        }

                        if (pendingCount == 0) return const SizedBox.shrink();

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ParentApprovalScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.secondary.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: theme.colorScheme.secondary,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Approvals Pending',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          color: theme.colorScheme.secondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$pendingCount tasks waiting for your approval',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: theme.colorScheme.secondary,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    Text('Your Children'.tr, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),

                    if (childrenSnapshot.connectionState == ConnectionState.waiting)
                      const Center(child: CircularProgressIndicator())
                    else if (childrenSnapshot.hasError)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Error: ${childrenSnapshot.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else if (childrenCards.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'No children linked yet.\nAdd a child from the Family tab.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      Column(children: childrenCards),

                    const SizedBox(height: 80),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChildProgressCard(
    String childId,
    String name,
    String initial,
    int earned,
    ThemeData theme,
    Color accentColor,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', isEqualTo: childId)
          .snapshots(),
      builder: (context, snapshot) {
        int completed = 0;
        int total = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          total = docs.length;
          completed = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'Completed' || data['isCompleted'] == true;
          }).length;
        }

        double progress = total == 0 ? 0 : completed / total;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: accentColor.withValues(alpha: 0.1),
                          child: Text(
                            initial,
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(name, style: theme.textTheme.titleMedium),
                      ],
                    ),
                    Text(
                      '৳$earned earned',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: theme.dividerColor,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$completed/$total chores done',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
