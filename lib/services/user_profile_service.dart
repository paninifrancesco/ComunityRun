import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import 'firestore_service.dart';

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService(ref.read(firestoreServiceProvider));
});

class UserProfileService {
  final FirestoreService _firestoreService;

  UserProfileService(this._firestoreService);

  Future<void> createUserProfile(UserProfile profile) async {
    try {
      await _firestoreService.createUserProfile(profile);
    } catch (e) {
      throw UserProfileServiceException('Failed to create user profile: ${e.toString()}');
    }
  }

  Stream<UserProfile?> getUserProfile(String userId) {
    try {
      return _firestoreService.getUserProfile(userId);
    } catch (e) {
      throw UserProfileServiceException('Failed to get user profile: ${e.toString()}');
    }
  }

  Future<UserProfile?> getUserProfileOnce(String userId) async {
    try {
      return await _firestoreService.getUserProfileOnce(userId);
    } catch (e) {
      throw UserProfileServiceException('Failed to get user profile: ${e.toString()}');
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _firestoreService.updateUserProfile(profile);
    } catch (e) {
      throw UserProfileServiceException('Failed to update user profile: ${e.toString()}');
    }
  }

  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      // Import firebase_auth to get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return await getUserProfileOnce(user.uid);
    } catch (e) {
      throw UserProfileServiceException('Failed to get current user profile: ${e.toString()}');
    }
  }

  Future<void> deleteUserProfile(String userId) async {
    try {
      await _firestoreService.deleteUserProfile(userId);
    } catch (e) {
      throw UserProfileServiceException('Failed to delete user profile: ${e.toString()}');
    }
  }

  Future<void> updateDisplayName(String userId, String displayName) async {
    try {
      final profile = await getUserProfileOnce(userId);
      if (profile == null) {
        throw UserProfileServiceException('User profile not found');
      }
      
      final updatedProfile = profile.copyWith(
        displayName: displayName,
        lastActive: DateTime.now(),
      );
      
      await updateUserProfile(updatedProfile);
    } catch (e) {
      throw UserProfileServiceException('Failed to update display name: ${e.toString()}');
    }
  }

  Future<void> updateBio(String userId, String bio) async {
    try {
      final profile = await getUserProfileOnce(userId);
      if (profile == null) {
        throw UserProfileServiceException('User profile not found');
      }
      
      final updatedProfile = profile.copyWith(
        bio: bio,
        lastActive: DateTime.now(),
      );
      
      await updateUserProfile(updatedProfile);
    } catch (e) {
      throw UserProfileServiceException('Failed to update bio: ${e.toString()}');
    }
  }

  Future<void> updatePhotoUrl(String userId, String photoUrl) async {
    try {
      final profile = await getUserProfileOnce(userId);
      if (profile == null) {
        throw UserProfileServiceException('User profile not found');
      }
      
      final updatedProfile = profile.copyWith(
        photoUrl: photoUrl,
        lastActive: DateTime.now(),
      );
      
      await updateUserProfile(updatedProfile);
    } catch (e) {
      throw UserProfileServiceException('Failed to update photo: ${e.toString()}');
    }
  }

  Future<void> updateRunningPreferences(String userId, RunningPreferences preferences) async {
    try {
      final profile = await getUserProfileOnce(userId);
      if (profile == null) {
        throw UserProfileServiceException('User profile not found');
      }
      
      final updatedProfile = profile.copyWith(
        runningPreferences: preferences,
        lastActive: DateTime.now(),
      );
      
      await updateUserProfile(updatedProfile);
    } catch (e) {
      throw UserProfileServiceException('Failed to update running preferences: ${e.toString()}');
    }
  }

  Future<void> updateNotificationSettings(String userId, NotificationSettings settings) async {
    try {
      final profile = await getUserProfileOnce(userId);
      if (profile == null) {
        throw UserProfileServiceException('User profile not found');
      }
      
      final updatedProfile = profile.copyWith(
        notificationSettings: settings,
        lastActive: DateTime.now(),
      );
      
      await updateUserProfile(updatedProfile);
    } catch (e) {
      throw UserProfileServiceException('Failed to update notification settings: ${e.toString()}');
    }
  }

  Future<void> updatePrivacySettings(String userId, PrivacySettings settings) async {
    try {
      final profile = await getUserProfileOnce(userId);
      if (profile == null) {
        throw UserProfileServiceException('User profile not found');
      }
      
      final updatedProfile = profile.copyWith(
        privacySettings: settings,
        lastActive: DateTime.now(),
      );
      
      await updateUserProfile(updatedProfile);
    } catch (e) {
      throw UserProfileServiceException('Failed to update privacy settings: ${e.toString()}');
    }
  }

  Future<void> updateSafetySettings(String userId, SafetySettings settings) async {
    try {
      final profile = await getUserProfileOnce(userId);
      if (profile == null) {
        throw UserProfileServiceException('User profile not found');
      }
      
      final updatedProfile = profile.copyWith(
        safetySettings: settings,
        lastActive: DateTime.now(),
      );
      
      await updateUserProfile(updatedProfile);
    } catch (e) {
      throw UserProfileServiceException('Failed to update safety settings: ${e.toString()}');
    }
  }

  Future<void> incrementRunStats(String userId, {double distance = 0.0}) async {
    try {
      final profile = await getUserProfileOnce(userId);
      if (profile == null) {
        throw UserProfileServiceException('User profile not found');
      }
      
      final updatedProfile = profile.copyWith(
        totalRuns: profile.totalRuns + 1,
        totalDistance: profile.totalDistance + distance,
        lastActive: DateTime.now(),
      );
      
      await updateUserProfile(updatedProfile);
    } catch (e) {
      throw UserProfileServiceException('Failed to update run stats: ${e.toString()}');
    }
  }

  Future<void> blockUser(String currentUserId, String userToBlockId) async {
    try {
      await _firestoreService.blockUser(currentUserId, userToBlockId);
    } catch (e) {
      throw UserProfileServiceException('Failed to block user: ${e.toString()}');
    }
  }

  Future<void> reportUser(String currentUserId, String userToReportId, String reason) async {
    try {
      await _firestoreService.reportUser(currentUserId, userToReportId, reason);
    } catch (e) {
      throw UserProfileServiceException('Failed to report user: ${e.toString()}');
    }
  }

  Future<List<UserProfile>> searchUsers({
    String? displayName,
    int limit = 20,
  }) async {
    try {
      return await _firestoreService.searchUsers(
        displayName: displayName,
        limit: limit,
      );
    } catch (e) {
      throw UserProfileServiceException('Failed to search users: ${e.toString()}');
    }
  }

  Future<void> updateLastActive(String userId) async {
    try {
      final profile = await getUserProfileOnce(userId);
      if (profile == null) {
        throw UserProfileServiceException('User profile not found');
      }
      
      final updatedProfile = profile.copyWith(
        lastActive: DateTime.now(),
      );
      
      await updateUserProfile(updatedProfile);
    } catch (e) {
      throw UserProfileServiceException('Failed to update last active: ${e.toString()}');
    }
  }

  Future<bool> isUserBlocked(String currentUserId, String otherUserId) async {
    try {
      final profile = await getUserProfileOnce(currentUserId);
      return profile?.blockedUsers.contains(otherUserId) ?? false;
    } catch (e) {
      throw UserProfileServiceException('Failed to check if user is blocked: ${e.toString()}');
    }
  }

  Future<bool> hasUserReported(String currentUserId, String otherUserId) async {
    try {
      final profile = await getUserProfileOnce(currentUserId);
      return profile?.reportedUsers.contains(otherUserId) ?? false;
    } catch (e) {
      throw UserProfileServiceException('Failed to check if user was reported: ${e.toString()}');
    }
  }

  Future<List<UserProfile>> getMultipleProfiles(List<String> userIds) async {
    try {
      List<UserProfile> profiles = [];
      for (String userId in userIds) {
        final profile = await getUserProfileOnce(userId);
        if (profile != null) {
          profiles.add(profile);
        }
      }
      return profiles;
    } catch (e) {
      throw UserProfileServiceException('Failed to get multiple profiles: ${e.toString()}');
    }
  }
}

class UserProfileServiceException implements Exception {
  final String message;

  UserProfileServiceException(this.message);

  @override
  String toString() => message;
}