import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'login_screen.dart';
import '../main.dart';
import '../core/app_translations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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

    return Scaffold(
      appBar: AppBar(title: Text('Settings'.tr)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Account'.tr, style: theme.textTheme.titleSmall),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      String familyCode = 'Loading...';
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        
                        if (data['role']?.toString().toLowerCase() == 'parent') {
                          final fId = data['familyId'];
                          if (fId == null || fId.toString().trim().isEmpty) {
                            // Legacy Fallback: Generate a random 6-character code
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid != null) {
                              WidgetsBinding.instance.addPostFrameCallback((_) async {
                                try {
                                  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
                                  final rnd = math.Random();
                                  final newCode = String.fromCharCodes(Iterable.generate(
                                      6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
                                  
                                  await FirebaseFirestore.instance.collection('users').doc(uid).update({
                                    'familyId': newCode,
                                  });
                                } catch (e) {
                                  debugPrint('Failed to generate fallback familyId: $e');
                                }
                              });
                            }
                          } else {
                            familyCode = fId.toString();
                          }
                        } else {
                          // Child role handling if they ever access this
                          familyCode = data['familyId'] ?? 'No Code';
                        }
                      }
                      return ListTile(
                        leading: Icon(
                          Icons.vpn_key_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text('Family Invite Code'),
                        subtitle: Text(
                          familyCode,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () {
                            if (familyCode != 'Loading...' && familyCode != 'No Code') {
                              Clipboard.setData(ClipboardData(text: familyCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied to clipboard')),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.lock_outline,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text('Change Password'.tr),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon!')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.notifications_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text('Notifications'.tr),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text('Preferences'.tr, style: theme.textTheme.titleSmall),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.language,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text('Language'.tr),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showLanguagePicker(context),
                  ),
                  const Divider(height: 1),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (context, currentMode, child) {
                      return ListTile(
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
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Card(
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: Text(
                  'Log Out'.tr,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(
                  'Delete Account'.tr,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Delete Account'.tr),
                      content: Text('Are you sure you want to delete your account? This action cannot be undone.'.tr),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Cancel'.tr),
                        ),
                        TextButton(
                          onPressed: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              try {
                                await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                                await user.delete();
                                if (!context.mounted) return;
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                  (route) => false,
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          child: Text('Delete'.tr, style: const TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
