import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_screen.dart';
import '../services/auth_service.dart';
import 'wallet_screen.dart';
import 'child_rewards_screen.dart';
import 'profile_settings_screen.dart';
import 'notifications_screen.dart';
import 'task_detail_screen.dart';
import '../core/app_translations.dart';
class ChildMainScreen extends StatefulWidget {
  const ChildMainScreen({super.key});

  @override
  State<ChildMainScreen> createState() => _ChildMainScreenState();
}

class _ChildMainScreenState extends State<ChildMainScreen> {
  final AuthService _authService = AuthService();
  String childName = "Loading...";
  int _currentIndex = 0;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  @override
  void initState() {
    super.initState();
    _loadChildName();
    _listenForDeletion();
  }

  void _listenForDeletion() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) async {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data() as Map<String, dynamic>;
          if (data['deletionApproved'] == true) {
            _userSubscription?.cancel();
            try {
              await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
              await user.delete();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            } catch (e) {
              // Sign out as fallback if delete fails
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadChildName() async {
    Map<String, dynamic>? userData = await _authService.getCurrentUserData();
    if (userData != null && mounted) {
      setState(() {
        childName = userData['fullName'] ?? "Kid";
      });
    } else {
      setState(() {
        childName = "Kid";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> tabs = [
      _buildHomeTab(context, theme),
      const WalletScreen(),
      const ChildRewardsScreen(),
      const ProfileSettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: 'Home'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            activeIcon: const Icon(Icons.account_balance_wallet),
            label: 'Wallet'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.emoji_events_outlined),
            activeIcon: const Icon(Icons.emoji_events),
            label: 'Rewards'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: 'Profile'.tr,
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context, ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back!', style: theme.textTheme.bodySmall),
            Text('Hi, $childName!', style: theme.textTheme.titleMedium),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseAuth.instance.currentUser?.uid == null 
                  ? const Stream<QuerySnapshot>.empty()
                  : FirebaseFirestore.instance
                      .collection('tasks')
                      .where('assignedTo', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                int completedCount = 0;
                if (snapshot.hasData) {
                  completedCount = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['status'] == 'Completed' || data['isCompleted'] == true;
                  }).length;
                }
                
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$completedCount ${'Tasks completed'.tr}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      Text('Keep it up!'.tr, style: theme.textTheme.bodySmall),
                    ],
                  ),
                );
              }
            ),
            const SizedBox(height: 24),

            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseAuth.instance.currentUser?.uid == null
                  ? const Stream<DocumentSnapshot>.empty()
                  : FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData = snapshot.data?.data() as Map<String, dynamic>?;
                final balance = (userData?['balance'] ?? 0) as num;

                final saveAmount = (balance * 0.5).round();
                final spendAmount = (balance * 0.3).round();
                final giveAmount = (balance * 0.2).round();

                return Row(
                  children: [
                    _buildBucketCard(
                      'Save'.tr,
                      '৳$saveAmount',
                      const Color(0xFF3B82F6),
                      theme,
                    ),
                    const SizedBox(width: 12),
                    _buildBucketCard(
                      'Spend'.tr,
                      '৳$spendAmount',
                      const Color(0xFFF59E0B),
                      theme,
                    ),
                    const SizedBox(width: 12),
                    _buildBucketCard(
                      'Give'.tr,
                      '৳$giveAmount',
                      const Color(0xFF10B981),
                      theme,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            Text("Today's Chores".tr, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseAuth.instance.currentUser?.uid == null 
                  ? const Stream<QuerySnapshot>.empty()
                  : FirebaseFirestore.instance
                      .collection('tasks')
                      .where('assignedTo', whereIn: [FirebaseAuth.instance.currentUser!.uid, 'all'])
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No chores assigned yet!',
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }

                final tasks = snapshot.data!.docs;

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    var taskData = tasks[index].data() as Map<String, dynamic>;
                    String title = taskData['title'] ?? 'Unnamed Task';
                    int reward = taskData['reward'] ?? 0;
                    bool isCompleted = taskData['isCompleted'] ?? false;
                    String status = taskData['status'] ?? 'Pending';
                    
                    Color statusColor;
                    switch (status) {
                      case 'Completed':
                        statusColor = const Color(0xFF10B981);
                        break;
                      case 'Pending Approval':
                        statusColor = const Color(0xFFF59E0B);
                        break;
                      case 'Ongoing':
                        statusColor = const Color(0xFF3B82F6);
                        break;
                      case 'Redo':
                        statusColor = Colors.redAccent;
                        break;
                      case 'Pending':
                      default:
                        statusColor = Colors.grey;
                    }

                    return Card(
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskDetailScreen(
                                taskId: tasks[index].id,
                                isParent: false,
                              ),
                            ),
                          );
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.check_circle
                                : (status == 'Pending' ? Icons.group : Icons.radio_button_unchecked),
                            color: statusColor,
                          ),
                        ),
                        title: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  status,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Text(
                          '৳$reward',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBucketCard(
    String title,
    String amount,
    Color color,
    ThemeData theme,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: theme.textTheme.titleMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
