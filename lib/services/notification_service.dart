import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user_profile.dart';
import 'user_profile_service.dart';
import 'firestore_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    userProfileService: ref.read(userProfileServiceProvider),
    firestoreService: ref.read(firestoreServiceProvider),
  );
});

class NotificationService {
  final UserProfileService _userProfileService;
  final FirestoreService _firestoreService;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  NotificationService({
    required UserProfileService userProfileService,
    required FirestoreService firestoreService,
  }) : _userProfileService = userProfileService,
       _firestoreService = firestoreService;

  Future<void> initialize() async {
    try {
      await _requestPermissions();
      await _configureForegroundNotifications();
      await _setupTokenRefreshListener();
      await _updateFCMToken();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing notifications: $e');
      }
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('iOS notification permission status: ${settings.authorizationStatus}');
      }
    } else if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (kDebugMode) {
        print('Android notification permission status: $status');
      }
    }
  }

  Future<void> _configureForegroundNotifications() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _setupTokenRefreshListener() async {
    _messaging.onTokenRefresh.listen((String token) async {
      if (kDebugMode) {
        print('FCM token refreshed: $token');
      }
      await _updateUserFCMToken(token);
    });
  }

  Future<void> _updateFCMToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _updateUserFCMToken(token);
        if (kDebugMode) {
          print('FCM token retrieved: $token');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
    }
  }

  Future<void> _updateUserFCMToken(String token) async {
    try {
      // Get current user ID from auth service or user profile
      // For now, we'll get it from the current user profile
      final currentUser = await _userProfileService.getCurrentUserProfile();
      if (currentUser != null) {
        final updatedProfile = currentUser.copyWith(
          fcmToken: token,
          lastTokenUpdate: DateTime.now(),
        );
        await _userProfileService.updateUserProfile(updatedProfile);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating FCM token: $e');
      }
    }
  }

  Future<void> sendRunNotification({
    required String runId,
    required String title,
    required String body,
    required NotificationType type,
    required List<String> recipientUserIds,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notificationData = {
        'type': type.toString().split('.').last,
        'runId': runId,
        'title': title,
        'body': body,
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      };

      // Store notification in Firestore for persistence
      await _firestoreService.addDocument('notifications', notificationData);

      // Send FCM notifications to specific users
      await _sendToSpecificUsers(
        userIds: recipientUserIds,
        title: title,
        body: body,
        data: notificationData,
      );

      if (kDebugMode) {
        print('Notification sent successfully: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification: $e');
      }
      rethrow;
    }
  }

  Future<void> _sendToSpecificUsers({
    required List<String> userIds,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Get FCM tokens for the specified users
      final tokens = <String>[];
      
      for (final userId in userIds) {
        final userProfile = await _userProfileService.getUserProfileOnce(userId);
        if (userProfile?.fcmToken != null) {
          tokens.add(userProfile!.fcmToken!);
        }
      }

      if (tokens.isEmpty) {
        if (kDebugMode) {
          print('No valid FCM tokens found for users: $userIds');
        }
        return;
      }

      // For now, we'll store the notification request
      // In a real implementation, you would use Firebase Cloud Functions
      // to send FCM messages from the server side
      final notificationRequest = {
        'tokens': tokens,
        'title': title,
        'body': body,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending',
      };

      await _firestoreService.addDocument('notificationRequests', notificationRequest);

      if (kDebugMode) {
        print('Notification request stored for ${tokens.length} tokens');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification to users: $e');
      }
      rethrow;
    }
  }

  Future<void> sendNewParticipantNotification({
    required String runId,
    required String runTitle,
    required String participantName,
    required String creatorUserId,
  }) async {
    await sendRunNotification(
      runId: runId,
      title: 'New Participant Joined',
      body: '$participantName joined your run "$runTitle"',
      type: NotificationType.newParticipant,
      recipientUserIds: [creatorUserId],
      data: {
        'participantName': participantName,
      },
    );
  }

  Future<void> sendParticipantLeftNotification({
    required String runId,
    required String runTitle,
    required String participantName,
    required String creatorUserId,
  }) async {
    await sendRunNotification(
      runId: runId,
      title: 'Participant Left',
      body: '$participantName left your run "$runTitle"',
      type: NotificationType.participantLeft,
      recipientUserIds: [creatorUserId],
      data: {
        'participantName': participantName,
      },
    );
  }

  Future<void> sendRunUpdatedNotification({
    required String runId,
    required String runTitle,
    required List<String> participantUserIds,
    required String updateSummary,
  }) async {
    await sendRunNotification(
      runId: runId,
      title: 'Run Updated',
      body: 'The run "$runTitle" has been updated: $updateSummary',
      type: NotificationType.runUpdated,
      recipientUserIds: participantUserIds,
      data: {
        'updateSummary': updateSummary,
      },
    );
  }

  Future<void> sendRunCancelledNotification({
    required String runId,
    required String runTitle,
    required List<String> participantUserIds,
    String? reason,
  }) async {
    final body = reason != null
        ? 'The run "$runTitle" has been cancelled: $reason'
        : 'The run "$runTitle" has been cancelled';

    await sendRunNotification(
      runId: runId,
      title: 'Run Cancelled',
      body: body,
      type: NotificationType.runCancelled,
      recipientUserIds: participantUserIds,
      data: {
        'reason': reason,
      },
    );
  }

  Future<void> sendRunReminderNotification({
    required String runId,
    required String runTitle,
    required List<String> participantUserIds,
    required int minutesUntilRun,
  }) async {
    final body = minutesUntilRun > 60
        ? 'Your run "$runTitle" starts in ${(minutesUntilRun / 60).ceil()} hour(s)'
        : 'Your run "$runTitle" starts in $minutesUntilRun minutes';

    await sendRunNotification(
      runId: runId,
      title: 'Run Reminder',
      body: body,
      type: NotificationType.runReminder,
      recipientUserIds: participantUserIds,
      data: {
        'minutesUntilRun': minutesUntilRun,
      },
    );
  }

  Future<void> sendNewMessageNotification({
    required String runId,
    required String runTitle,
    required String senderName,
    required String messagePreview,
    required List<String> participantUserIds,
    required String senderUserId,
  }) async {
    // Don't send notification to the sender
    final recipients = participantUserIds.where((id) => id != senderUserId).toList();

    if (recipients.isEmpty) return;

    await sendRunNotification(
      runId: runId,
      title: 'New Message in $runTitle',
      body: '$senderName: $messagePreview',
      type: NotificationType.newMessage,
      recipientUserIds: recipients,
      data: {
        'senderName': senderName,
        'messagePreview': messagePreview,
      },
    );
  }

  Future<void> sendWaitlistPromotedNotification({
    required String runId,
    required String runTitle,
    required String userId,
  }) async {
    await sendRunNotification(
      runId: runId,
      title: 'Spot Available!',
      body: 'A spot opened up in "$runTitle" and you\'ve been promoted from the waitlist',
      type: NotificationType.waitlistPromoted,
      recipientUserIds: [userId],
    );
  }

  void setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Received foreground message: ${message.notification?.title}');
      }
      _handleMessage(message);
    });

    // Handle messages when app is opened from notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('App opened from notification: ${message.notification?.title}');
      }
      _handleMessage(message);
    });

    // Handle messages when app is launched from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print('App launched from notification: ${message.notification?.title}');
        }
        _handleMessage(message);
      }
    });
  }

  void _handleMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    
    if (kDebugMode) {
      print('Handling message of type: $type');
      print('Message data: $data');
    }

    // Handle different notification types
    switch (type) {
      case 'newParticipant':
      case 'participantLeft':
      case 'runUpdated':
      case 'runCancelled':
      case 'runReminder':
      case 'newMessage':
      case 'waitlistPromoted':
        // Navigation logic would go here
        // For now, we'll just log the message
        if (kDebugMode) {
          print('Would navigate to run: ${data['runId']}');
        }
        break;
      default:
        if (kDebugMode) {
          print('Unknown notification type: $type');
        }
    }
  }

  Future<void> clearUserToken() async {
    try {
      await _messaging.deleteToken();
      if (kDebugMode) {
        print('FCM token cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing FCM token: $e');
      }
    }
  }

  Future<bool> hasNotificationPermission() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  Future<void> openNotificationSettings() async {
    await _messaging.requestPermission();
  }

  Future<void> sendEmergencyAlert({
    required String runId,
    required String alertMessage,
    required String alertingUserId,
    required Map<String, double> location,
  }) async {
    try {
      // Get run participants
      final runDoc = await _firestoreService.getDocument('runs', runId);
      if (runDoc == null) return;

      final participants = List<String>.from(runDoc['participants'] ?? []);
      
      // Remove the alerting user from the notification list
      participants.remove(alertingUserId);

      // Send notifications to all other participants
      for (final participantId in participants) {
        final userProfile = await _userProfileService.getUserProfile(participantId).first;
        
        if (userProfile?.fcmToken != null && 
            userProfile!.notificationSettings.safetyAlerts) {
          
          final notification = {
            'title': '🚨 Emergency Alert',
            'body': alertMessage,
            'data': {
              'type': 'emergency_alert',
              'runId': runId,
              'alertingUserId': alertingUserId,
              'latitude': location['latitude'].toString(),
              'longitude': location['longitude'].toString(),
            },
          };

          await _sendNotificationToToken(userProfile.fcmToken!, notification);
        }
      }
      
      if (kDebugMode) {
        print('Emergency alert sent to ${participants.length} participants');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending emergency alert: $e');
      }
    }
  }

  // Send notification to specific FCM token
  Future<void> _sendNotificationToToken(String token, Map<String, dynamic> notification) async {
    try {
      // Note: This is a placeholder for actual FCM server implementation
      // In a real app, you would need a backend service to send notifications
      // using Firebase Admin SDK or FCM HTTP API
      if (kDebugMode) {
        print('Sending notification to token: $token');
        print('Notification: $notification');
      }
      
      // For now, just log the notification
      // In production, implement actual notification sending
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification to token: $e');
      }
    }
  }
}

enum NotificationType {
  newParticipant,
  participantLeft,
  runUpdated,
  runCancelled,
  runReminder,
  newMessage,
  waitlistPromoted,
}

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Handling background message: ${message.notification?.title}');
  }
  // Handle background message
}