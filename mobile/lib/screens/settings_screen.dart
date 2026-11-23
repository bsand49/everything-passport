import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/cache_service.dart';
import '../widgets/email_verification_banner.dart';
import 'user_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final authService = context.read<AuthService>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Pop the settings page before signing out
        Navigator.pop(context);
        await authService.signOut();
      } catch (e) {
        if (messenger.mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('Error signing out: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleClearCache(BuildContext context) async {
    final cacheService = context.read<CacheService>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cache'),
        content: const Text(
          'Clear downloaded data and cached content? You will need a '
          'connection to reload it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await cacheService.clearAll();
        if (messenger.mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Cache cleared')),
          );
        }
      } catch (e) {
        if (messenger.mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('Error clearing cache: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const EmailVerificationBanner(),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Edit Profile'),
            subtitle: const Text('Change your name, photo, and details'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmailVerificationBannerHost(
                    child: UserProfileScreen(),
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Clear cache'),
            subtitle: const Text('Clear downloaded data and cached content'),
            onTap: () => _handleClearCache(context),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: colorScheme.error),
            title: Text('Logout', style: TextStyle(color: colorScheme.error)),
            onTap: () => _handleLogout(context),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              // TODO: Use package_info_plus for dynamic versioning
              'App Version 1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
