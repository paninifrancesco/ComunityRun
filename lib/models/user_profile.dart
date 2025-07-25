import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime lastActive;
  
  final RunningPreferences runningPreferences;
  final NotificationSettings notificationSettings;
  final PrivacySettings privacySettings;
  final SafetySettings safetySettings;
  
  final String? stravaUserId;
  final Map<String, dynamic>? stravaProfile;
  
  final int totalRuns;
  final double totalDistance;
  final List<String> blockedUsers;
  final List<String> reportedUsers;

  const UserProfile({
    required this.uid,
    required this.displayName,
    this.email,
    this.photoUrl,
    this.bio,
    required this.createdAt,
    required this.lastActive,
    required this.runningPreferences,
    required this.notificationSettings,
    required this.privacySettings,
    required this.safetySettings,
    this.stravaUserId,
    this.stravaProfile,
    this.totalRuns = 0,
    this.totalDistance = 0.0,
    this.blockedUsers = const [],
    this.reportedUsers = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'runningPreferences': runningPreferences.toMap(),
      'notificationSettings': notificationSettings.toMap(),
      'privacySettings': privacySettings.toMap(),
      'safetySettings': safetySettings.toMap(),
      'stravaUserId': stravaUserId,
      'stravaProfile': stravaProfile,
      'totalRuns': totalRuns,
      'totalDistance': totalDistance,
      'blockedUsers': blockedUsers,
      'reportedUsers': reportedUsers,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? '',
      email: map['email'],
      photoUrl: map['photoUrl'],
      bio: map['bio'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastActive: (map['lastActive'] as Timestamp).toDate(),
      runningPreferences: RunningPreferences.fromMap(map['runningPreferences'] ?? {}),
      notificationSettings: NotificationSettings.fromMap(map['notificationSettings'] ?? {}),
      privacySettings: PrivacySettings.fromMap(map['privacySettings'] ?? {}),
      safetySettings: SafetySettings.fromMap(map['safetySettings'] ?? {}),
      stravaUserId: map['stravaUserId'],
      stravaProfile: map['stravaProfile'],
      totalRuns: map['totalRuns'] ?? 0,
      totalDistance: map['totalDistance']?.toDouble() ?? 0.0,
      blockedUsers: List<String>.from(map['blockedUsers'] ?? []),
      reportedUsers: List<String>.from(map['reportedUsers'] ?? []),
    );
  }

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    String? bio,
    DateTime? lastActive,
    RunningPreferences? runningPreferences,
    NotificationSettings? notificationSettings,
    PrivacySettings? privacySettings,
    SafetySettings? safetySettings,
    String? stravaUserId,
    Map<String, dynamic>? stravaProfile,
    int? totalRuns,
    double? totalDistance,
    List<String>? blockedUsers,
    List<String>? reportedUsers,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt,
      lastActive: lastActive ?? this.lastActive,
      runningPreferences: runningPreferences ?? this.runningPreferences,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      privacySettings: privacySettings ?? this.privacySettings,
      safetySettings: safetySettings ?? this.safetySettings,
      stravaUserId: stravaUserId ?? this.stravaUserId,
      stravaProfile: stravaProfile ?? this.stravaProfile,
      totalRuns: totalRuns ?? this.totalRuns,
      totalDistance: totalDistance ?? this.totalDistance,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      reportedUsers: reportedUsers ?? this.reportedUsers,
    );
  }
}

class RunningPreferences {
  final List<String> preferredPaces;
  final List<String> preferredDistances;
  final List<String> preferredTimes;
  final List<String> runningGoals;
  final int maxGroupSize;
  final bool openToNewRunners;

  const RunningPreferences({
    this.preferredPaces = const [],
    this.preferredDistances = const [],
    this.preferredTimes = const [],
    this.runningGoals = const [],
    this.maxGroupSize = 10,
    this.openToNewRunners = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'preferredPaces': preferredPaces,
      'preferredDistances': preferredDistances,
      'preferredTimes': preferredTimes,
      'runningGoals': runningGoals,
      'maxGroupSize': maxGroupSize,
      'openToNewRunners': openToNewRunners,
    };
  }

