import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_profile_service.dart';
import '../../services/emergency_service.dart';
import '../../models/user_profile.dart';

class EmergencySettingsScreen extends ConsumerStatefulWidget {
  const EmergencySettingsScreen({super.key});

  @override
  ConsumerState<EmergencySettingsScreen> createState() => _EmergencySettingsScreenState();
}

class _EmergencySettingsScreenState extends ConsumerState<EmergencySettingsScreen> {
  late final UserProfileService _userProfileService;
  late final EmergencyService _emergencyService;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _userProfileService = ref.read(userProfileServiceProvider);
    _emergencyService = ref.read(emergencyServiceProvider);
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final profile = await _userProfileService.getUserProfile(currentUser.uid).first;
      setState(() {
        _userProfile = profile;
        _nameController.text = profile?.safetySettings.emergencyContactName ?? '';
        _phoneController.text = profile?.safetySettings.emergencyContactPhone ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error loading profile: ${e.toString()}');
    }
  }

  Future<void> _saveEmergencyContact() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _userProfile == null) return;

    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      _showSnackBar('Please fill in both name and phone number');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Test if phone number is valid
      final isValidPhone = await _emergencyService.testEmergencyContact(_phoneController.text.trim());
      if (!isValidPhone) {
        _showSnackBar('Invalid phone number');
        return;
      }

      final updatedSafetySettings = SafetySettings(
        emergencyContactName: _nameController.text.trim(),
        emergencyContactPhone: _phoneController.text.trim(),
        shareLocationWithEmergencyContact: _userProfile!.safetySettings.shareLocationWithEmergencyContact,
        autoCheckIn: _userProfile!.safetySettings.autoCheckIn,
        checkInIntervalMinutes: _userProfile!.safetySettings.checkInIntervalMinutes,
      );

      final updatedProfile = _userProfile!.copyWith(safetySettings: updatedSafetySettings);
      await _userProfileService.updateUserProfile(updatedProfile);

      setState(() {
        _userProfile = _userProfile!.copyWith(safetySettings: updatedSafetySettings);
      });

      _showSnackBar('Emergency contact saved successfully');
    } catch (e) {
      _showSnackBar('Error saving emergency contact: ${e.toString()}');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _updateSafetySetting(Map<String, dynamic> updates) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _userProfile == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final currentSettings = _userProfile!.safetySettings.toMap();
      currentSettings.addAll(updates);

      final updatedSafetySettings = SafetySettings.fromMap(currentSettings);
      final updatedProfile = _userProfile!.copyWith(safetySettings: updatedSafetySettings);
      await _userProfileService.updateUserProfile(updatedProfile);

      setState(() {
        _userProfile = _userProfile!.copyWith(
          safetySettings: SafetySettings.fromMap(currentSettings),
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

  Future<void> _testEmergencyContact() async {
    if (_phoneController.text.trim().isEmpty) {
      _showSnackBar('Please enter a phone number first');
      return;
    }

    try {
      await _emergencyService.shareLocationWithEmergencyContact(
        userId: FirebaseAuth.instance.currentUser!.uid,
        message: 'This is a test message from CommunityRun. Your emergency contact is working correctly.',
      );
      _showSnackBar('Test message sent successfully');
    } catch (e) {
      _showSnackBar('Test failed: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Emergency Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildEmergencyContactCard(),
            const SizedBox(height: 16),
            _buildAutoCheckInCard(),
            const SizedBox(height: 16),
            _buildEmergencyActionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.red.shade50,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emergency, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Emergency Safety',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Configure emergency contacts and safety features to ensure help can reach you quickly during runs.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency Contact',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Contact Name',
                hintText: 'Enter emergency contact name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+39 123 456 7890',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveEmergencyContact,
                    icon: const Icon(Icons.save),
                    label: _isSaving
                        ? const Text('Saving...')
                        : const Text('Save Contact'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _phoneController.text.trim().isEmpty ? null : _testEmergencyContact,
                  icon: const Icon(Icons.send),
                  tooltip: 'Test Emergency Contact',
                ),
              ],
            ),
            if (_userProfile?.safetySettings.emergencyContactPhone != null) ...[
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Share Location with Emergency Contact'),
                subtitle: const Text('Automatically share your location during emergencies'),
                value: _userProfile!.safetySettings.shareLocationWithEmergencyContact,
                onChanged: _isSaving ? null : (value) {
                  _updateSafetySetting({'shareLocationWithEmergencyContact': value});
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAutoCheckInCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Auto Check-In',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Automatically check your safety during runs',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable Auto Check-In'),
              subtitle: const Text('Send check-in notifications during runs'),
              value: _userProfile?.safetySettings.autoCheckIn ?? false,
              onChanged: _isSaving ? null : (value) {
                _updateSafetySetting({'autoCheckIn': value});
              },
            ),
            if (_userProfile?.safetySettings.autoCheckIn == true) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Check-in interval: '),
                  DropdownButton<int>(
                    value: _userProfile!.safetySettings.checkInIntervalMinutes,
                    onChanged: _isSaving ? null : (value) {
                      if (value != null) {
                        _updateSafetySetting({'checkInIntervalMinutes': value});
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 15, child: Text('15 minutes')),
                      DropdownMenuItem(value: 30, child: Text('30 minutes')),
                      DropdownMenuItem(value: 45, child: Text('45 minutes')),
                      DropdownMenuItem(value: 60, child: Text('1 hour')),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.call, color: Colors.red),
              title: const Text('Call Emergency Services'),
              subtitle: const Text('Quick dial 112 (Italy emergency number)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                try {
                  await _emergencyService.callEmergencyServices(countryCode: 'IT');
                } catch (e) {
                  _showSnackBar('Error calling emergency services: ${e.toString()}');
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on, color: Colors.orange),
              title: const Text('Share Current Location'),
              subtitle: const Text('Send your location to emergency contact'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _userProfile?.safetySettings.emergencyContactPhone == null
                  ? null
                  : () async {
                      try {
                        await _emergencyService.shareLocationWithEmergencyContact(
                          userId: FirebaseAuth.instance.currentUser!.uid,
                        );
                        _showSnackBar('Location shared successfully');
                      } catch (e) {
                        _showSnackBar('Error sharing location: ${e.toString()}');
                      }
                    },
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}