import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSettingsSection(
            context,
            'Account',
            [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile Settings'),
                subtitle: const Text('Manage your profile information'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to profile settings
                },
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Privacy'),
                subtitle: const Text('Control your privacy settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to privacy settings  
                },
              ),
            ],
          ),
          _buildSettingsSection(
            context,
            'Notifications',
            [
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Push Notifications'),
                subtitle: const Text('Manage notification preferences'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to notification settings
                },
              ),
            ],
          ),
          _buildSettingsSection(
            context,
            'Running Preferences',
            [
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Preferred Times'),
                subtitle: const Text('Set your preferred running times'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to time preferences
                },
              ),
              ListTile(
                leading: const Icon(Icons.speed),
                title: const Text('Pace & Distance'),
                subtitle: const Text('Configure your running preferences'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to pace/distance settings
                },
              ),
            ],
          ),
          _buildSettingsSection(
            context,
            'Safety',
            [
              ListTile(
                leading: const Icon(Icons.emergency),
                title: const Text('Emergency Contacts'),
                subtitle: const Text('Manage emergency contact information'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to emergency contacts
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Location Sharing'),
                subtitle: const Text('Control location sharing settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to location settings
                },
              ),
            ],
          ),
          _buildSettingsSection(
            context,
            'About',
            [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('App Version'),
                subtitle: const Text('1.0.0'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to help
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}