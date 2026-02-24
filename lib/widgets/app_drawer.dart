import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../about.dart';
import '../home.dart';
import '../login.dart';
import '../settings.dart';
import '../utils/snackbar_helper.dart';

class AppDrawer extends StatelessWidget {

  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {

    final firebaseUser = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset("assets/images/logo-removebg.png", height: 140),
            const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'welcomeBack'.tr(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              )
            ),
            
            const Divider(height: 10),

            _MenuTile(
              icon: Icons.home_outlined,
              title: 'home'.tr(),
              onTap: () => _push(context, const HomeScreen()),
            ),

            _MenuTile(
              icon: Icons.info_outline,
              title: 'aboutUs'.tr(),
              onTap: () => _push(context, const AboutScreen()),
            ),

            _MenuTile(
              icon: Icons.privacy_tip_outlined,
              title: 'privacyPolicy'.tr(),
              onTap: () => _push(context, const PrivacyPolicyScreen()),
            ),

            _MenuTile(
              icon: Icons.description_outlined,
              title: 'termsOfService'.tr(),
              onTap: () => _push(context, const TermsOfServiceScreen()),
            ),

            _MenuTile(
              icon: Icons.settings,
              title: 'settings'.tr(),
              onTap: () => _push(context, SettingsScreen(
                  user: UserData(
                    name: firebaseUser?.displayName ?? 'No Name',
                    photoUrl: firebaseUser?.photoURL ?? '',
                  ),
                )
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    await GoogleSignIn.instance.signOut();
                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const GoogleSignInPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'auth.log_out'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool enabled;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: enabled ? Colors.pinkAccent : Colors.black38,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? Colors.black : Colors.black38,
        ),
      ),
      onTap: enabled
          ? onTap
          : () => SnackBarHelper.showSuccess(context, 'Please sign in to access this feature'),
    );
  }
}