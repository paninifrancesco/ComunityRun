import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import 'user_profile_service.dart';
import 'firestore_service.dart';

enum ReportType {
  inappropriateBehavior,
  noShow,
  harassment,
  unsafeLocation,
  spam,
  fakeProfile,
  other,
}

class Report {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String? runId;
  final ReportType type;
  final String description;
  final DateTime timestamp;
  final String status; // pending, reviewed, resolved

  const Report({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    this.runId,
    required this.type,
    required this.description,
    required this.timestamp,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'runId': runId,
      'type': type.name,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] ?? '',
      reporterId: map['reporterId'] ?? '',
      reportedUserId: map['reportedUserId'] ?? '',
      runId: map['runId'],
      type: ReportType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ReportType.other,
      ),
      description: map['description'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
    );
  }
}

final safetyServiceProvider = Provider<SafetyService>((ref) {
  return SafetyService(ref.read(userProfileServiceProvider));
});

class SafetyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserProfileService _userProfileService;

  SafetyService(this._userProfileService);

  Future<bool> reportUser({
    required String reporterId,
    required String reportedUserId,
    String? runId,
    required ReportType type,
    required String description,
  }) async {
    try {
      // Prevent self-reporting
      if (reporterId == reportedUserId) {
        throw Exception('Cannot report yourself');
      }

      // Check if already reported (within last 30 days)
      final existingReports = await _firestore
          .collection('reports')
          .where('reporterId', isEqualTo: reporterId)
          .where('reportedUserId', isEqualTo: reportedUserId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 30))
          ))
          .get();

      if (existingReports.docs.isNotEmpty) {
        throw Exception('You have already reported this user recently');
      }

      final reportId = _firestore.collection('reports').doc().id;
      final report = Report(
        id: reportId,
        reporterId: reporterId,
        reportedUserId: reportedUserId,
        runId: runId,
        type: type,
        description: description,
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection('reports')
          .doc(reportId)
          .set(report.toMap());

      // Update reporter's profile to track reported users
      await _updateUserReportedList(reporterId, reportedUserId);

      return true;
    } catch (e) {
      print('Report user error: $e');
      return false;
    }
  }

  Future<bool> blockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    try {
      // Prevent self-blocking
      if (blockerId == blockedUserId) {
        throw Exception('Cannot block yourself');
      }

      // Add to blocker's blocked list
      final blockerProfile = await _userProfileService.getUserProfileOnce(blockerId);
      if (blockerProfile != null) {
        final updatedBlockedUsers = List<String>.from(blockerProfile.blockedUsers)..add(blockedUserId);
        final updatedProfile = blockerProfile.copyWith(blockedUsers: updatedBlockedUsers);
        await _userProfileService.updateUserProfile(updatedProfile);
      }

      // Create a blocking record for tracking
      await _firestore.collection('blocks').add({
        'blockerId': blockerId,
        'blockedUserId': blockedUserId,
        'timestamp': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Block user error: $e');
      return false;
    }
  }

  Future<bool> unblockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    try {
      // Remove from blocker's blocked list
      final blockerProfile = await _userProfileService.getUserProfileOnce(blockerId);
      if (blockerProfile != null) {
        final updatedBlockedUsers = List<String>.from(blockerProfile.blockedUsers)..remove(blockedUserId);
        final updatedProfile = blockerProfile.copyWith(blockedUsers: updatedBlockedUsers);
        await _userProfileService.updateUserProfile(updatedProfile);
      }

      // Remove blocking record
      final blockDoc = await _firestore
          .collection('blocks')
          .where('blockerId', isEqualTo: blockerId)
          .where('blockedUserId', isEqualTo: blockedUserId)
          .get();

      for (final doc in blockDoc.docs) {
        await doc.reference.delete();
      }

      return true;
    } catch (e) {
      print('Unblock user error: $e');
      return false;
    }
  }

  Future<List<String>> getBlockedUsers(String userId) async {
    try {
      final userProfile = await _userProfileService.getUserProfile(userId).first;
      return userProfile?.blockedUsers ?? [];
    } catch (e) {
      print('Get blocked users error: $e');
      return [];
    }
  }

  Future<bool> isUserBlocked(String userId, String targetUserId) async {
    try {
      final blockedUsers = await getBlockedUsers(userId);
      return blockedUsers.contains(targetUserId);
    } catch (e) {
      print('Check if user blocked error: $e');
      return false;
    }
  }

  Future<List<Report>> getUserReports(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reports')
          .where('reporterId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Report.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Get user reports error: $e');
      return [];
    }
  }

  Future<bool> canUserJoinRun(String userId, List<String> participantIds) async {
    try {
      final blockedUsers = await getBlockedUsers(userId);
      
      // Check if any participant has blocked this user
      for (final participantId in participantIds) {
        final participantBlockedUsers = await getBlockedUsers(participantId);
        if (participantBlockedUsers.contains(userId)) {
          return false;
        }
        
        // Check if this user has blocked any participant
        if (blockedUsers.contains(participantId)) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      print('Check can user join run error: $e');
      return true; // Default to allowing join if there's an error
    }
  }

  Future<List<String>> filterBlockedUsers(String userId, List<String> userIds) async {
    try {
      final blockedUsers = await getBlockedUsers(userId);
      
      // Filter out blocked users and users who have blocked the current user
      final filteredUsers = <String>[];
      
      for (final targetUserId in userIds) {
        if (!blockedUsers.contains(targetUserId)) {
          final targetBlockedUsers = await getBlockedUsers(targetUserId);
          if (!targetBlockedUsers.contains(userId)) {
            filteredUsers.add(targetUserId);
          }
        }
      }
      
      return filteredUsers;
    } catch (e) {
      print('Filter blocked users error: $e');
      return userIds; // Return original list if error
    }
  }

  Future<void> _updateUserReportedList(String reporterId, String reportedUserId) async {
    try {
      final reporterProfile = await _userProfileService.getUserProfileOnce(reporterId);
      if (reporterProfile != null) {
        final updatedReportedUsers = List<String>.from(reporterProfile.reportedUsers)..add(reportedUserId);
        final updatedProfile = reporterProfile.copyWith(reportedUsers: updatedReportedUsers);
        await _userProfileService.updateUserProfile(updatedProfile);
      }
    } catch (e) {
      print('Update user reported list error: $e');
    }
  }

  // Admin functions for reviewing reports
  Future<List<Report>> getAllPendingReports() async {
    try {
      final querySnapshot = await _firestore
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Report.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Get pending reports error: $e');
      return [];
    }
  }

  Future<bool> updateReportStatus(String reportId, String status) async {
    try {
      await _firestore
          .collection('reports')
          .doc(reportId)
          .update({'status': status});
      return true;
    } catch (e) {
      print('Update report status error: $e');
      return false;
    }
  }
}