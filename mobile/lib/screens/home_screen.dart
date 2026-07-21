import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_profile.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    final userProfile = context.watch<UserProfile?>();

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not Logged In")));
    }

    if (userProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final name = userProfile.firstName;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            leading: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddMenu(context),
            ),
            title: Text(userProfile.username),
            centerTitle: true,
            floating: true,
            snap: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (userProfile.photoUrl != null)
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: CachedNetworkImageProvider(
                          userProfile.photoUrl!,
                          maxWidth: 240,
                          maxHeight: 240,
                        ),
                      )
                    else
                      const CircleAvatar(
                        radius: 60,
                        child: Icon(Icons.person, size: 60),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome to Everything Passport, $name!',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your travel journey starts here.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Add New',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.flight_takeoff),
                title: const Text('Add Trip'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement Add Trip
                },
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.event),
                title: const Text('Add Event'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement Add Event
                },
              ),
              const Divider(height: 0),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
