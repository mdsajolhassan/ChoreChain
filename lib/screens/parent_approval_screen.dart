import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'task_detail_screen.dart';

class ParentApprovalScreen extends StatelessWidget {
  const ParentApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Approvals')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseAuth.instance.currentUser?.uid == null 
            ? const Stream<QuerySnapshot>.empty()
            : FirebaseFirestore.instance
                .collection('tasks')
                .where('parentId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                .where('status', isEqualTo: 'Pending Approval')
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
                'No pending approvals right now!',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          final approvalTasks = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(24.0),
            itemCount: approvalTasks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              var task = approvalTasks[index];
              String taskId = task.id;
              String taskName = task['title'] ?? 'Task';
              String assignedToName =
                  (task.data() as Map<String, dynamic>).containsKey(
                    'assignedToName',
                  )
                  ? task['assignedToName']
                  : 'Child';
              int reward = task['reward'] ?? 0;

              return Card(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TaskDetailScreen(taskId: taskId, isParent: true),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              child: Text(
                                assignedToName.isNotEmpty
                                    ? assignedToName[0]
                                    : '?',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  assignedToName,
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  taskName,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              '৳$reward',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
