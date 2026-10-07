import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChildRewardsScreen extends StatefulWidget {
  const ChildRewardsScreen({super.key});

  @override
  State<ChildRewardsScreen> createState() => _ChildRewardsScreenState();
}

class _ChildRewardsScreenState extends State<ChildRewardsScreen> {
  bool _isRedeeming = false;

  Future<void> _redeemReward(String title, int cost, num currentBalance) async {
    if (currentBalance < cost) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Not enough balance!')));
      return;
    }

    setState(() => _isRedeeming = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final batch = FirebaseFirestore.instance.batch();

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      batch.update(userRef, {'balance': FieldValue.increment(-cost)});

      final txRef = FirebaseFirestore.instance.collection('transactions').doc();
      batch.set(txRef, {
        'userId': user.uid,
        'amount': cost,
        'type': 'Spent',
        'title': 'Redeemed: $title',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully redeemed $title!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isRedeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        num balance = 0;
        int level = 1;
        int points = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          balance = data['balance'] ?? 0;
          level = data['level'] ?? 1;
          points = data['points'] ?? 0;
        }

        int pointsRequired = level * 100;
        int pointsToNext = pointsRequired - points;
        if (pointsToNext < 0) pointsToNext = 0;
        double progress = points / pointsRequired;
        if (progress > 1.0) progress = 1.0;

        String levelTitle = level == 1
            ? 'Starter'
            : (level == 2 ? 'Helper' : 'Rising Star');

        return Scaffold(
          appBar: AppBar(
            title: const Text('Rewards'),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Text(
                    '৳$balance available',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.stars,
                        color: theme.colorScheme.primary,
                        size: 40,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Level $level: $levelTitle',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.2),
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$pointsToNext points to Level ${level + 1}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                Text('Available to Redeem', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),

                _buildRewardItem(
                  'Extra Screen Time (1 hr)',
                  50,
                  Icons.tv,
                  balance,
                  theme,
                ),
                const SizedBox(height: 12),
                _buildRewardItem(
                  'Skip a Chore',
                  100,
                  Icons.fast_forward,
                  balance,
                  theme,
                ),
                const SizedBox(height: 12),
                _buildRewardItem(
                  'Pizza Night Choice',
                  300,
                  Icons.local_pizza,
                  balance,
                  theme,
                ),
                const SizedBox(height: 12),
                _buildRewardItem(
                  'New Video Game',
                  1000,
                  Icons.gamepad,
                  balance,
                  theme,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRewardItem(
    String title,
    int cost,
    IconData icon,
    num currentBalance,
    ThemeData theme,
  ) {
    bool canAfford = currentBalance >= cost;

    return Opacity(
      opacity: canAfford ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: theme.colorScheme.secondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '৳$cost',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary.withValues(
                  alpha: 0.1,
                ),
                foregroundColor: theme.colorScheme.secondary,
                elevation: 0,
              ),
              onPressed: _isRedeeming
                  ? null
                  : () => _redeemReward(title, cost, currentBalance),
              child: const Text('Redeem'),
            ),
          ],
        ),
      ),
    );
  }
}
