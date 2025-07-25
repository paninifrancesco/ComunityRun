import 'package:flutter_test/flutter_test.dart';
import 'package:communityrun/models/user_profile.dart';
import 'package:communityrun/models/message.dart';

void main() {
  group('Data Models Tests', () {
    test('UserProfile creation and serialization', () {
      final profile = UserProfile(
        uid: 'test-uid',
        displayName: 'Test Runner',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        runningPreferences: const RunningPreferences(),
        notificationSettings: const NotificationSettings(),
        privacySettings: const PrivacySettings(),
        safetySettings: const SafetySettings(),
      );

      final map = profile.toMap();
      expect(map['uid'], 'test-uid');
      expect(map['displayName'], 'Test Runner');
      expect(map['totalRuns'], 0);
      expect(map['totalDistance'], 0.0);
    });

    test('Message creation and types', () {
      final message = Message(
        id: 'msg-1',
        senderId: 'user-1',
        senderName: 'Runner',
        runId: 'run-1',
        content: 'Hello everyone!',
        timestamp: DateTime.now(),
      );

      expect(message.type, MessageType.text);
      expect(message.isSystemMessage, false);
      expect(message.hasImages, false);
      expect(message.hasLocation, false);
    });
  });
}