  factory RunningPreferences.fromMap(Map<String, dynamic> map) {
    return RunningPreferences(
      preferredPaces: List<String>.from(map['preferredPaces'] ?? []),
      preferredDistances: List<String>.from(map['preferredDistances'] ?? []),
      preferredTimes: List<String>.from(map['preferredTimes'] ?? []),
      runningGoals: List<String>.from(map['runningGoals'] ?? []),
      maxGroupSize: map['maxGroupSize'] ?? 10,
      openToNewRunners: map['openToNewRunners'] ?? true,
    );
  }
}

class NotificationSettings {
  final bool newRunInArea;
  final bool runUpdates;
  final bool messages;
  final bool safetyAlerts;
  final bool weeklyDigest;
  final int quietHoursStart;
  final int quietHoursEnd;

  const NotificationSettings({
    this.newRunInArea = true,
    this.runUpdates = true,
    this.messages = true,
    this.safetyAlerts = true,
    this.weeklyDigest = false,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 7,
  });

  Map<String, dynamic> toMap() {
    return {
      'newRunInArea': newRunInArea,
      'runUpdates': runUpdates,
      'messages': messages,
      'safetyAlerts': safetyAlerts,
      'weeklyDigest': weeklyDigest,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
    };
  }

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      newRunInArea: map['newRunInArea'] ?? true,
      runUpdates: map['runUpdates'] ?? true,
      messages: map['messages'] ?? true,
      safetyAlerts: map['safetyAlerts'] ?? true,
      weeklyDigest: map['weeklyDigest'] ?? false,
      quietHoursStart: map['quietHoursStart'] ?? 22,
      quietHoursEnd: map['quietHoursEnd'] ?? 7,
    );
  }
}

class PrivacySettings {
  final bool showRealName;
  final bool showExactLocation;
  final bool allowDirectMessages;
  final bool shareWithStrava;
  final String profileVisibility;

  const PrivacySettings({
    this.showRealName = false,
    this.showExactLocation = false,
    this.allowDirectMessages = true,
    this.shareWithStrava = false,
    this.profileVisibility = 'public',
  });

  Map<String, dynamic> toMap() {
    return {
      'showRealName': showRealName,
      'showExactLocation': showExactLocation,
      'allowDirectMessages': allowDirectMessages,
      'shareWithStrava': shareWithStrava,
      'profileVisibility': profileVisibility,
    };
  }

  factory PrivacySettings.fromMap(Map<String, dynamic> map) {
    return PrivacySettings(
      showRealName: map['showRealName'] ?? false,
      showExactLocation: map['showExactLocation'] ?? false,
      allowDirectMessages: map['allowDirectMessages'] ?? true,
      shareWithStrava: map['shareWithStrava'] ?? false,
      profileVisibility: map['profileVisibility'] ?? 'public',
    );
  }
}

class SafetySettings {
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final bool shareLocationWithEmergencyContact;
  final bool autoCheckIn;
  final int checkInIntervalMinutes;

  const SafetySettings({
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.shareLocationWithEmergencyContact = false,
    this.autoCheckIn = false,
    this.checkInIntervalMinutes = 30,
  });

  Map<String, dynamic> toMap() {
    return {
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'shareLocationWithEmergencyContact': shareLocationWithEmergencyContact,
      'autoCheckIn': autoCheckIn,
      'checkInIntervalMinutes': checkInIntervalMinutes,
    };
  }

  factory SafetySettings.fromMap(Map<String, dynamic> map) {
    return SafetySettings(
      emergencyContactName: map['emergencyContactName'],
      emergencyContactPhone: map['emergencyContactPhone'],
      shareLocationWithEmergencyContact: map['shareLocationWithEmergencyContact'] ?? false,
      autoCheckIn: map['autoCheckIn'] ?? false,
      checkInIntervalMinutes: map['checkInIntervalMinutes'] ?? 30,
    );
  }
}