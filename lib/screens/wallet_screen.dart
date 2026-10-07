import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
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

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Total Balance',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '৳$balance',
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text('My Buckets', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),

                    _buildDetailedBucket(
                      'Save',
                      '৳$saveAmount',
                      '50% of total',
                      Icons.savings_outlined,
                      const Color(0xFF3B82F6),
                      theme,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailedBucket(
                      'Spend',
                      '৳$spendAmount',
                      '30% of total',
                      Icons.shopping_bag_outlined,
                      const Color(0xFFF59E0B),
                      theme,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailedBucket(
                      'Give',
                      '৳$giveAmount',
                      '20% of total',
                      Icons.favorite_outline,
                      const Color(0xFF10B981),
                      theme,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),
            Text('Recent Transactions', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No transactions yet.'));
                }

                // Sort and limit locally to avoid needing a composite index
                var docs = snapshot.data!.docs;
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['timestamp'] as Timestamp?;
                  final bTime = bData['timestamp'] as Timestamp?;
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });

                final limitedDocs = docs.take(10).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: limitedDocs.length,
                  itemBuilder: (context, index) {
                    final tx =
                        limitedDocs[index].data() as Map<String, dynamic>;
                    final amount = tx['amount'] ?? 0;
                    final title = tx['title'] ?? 'Transaction';
                    final type = tx['type'] ?? 'Earned'; // Earned or Spent
                    final timestamp = tx['timestamp'] as Timestamp?;
                    final dateStr = timestamp != null
                        ? DateFormat('MMM d, yyyy - h:mm a')
                              .format(timestamp.toDate())
                        : 'Pending';

                    final isEarned = type == 'Earned';
                    final color = isEarned
                        ? const Color(0xFF10B981)
                        : Colors.redAccent;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.1),
                        child: Icon(
                          isEarned ? Icons.arrow_downward : Icons.arrow_upward,
                          color: color,
                        ),
                      ),
                      title: Text(title, style: theme.textTheme.titleMedium),
                      subtitle: Text(dateStr, style: theme.textTheme.bodySmall),
                      trailing: Text(
                        '${isEarned ? '+' : '-'}৳$amount',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: color,
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

  Widget _buildDetailedBucket(
    String title,
    String amount,
    String subtitle,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Container(
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
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            amount,
            style: theme.textTheme.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
