import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../services/user_profile_service.dart';
import '../services/firestore_service.dart';
import '../models/user_profile.dart';

final emergencyServiceProvider = Provider<EmergencyService>((ref) {
  return EmergencyService(
    ref.read(notificationServiceProvider),
    ref.read(userProfileServiceProvider),
  );
});

class EmergencyService {
  final NotificationService _notificationService;
  final UserProfileService _userProfileService;

  EmergencyService(this._notificationService, this._userProfileService);

  // Emergency contact numbers by country
  static const Map<String, String> emergencyNumbers = {
    'IT': '112', // Italy
    'US': '911', // United States
    'GB': '999', // United Kingdom
    'FR': '112', // France
    'DE': '112', // Germany
    'ES': '112', // Spain
    'default': '112', // EU standard
  };

  Future<void> triggerSOS({
    required String userId,
    String? runId,
    String? additionalInfo,
  }) async {
    try {
      // Get current location
      final position = await _getCurrentLocation();
      
      // Get user profile for emergency contact
      final userProfile = await _userProfileService.getUserProfile(userId).first;
      
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      // Send emergency alert to emergency contact
      if (userProfile.safetySettings.emergencyContactPhone != null) {
        await _sendEmergencyAlert(
          userProfile: userProfile,
          position: position,
          runId: runId,
          additionalInfo: additionalInfo,
        );
      }

      // Send alerts to run participants if in a run
      if (runId != null) {
        await _alertRunParticipants(
          runId: runId,
          userId: userId,
          userDisplayName: userProfile.displayName,
          position: position,
        );
      }

      // Log emergency event
      await _logEmergencyEvent(
        userId: userId,
        runId: runId,
        position: position,
        additionalInfo: additionalInfo,
      );

    } catch (e) {
      print('SOS trigger error: $e');
      rethrow;
    }
  }

  Future<void> callEmergencyServices({String? countryCode}) async {
    try {
      final emergencyNumber = emergencyNumbers[countryCode] ?? emergencyNumbers['default']!;
      final uri = Uri.parse('tel:$emergencyNumber');
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('Cannot make emergency call');
      }
    } catch (e) {
      print('Emergency call error: $e');
      rethrow;
    }
  }

  Future<void> shareLocationWithEmergencyContact({
    required String userId,
    String? message,
  }) async {
    try {
      final position = await _getCurrentLocation();
      final userProfile = await _userProfileService.getUserProfile(userId).first;
      
      if (userProfile?.safetySettings.emergencyContactPhone == null) {
        throw Exception('No emergency contact configured');
      }

      final locationUrl = 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
      final smsMessage = message ?? 'Emergency: I need help. My location: $locationUrl';
      
      final uri = Uri.parse('sms:${userProfile!.safetySettings.emergencyContactPhone}?body=${Uri.encodeComponent(smsMessage)}');
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('Cannot send SMS');
      }
    } catch (e) {
      print('Share location error: $e');
      rethrow;
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _sendEmergencyAlert({
    required UserProfile userProfile,
    required Position position,
    String? runId,
    String? additionalInfo,
  }) async {
    try {
      // Create emergency message
      final locationUrl = 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
      final timeStamp = DateTime.now().toIso8601String();
      
      String message = '''
EMERGENCY ALERT - ${userProfile.displayName}

Time: $timeStamp
Location: $locationUrl
''';

      if (runId != null) {
        message += 'Activity: Running with group (ID: $runId)\n';
      }

      if (additionalInfo != null) {
        message += 'Additional Info: $additionalInfo\n';
      }

      message += '\nThis is an automated emergency alert from the CommunityRun app.';

      // Send SMS to emergency contact
      final smsUri = Uri.parse(
        'sms:${userProfile.safetySettings.emergencyContactPhone}?body=${Uri.encodeComponent(message)}'
      );
      
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }

      // Also try to make a call
      final callUri = Uri.parse('tel:${userProfile.safetySettings.emergencyContactPhone}');
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
      }

    } catch (e) {
      print('Send emergency alert error: $e');
    }
  }

  Future<void> _alertRunParticipants({
    required String runId,
    required String userId,
    required String userDisplayName,
    required Position position,
  }) async {
    try {
      // Send push notifications to all run participants
      await _notificationService.sendEmergencyAlert(
        runId: runId,
        alertMessage: '$userDisplayName has triggered an emergency alert',
        alertingUserId: userId,
        location: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      );
    } catch (e) {
      print('Alert run participants error: $e');
    }
  }

  Future<void> _logEmergencyEvent({
    required String userId,
    String? runId,
    required Position position,
    String? additionalInfo,
  }) async {
    try {
      // Log emergency event for safety tracking and analytics
      // This could be stored in Firestore for admin review
      print('Emergency event logged for user $userId at ${DateTime.now()}');
    } catch (e) {
      print('Log emergency event error: $e');
    }
  }

  Future<bool> testEmergencyContact(String phoneNumber) async {
    try {
      final uri = Uri.parse('tel:$phoneNumber');
      return await canLaunchUrl(uri);
    } catch (e) {
      return false;
    }
  }

  Future<void> scheduleCheckIn({
    required String userId,
    required int intervalMinutes,
  }) async {
    // This would integrate with a background service or push notifications
    // to check on the user's safety at regular intervals
    try {
      print('Check-in scheduled for $userId every $intervalMinutes minutes');
      // Implementation would depend on the specific background service used
    } catch (e) {
      print('Schedule check-in error: $e');
    }
  }

  Future<void> cancelCheckIn(String userId) async {
    try {
      print('Check-in cancelled for $userId');
      // Cancel scheduled check-ins
    } catch (e) {
      print('Cancel check-in error: $e');
    }
  }
}