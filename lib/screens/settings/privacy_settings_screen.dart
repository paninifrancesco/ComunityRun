import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_profile_service.dart';
import '../../models/user_profile.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  late final UserProfileService _userProfileService;
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _userProfileService = ref.read(userProfileServiceProvider);
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final profile = await _userProfileService.getUserProfile(currentUser.uid).first;
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error loading profile: ${e.toString()}');
    }
  }

  Future<void> _updatePrivacySetting(Map<String, dynamic> updates) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _userProfile == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedPrivacySettings = _userProfile!.privacySettings.toMap()..addAll(updates);
      final updatedProfile = _userProfile!.copyWith(
        privacySettings: PrivacySettings.fromMap(updatedPrivacySettings),
      );
      await _userProfileService.updateUserProfile(updatedProfile);
      
      // Update local state
      setState(() {
        _userProfile = _userProfile!.copyWith(
          privacySettings: PrivacySettings(
            showRealName: updates['showRealName'] ?? _userProfile!.privacySettings.showRealName,
            showExactLocation: updates['showExactLocation'] ?? _userProfile!.privacySettings.showExactLocation,
            allowDirectMessages: updates['allowDirectMessages'] ?? _userProfile!.privacySettings.allowDirectMessages,
            shareWithStrava: updates['shareWithStrava'] ?? _userProfile!.privacySettings.shareWithStrava,
            profileVisibility: updates['profileVisibility'] ?? _userProfile!.privacySettings.profileVisibility,
          ),
        );
      });
    } catch (e) {
      _showSnackBar('Error updating settings: ${e.toString()}');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Privacy Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Privacy Settings')),
        body: const Center(
          child: Text('Unable to load privacy settings'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildLocationPrivacyCard(),
          const SizedBox(height: 16),
          _buildProfileVisibilityCard(),
          const SizedBox(height: 16),
          _buildCommunicationCard(),
          const SizedBox(height: 16),
          _buildDataSharingCard(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Privacy Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Your privacy is important to us. These settings control what information is shared with other runners.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPrivacyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location Privacy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show Exact Location'),
              subtitle: const Text(
                'When disabled, your location will be approximate (~1km radius)',
              ),
              value: _userProfile!.privacySettings.showExactLocation,
              onChanged: _isSaving ? null : (value) {
                _updatePrivacySetting({'showExactLocation': value});
              },
            ),
            if (!_userProfile!.privacySettings.showExactLocation) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Icon(Icons.info, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Other users will see your approximate location only. Exact meeting points are shared after joining a run.',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileVisibilityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Visibility',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              title: const Text('Public'),
              subtitle: const Text('Anyone can see your profile'),
              value: 'public',
              groupValue: _userProfile!.privacySettings.profileVisibility,
              onChanged: _isSaving ? null : (value) {
                if (value != null) {
                  _updatePrivacySetting({'profileVisibility': value});
                }
              },
            ),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              title: const Text('Runners Only'),
              subtitle: const Text('Only verified runners can see your profile'),
              value: 'runners',
              groupValue: _userProfile!.privacySettings.profileVisibility,
              onChanged: _isSaving ? null : (value) {
                if (value != null) {
                  _updatePrivacySetting({'profileVisibility': value});
                }
              },
            ),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              title: const Text('Private'),
              subtitle: const Text('Only your running partners can see details'),
              value: 'private',
              groupValue: _userProfile!.privacySettings.profileVisibility,
              onChanged: _isSaving ? null : (value) {
                if (value != null) {
                  _updatePrivacySetting({'profileVisibility': value});
                }
              },
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show Real Name'),
              subtitle: const Text('Display your real name instead of username'),
              value: _userProfile!.privacySettings.showRealName,
              onChanged: _isSaving ? null : (value) {
                _updatePrivacySetting({'showRealName': value});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunicationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Communication',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Allow Direct Messages'),
              subtitle: const Text('Allow other runners to message you directly'),
              value: _userProfile!.privacySettings.allowDirectMessages,
              onChanged: _isSaving ? null : (value) {
                _updatePrivacySetting({'allowDirectMessages': value});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSharingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Sharing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Share with Strava'),
              subtitle: const Text('Allow sharing run data with Strava (when connected)'),
              value: _userProfile!.privacySettings.shareWithStrava,
              onChanged: _isSaving ? null : (value) {
                _updatePrivacySetting({'shareWithStrava': value});
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Usage',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Your location data is used only for finding nearby runs',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '• Personal information is never shared with third parties',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '• You can delete your account and data at any time',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}