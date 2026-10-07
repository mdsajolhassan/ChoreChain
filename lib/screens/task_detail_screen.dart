import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_translations.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  final bool isParent;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
    this.isParent = false,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _isLoading = false;

  Future<void> _updateTaskStatus(
    String newStatus,
    int reward,
    String childId,
  ) async {
    setState(() => _isLoading = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final taskRef = FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId);

      batch.update(taskRef, {
        'status': newStatus,
        'isCompleted': newStatus == 'Completed',
      });

      // If parent is approving, add funds to child's balance
      if (widget.isParent && newStatus == 'Completed') {
        if (childId != 'all' && childId.isNotEmpty) {
          final userRef = FirebaseFirestore.instance
              .collection('users')
              .doc(childId);
          batch.update(userRef, {'balance': FieldValue.increment(reward)});

          // Add to transactions
          final txRef = FirebaseFirestore.instance
              .collection('transactions')
              .doc();
          batch.set(txRef, {
            'userId': childId,
            'amount': reward,
            'type': 'Earned',
            'title': 'Task Approved',
            'timestamp': FieldValue.serverTimestamp(),
          });

          // Add notification
          final notifRef = FirebaseFirestore.instance
              .collection('notifications')
              .doc();
          batch.set(notifRef, {
            'userId': childId,
            'title': 'Task Approved! 🎉',
            'body': 'Your task was approved and you earned ৳$reward.',
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Task $newStatus')));
        Navigator.pop(context);
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Firebase Error: ${e.message}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptTask(BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final childName = userDoc.data()?['fullName'] ?? 'Child';

      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .update({
            'status': 'Ongoing',
            'assignedTo': uid,
            'assignedToName': childName,
          });

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Task accepted!')));
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Firebase Error: ${e.message}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .doc(widget.taskId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Task not found'));
          }

          final taskData = snapshot.data!.data() as Map<String, dynamic>;
          final title = taskData['title'] ?? 'Unnamed Task';
          final instructions =
              taskData['instructions'] ?? 'No instructions provided.';
          final reward = taskData['reward'] ?? 0;
          final status = taskData['status'] ?? 'Pending';
          final assignedTo = taskData['assignedTo'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(title, style: theme.textTheme.headlineSmall),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '৳$reward',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text('Instructions', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(instructions, style: theme.textTheme.bodyMedium),

                const SizedBox(height: 32),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  if (widget.isParent && status == 'Pending Approval') ...[
                    ElevatedButton(
                      onPressed: () =>
                          _updateTaskStatus('Completed', reward, assignedTo),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                      ),
                      child: Text('Approve & Pay'.tr),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _updateTaskStatus('Redo', 0, assignedTo),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                      child: const Text('Reject (Needs Redo)'),
                    ),
                  ] else if (!widget.isParent && assignedTo == 'all' && status == 'Pending') ...[
                    ElevatedButton(
                      onPressed: () => _acceptTask(context),
                      child: Text('Accept Task (Claim)'.tr),
                    ),
                  ] else if (!widget.isParent &&
                      (status == 'Pending' || status == 'Ongoing' || status == 'Redo')) ...[
                    ElevatedButton(
                      onPressed: () =>
                          _updateTaskStatus('Pending Approval', 0, assignedTo),
                      child: Text('Submit for Approval'.tr),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return const Color(0xFF10B981); // Emerald
      case 'Pending Approval':
        return const Color(0xFFF59E0B); // Amber
      case 'Redo':
        return Colors.redAccent;
      case 'Ongoing':
        return const Color(0xFF3B82F6); // Blue
      case 'Pending':
      default:
        return Colors.grey;
    }
  }
}
