import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';
import 'edit_profile_screen.dart';
import '../main.dart'; // import themeNotifier
import '../core/app_translations.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Language'.tr,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('English'),
                onTap: () {
                  AppTranslations.changeLanguage('en');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('বাংলা (Bengali)'),
                onTap: () {
                  AppTranslations.changeLanguage('bn');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('हिन्दी (Hindi)'),
                onTap: () {
                  AppTranslations.changeLanguage('hi');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text('Profile'.tr)),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<DocumentSnapshot>(
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

                final childData = snapshot.data?.data() as Map<String, dynamic>?;
                final childName = childData?['fullName'] ?? 'No Name';
                final childEmail = user.email ?? '';
                final parentId = childData?['parentId'];

                return ListView(
                  padding: const EdgeInsets.all(24.0),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('My Profile'.tr, style: theme.textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          Text(
                            childName,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            childEmail,
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (parentId != null)
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('users').doc(parentId).get(),
                              builder: (context, parentSnapshot) {
                                if (parentSnapshot.hasData && parentSnapshot.data!.exists) {
                                  final parentData = parentSnapshot.data!.data() as Map<String, dynamic>;
                                  final parentName = parentData['fullName'] ?? '';
                                  final parentEmail = parentData['email'] ?? '';
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      '${'Parents'.tr}: $parentName - $parentEmail',
                                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    Text('Account'.tr, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    _buildSettingsTile(Icons.person_outline, 'Edit Profile'.tr, theme, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                      );
                    }),
                    _buildSettingsTile(
                      Icons.lock_outline,
                      'Change Password'.tr,
                      theme,
                      () async {
                        if (user.email != null) {
                          await FirebaseAuth.instance.sendPasswordResetEmail(
                            email: user.email!,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password reset email sent!')),
                            );
                          }
                        }
                      },
                    ),
                    _buildSettingsTile(
                      Icons.notifications_outlined,
                      'Notifications'.tr,
                      theme,
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notifications coming soon!')),
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    Text('Preferences'.tr, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    _buildSettingsTile(Icons.language, 'Language'.tr, theme, () {
                      _showLanguagePicker(context);
                    }),
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: themeNotifier,
                      builder: (context, currentMode, child) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.dark_mode_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            title: Text('Dark Mode'.tr),
                            trailing: Switch(
                              value: currentMode == ThemeMode.dark,
                              onChanged: (val) {
                                themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                              },
                              activeThumbColor: theme.colorScheme.primary,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.logout),
                      label: Text('Log Out'.tr),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (childData?['deletionRequested'] == true) 
                            ? Colors.grey.withValues(alpha: 0.1) 
                            : Colors.red.withValues(alpha: 0.1),
                        foregroundColor: (childData?['deletionRequested'] == true) 
                            ? Colors.grey 
                            : Colors.red,
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.delete_forever),
                      label: Text(
                        (childData?['deletionRequested'] == true) 
                            ? 'Deletion request pending'.tr 
                            : 'Delete Account'.tr,
                      ),
                      onPressed: (childData?['deletionRequested'] == true) ? null : () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('Delete Account'.tr),
                            content: Text('Request account deletion from your parent?'.tr),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text('Cancel'.tr),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  final user = FirebaseAuth.instance.currentUser;
                                  if (user != null) {
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user.uid)
                                          .update({'deletionRequested': true});
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Request sent to parent'.tr)),
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  }
                                },
                                child: Text('Request'.tr, style: const TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    ThemeData theme,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
