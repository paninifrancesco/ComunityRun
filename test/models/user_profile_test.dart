import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:communityrun/models/user_profile.dart';

void main() {
  group('UserProfile Model Tests', () {
    late UserProfile testProfile;

    setUp(() {
      testProfile = UserProfile(
        uid: 'user_123',
        displayName: 'Mario Rossi',
        email: 'mario.rossi@example.com',
        photoUrl: 'https://example.com/photo.jpg',
        bio: 'Passionate runner from Milan',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastActive: DateTime(2024, 3, 10, 15, 30),
        runningPreferences: const RunningPreferences(
          preferredPaces: ['5:00-5:30', '5:30-6:00'],
          preferredDistances: ['5K', '10K'],
          preferredTimes: ['morning', 'evening'],
          runningGoals: ['fitness', 'social'],
          maxGroupSize: 8,
          openToNewRunners: true,
        ),
        notificationSettings: const NotificationSettings(
          newRunInArea: true,
          runUpdates: true,
          messages: true,
          safetyAlerts: true,
          weeklyDigest: false,
          quietHoursStart: 22,
          quietHoursEnd: 7,
        ),
        privacySettings: const PrivacySettings(
          showRealName: true,
          showExactLocation: false,
          allowDirectMessages: true,
          shareWithStrava: false,
          profileVisibility: 'public',
        ),
        safetySettings: const SafetySettings(
          emergencyContactName: 'Anna Rossi',
          emergencyContactPhone: '+39 123 456 7890',
          shareLocationWithEmergencyContact: true,
          autoCheckIn: false,
          checkInIntervalMinutes: 30,
        ),
        stravaUserId: 'strava_123',
        totalRuns: 42,
        totalDistance: 250.5,
        blockedUsers: ['blocked_user_1'],
        reportedUsers: ['reported_user_1'],
      );
    });

    test('should create UserProfile with all properties', () {
      expect(testProfile.uid, 'user_123');
      expect(testProfile.displayName, 'Mario Rossi');
      expect(testProfile.email, 'mario.rossi@example.com');
      expect(testProfile.bio, 'Passionate runner from Milan');
      expect(testProfile.totalRuns, 42);
      expect(testProfile.totalDistance, 250.5);
      expect(testProfile.stravaUserId, 'strava_123');
    });

    test('should convert UserProfile to Map correctly', () {
      final map = testProfile.toMap();
      
      expect(map['uid'], 'user_123');
      expect(map['displayName'], 'Mario Rossi');
      expect(map['email'], 'mario.rossi@example.com');
      expect(map['bio'], 'Passionate runner from Milan');
      expect(map['totalRuns'], 42);
      expect(map['totalDistance'], 250.5);
      expect(map['stravaUserId'], 'strava_123');
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['lastActive'], isA<Timestamp>());
      expect(map['runningPreferences'], isA<Map<String, dynamic>>());
      expect(map['notificationSettings'], isA<Map<String, dynamic>>());
      expect(map['privacySettings'], isA<Map<String, dynamic>>());
      expect(map['safetySettings'], isA<Map<String, dynamic>>());
      expect(map['blockedUsers'], ['blocked_user_1']);
      expect(map['reportedUsers'], ['reported_user_1']);
    });

    test('should create UserProfile from Map correctly', () {
      final map = testProfile.toMap();
      final recreatedProfile = UserProfile.fromMap(map);
      
      expect(recreatedProfile.uid, testProfile.uid);
      expect(recreatedProfile.displayName, testProfile.displayName);
      expect(recreatedProfile.email, testProfile.email);
      expect(recreatedProfile.bio, testProfile.bio);
      expect(recreatedProfile.totalRuns, testProfile.totalRuns);
      expect(recreatedProfile.totalDistance, testProfile.totalDistance);
      expect(recreatedProfile.stravaUserId, testProfile.stravaUserId);
      expect(recreatedProfile.blockedUsers, testProfile.blockedUsers);
      expect(recreatedProfile.reportedUsers, testProfile.reportedUsers);
    });

    test('should handle copyWith correctly', () {
      final updatedProfile = testProfile.copyWith(
        displayName: 'Giuseppe Verdi',
        bio: 'Updated bio',
        totalRuns: 50,
      );
      
      expect(updatedProfile.displayName, 'Giuseppe Verdi');
      expect(updatedProfile.bio, 'Updated bio');
      expect(updatedProfile.totalRuns, 50);
      // Original values should remain unchanged for other fields
      expect(updatedProfile.uid, testProfile.uid);
      expect(updatedProfile.email, testProfile.email);
      expect(updatedProfile.totalDistance, testProfile.totalDistance);
    });

    test('should handle missing optional fields in fromMap', () {
      final minimalMap = {
        'uid': 'user_123',
        'displayName': 'Test User',
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'lastActive': Timestamp.fromDate(DateTime.now()),
        'runningPreferences': {},
        'notificationSettings': {},
        'privacySettings': {},
        'safetySettings': {},
      };
      
      final profile = UserProfile.fromMap(minimalMap);
      
      expect(profile.uid, 'user_123');
      expect(profile.displayName, 'Test User');
      expect(profile.email, null);
      expect(profile.bio, null);
      expect(profile.totalRuns, 0); // default value
      expect(profile.totalDistance, 0.0); // default value
      expect(profile.blockedUsers, isEmpty);
      expect(profile.reportedUsers, isEmpty);
    });
  });

  group('RunningPreferences Model Tests', () {
    late RunningPreferences testPreferences;

    setUp(() {
      testPreferences = const RunningPreferences(
        preferredPaces: ['5:00-5:30', '5:30-6:00'],
        preferredDistances: ['5K', '10K', 'Half Marathon'],
        preferredTimes: ['morning', 'evening'],
        runningGoals: ['fitness', 'weight loss', 'social'],
        maxGroupSize: 6,
        openToNewRunners: true,
      );
    });

    test('should create RunningPreferences with all properties', () {
      expect(testPreferences.preferredPaces, ['5:00-5:30', '5:30-6:00']);
      expect(testPreferences.preferredDistances, ['5K', '10K', 'Half Marathon']);
      expect(testPreferences.preferredTimes, ['morning', 'evening']);
      expect(testPreferences.maxGroupSize, 6);
      expect(testPreferences.openToNewRunners, true);
    });

    test('should convert to Map correctly', () {
      final map = testPreferences.toMap();
      
      expect(map['preferredPaces'], ['5:00-5:30', '5:30-6:00']);
      expect(map['preferredDistances'], ['5K', '10K', 'Half Marathon']);
      expect(map['maxGroupSize'], 6);
      expect(map['openToNewRunners'], true);
    });

    test('should create from Map correctly', () {
      final map = testPreferences.toMap();
      final recreated = RunningPreferences.fromMap(map);
      
      expect(recreated.preferredPaces, testPreferences.preferredPaces);
      expect(recreated.preferredDistances, testPreferences.preferredDistances);
      expect(recreated.maxGroupSize, testPreferences.maxGroupSize);
      expect(recreated.openToNewRunners, testPreferences.openToNewRunners);
    });
  });

  group('NotificationSettings Model Tests', () {
    late NotificationSettings testSettings;

    setUp(() {
      testSettings = const NotificationSettings(
        newRunInArea: true,
        runUpdates: true,
        messages: false,
        safetyAlerts: true,
        weeklyDigest: true,
        quietHoursStart: 23,
        quietHoursEnd: 6,
      );
    });

    test('should create NotificationSettings with all properties', () {
      expect(testSettings.newRunInArea, true);
      expect(testSettings.runUpdates, true);
      expect(testSettings.messages, false);
      expect(testSettings.safetyAlerts, true);
      expect(testSettings.weeklyDigest, true);
      expect(testSettings.quietHoursStart, 23);
      expect(testSettings.quietHoursEnd, 6);
    });

    test('should convert to Map correctly', () {
      final map = testSettings.toMap();
      
      expect(map['newRunInArea'], true);
      expect(map['runUpdates'], true);
      expect(map['messages'], false);
      expect(map['quietHoursStart'], 23);
      expect(map['quietHoursEnd'], 6);
    });

    test('should create from Map correctly', () {
      final map = testSettings.toMap();
      final recreated = NotificationSettings.fromMap(map);
      
      expect(recreated.newRunInArea, testSettings.newRunInArea);
      expect(recreated.messages, testSettings.messages);
      expect(recreated.quietHoursStart, testSettings.quietHoursStart);
    });
  });

  group('PrivacySettings Model Tests', () {
    late PrivacySettings testSettings;

    setUp(() {
      testSettings = const PrivacySettings(
        showRealName: false,
        showExactLocation: false,
        allowDirectMessages: true,
        shareWithStrava: true,
        profileVisibility: 'friends-only',
      );
    });

    test('should create PrivacySettings with all properties', () {
      expect(testSettings.showRealName, false);
      expect(testSettings.showExactLocation, false);
      expect(testSettings.allowDirectMessages, true);
      expect(testSettings.shareWithStrava, true);
      expect(testSettings.profileVisibility, 'friends-only');
    });

    test('should convert to Map correctly', () {
      final map = testSettings.toMap();
      
      expect(map['showRealName'], false);
      expect(map['showExactLocation'], false);
      expect(map['allowDirectMessages'], true);
      expect(map['shareWithStrava'], true);
      expect(map['profileVisibility'], 'friends-only');
    });

    test('should create from Map correctly', () {
      final map = testSettings.toMap();
      final recreated = PrivacySettings.fromMap(map);
      
      expect(recreated.showRealName, testSettings.showRealName);
      expect(recreated.allowDirectMessages, testSettings.allowDirectMessages);
      expect(recreated.profileVisibility, testSettings.profileVisibility);
    });
  });

  group('SafetySettings Model Tests', () {
    late SafetySettings testSettings;

    setUp(() {
      testSettings = const SafetySettings(
        emergencyContactName: 'Anna Rossi',
        emergencyContactPhone: '+39 123 456 7890',
        shareLocationWithEmergencyContact: true,
        autoCheckIn: true,
        checkInIntervalMinutes: 20,
      );
    });

    test('should create SafetySettings with all properties', () {
      expect(testSettings.emergencyContactName, 'Anna Rossi');
      expect(testSettings.emergencyContactPhone, '+39 123 456 7890');
      expect(testSettings.shareLocationWithEmergencyContact, true);
      expect(testSettings.autoCheckIn, true);
      expect(testSettings.checkInIntervalMinutes, 20);
    });

    test('should convert to Map correctly', () {
      final map = testSettings.toMap();
      
      expect(map['emergencyContactName'], 'Anna Rossi');
      expect(map['emergencyContactPhone'], '+39 123 456 7890');
      expect(map['shareLocationWithEmergencyContact'], true);
      expect(map['autoCheckIn'], true);
      expect(map['checkInIntervalMinutes'], 20);
    });

    test('should create from Map correctly', () {
      final map = testSettings.toMap();
      final recreated = SafetySettings.fromMap(map);
      
      expect(recreated.emergencyContactName, testSettings.emergencyContactName);
      expect(recreated.emergencyContactPhone, testSettings.emergencyContactPhone);
      expect(recreated.shareLocationWithEmergencyContact, testSettings.shareLocationWithEmergencyContact);
      expect(recreated.autoCheckIn, testSettings.autoCheckIn);
      expect(recreated.checkInIntervalMinutes, testSettings.checkInIntervalMinutes);
    });

    test('should handle null emergency contact fields', () {
      const settingsWithNulls = SafetySettings(
        emergencyContactName: null,
        emergencyContactPhone: null,
        shareLocationWithEmergencyContact: false,
        autoCheckIn: false,
        checkInIntervalMinutes: 30,
      );
      
      expect(settingsWithNulls.emergencyContactName, null);
      expect(settingsWithNulls.emergencyContactPhone, null);
      expect(settingsWithNulls.shareLocationWithEmergencyContact, false);
    });
  });
}