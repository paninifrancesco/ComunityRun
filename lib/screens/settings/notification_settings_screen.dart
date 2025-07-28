import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_profile.dart';
import '../../services/user_profile_service.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  bool _isLoading = false;
  bool _hasNotificationPermission = false;
  NotificationSettings? _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkNotificationPermission();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser != null) {
        setState(() {
          _settings = currentUser.notificationSettings;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkNotificationPermission() async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      final hasPermission = await notificationService.hasNotificationPermission();
      setState(() {
        _hasNotificationPermission = hasPermission;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _updateSettings(NotificationSettings newSettings) async {
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) return;

      final userProfileService = ref.read(userProfileServiceProvider);
      final userProfile = await userProfileService.getUserProfileOnce(currentUser.uid);
      if (userProfile != null) {
        final updatedProfile = userProfile.copyWith(
          notificationSettings: newSettings,
        );
        await userProfileService.updateUserProfile(updatedProfile);
      }

      setState(() {
        _settings = newSettings;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.openNotificationSettings();
      await _checkNotificationPermission();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open notification settings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _settings == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notification Settings'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_hasNotificationPermission) ...[
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_off,
                      size: 48,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Notifications Disabled',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enable notifications to stay updated about your runs, new messages, and important updates.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _requestNotificationPermission,
                      icon: const Icon(Icons.settings),
                      label: const Text('Enable Notifications'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          _buildNotificationSection(
            'Run Notifications',
            Icons.directions_run,
            [
              _buildSwitchTile(
                'New runs in your area',
                'Get notified when new runs are created near you',
                _settings!.newRunInArea,
                (value) => _updateSettings(_settings!.copyWith(newRunInArea: value)),
              ),
              _buildSwitchTile(
                'Run updates',
                'Get notified when run details change',
                _settings!.runUpdates,
                (value) => _updateSettings(_settings!.copyWith(runUpdates: value)),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildNotificationSection(
            'Communication',
            Icons.chat,
            [
              _buildSwitchTile(
                'New messages',
                'Get notified about new messages in run chats',
                _settings!.messages,
                (value) => _updateSettings(_settings!.copyWith(messages: value)),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildNotificationSection(
            'Safety & Important',
            Icons.security,
            [
              _buildSwitchTile(
                'Safety alerts',
                'Critical safety notifications (always enabled)',
                _settings!.safetyAlerts,
                null, // Always enabled for safety
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildNotificationSection(
            'Digest & Summary',
            Icons.summarize,
            [
              _buildSwitchTile(
                'Weekly digest',
                'Get a weekly summary of your running activity',
                _settings!.weeklyDigest,
                (value) => _updateSettings(_settings!.copyWith(weeklyDigest: value)),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildQuietHoursSection(),
          
          const SizedBox(height: 32),
          
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'About Notifications',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Safety alerts cannot be disabled for your security\n'
                    '• Notifications respect your quiet hours settings\n'
                    '• You can manage notification sounds in your device settings',
                    style: TextStyle(height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool>? onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).primaryColor,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildQuietHoursSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bedtime, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Quiet Hours',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'No notifications will be sent during these hours (except safety alerts)',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start Time', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectTime(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_settings!.quietHoursStart.toString().padLeft(2, '0')}:00',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('End Time', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectTime(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_settings!.quietHoursEnd.toString().padLeft(2, '0')}:00',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(bool isStartTime) async {
    final currentHour = isStartTime ? _settings!.quietHoursStart : _settings!.quietHoursEnd;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: 0),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (time != null) {
      if (isStartTime) {
        _updateSettings(_settings!.copyWith(quietHoursStart: time.hour));
      } else {
        _updateSettings(_settings!.copyWith(quietHoursEnd: time.hour));
      }
    }
  }
}

extension NotificationSettingsExtension on NotificationSettings {
  NotificationSettings copyWith({
    bool? newRunInArea,
    bool? runUpdates,
    bool? messages,
    bool? safetyAlerts,
    bool? weeklyDigest,
    int? quietHoursStart,
    int? quietHoursEnd,
  }) {
    return NotificationSettings(
      newRunInArea: newRunInArea ?? this.newRunInArea,
      runUpdates: runUpdates ?? this.runUpdates,
      messages: messages ?? this.messages,
      safetyAlerts: safetyAlerts ?? this.safetyAlerts,
      weeklyDigest: weeklyDigest ?? this.weeklyDigest,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }
}