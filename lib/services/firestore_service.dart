import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import '../models/user_profile.dart';
import '../models/run.dart';
import '../models/message.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeoFlutterFire _geo = GeoFlutterFire();

  CollectionReference get _users => _firestore.collection('userProfiles');
  CollectionReference get _runs => _firestore.collection('runs');
  CollectionReference get _messages => _firestore.collection('messages');
  CollectionReference get _chats => _firestore.collection('chats');

  Future<void> createUserProfile(UserProfile profile) async {
    try {
      await _users.doc(profile.uid).set(profile.toMap());
    } catch (e) {
      throw FirestoreException('Failed to create user profile: ${e.toString()}');
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _users.doc(profile.uid).update(profile.toMap());
    } catch (e) {
      throw FirestoreException('Failed to update user profile: ${e.toString()}');
    }
  }

  Stream<UserProfile?> getUserProfile(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  Future<UserProfile?> getUserProfileOnce(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw FirestoreException('Failed to get user profile: ${e.toString()}');
    }
  }

  Future<void> deleteUserProfile(String uid) async {
    try {
      await _users.doc(uid).delete();
    } catch (e) {
      throw FirestoreException('Failed to delete user profile: ${e.toString()}');
    }
  }

  Future<String> createRun(Run run) async {
    try {
      final docRef = await _runs.add(run.toMap());
      return docRef.id;
    } catch (e) {
      throw FirestoreException('Failed to create run: ${e.toString()}');
    }
  }

  Future<void> updateRun(Run run) async {
    try {
      await _runs.doc(run.id).update(run.toMap());
    } catch (e) {
      throw FirestoreException('Failed to update run: ${e.toString()}');
    }
  }

  Future<void> deleteRun(String runId) async {
    try {
      await _runs.doc(runId).delete();
    } catch (e) {
      throw FirestoreException('Failed to delete run: ${e.toString()}');
    }
  }

  Stream<Run?> getRun(String runId) {
    return _runs.doc(runId).snapshots().map((doc) {
      if (doc.exists) {
        return Run.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  Future<Run?> getRunOnce(String runId) async {
    try {
      final doc = await _runs.doc(runId).get();
      if (doc.exists) {
        return Run.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw FirestoreException('Failed to get run: ${e.toString()}');
    }
  }

  Stream<List<Run>> getNearbyRuns({
    required double latitude,
    required double longitude,
    required double radiusKm,
    int limit = 20,
  }) {
    final center = _geo.point(latitude: latitude, longitude: longitude);
    
    return _geo
        .collection(collectionRef: _runs)
        .within(
          center: center,
          radius: radiusKm,
          field: 'startLocation',
        )
        .map((docs) => docs
            .map((doc) => Run.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .where((run) => run.isUpcoming)
            .take(limit)
            .toList());
  }

  Stream<List<Run>> getUserRuns(String userId) {
    return _runs
        .where('participants', arrayContains: userId)
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Run.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<Run>> getCreatedRuns(String userId) {
    return _runs
        .where('creatorId', isEqualTo: userId)
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Run.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> joinRun(String runId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final runDoc = await transaction.get(_runs.doc(runId));
        
        if (!runDoc.exists) {
          throw FirestoreException('Run not found');
        }

        final run = Run.fromMap(runDoc.data() as Map<String, dynamic>, runDoc.id);
        
        if (run.participants.contains(userId)) {
          throw FirestoreException('Already joined this run');
        }

        List<String> updatedParticipants = List.from(run.participants);
        List<String> updatedWaitingList = List.from(run.waitingList);

        if (run.isFull) {
          if (run.allowWaitingList && !updatedWaitingList.contains(userId)) {
            updatedWaitingList.add(userId);
          } else {
            throw FirestoreException('Run is full and waiting list is not allowed');
          }
        } else {
          updatedParticipants.add(userId);
          updatedWaitingList.remove(userId);
        }

        transaction.update(_runs.doc(runId), {
          'participants': updatedParticipants,
          'waitingList': updatedWaitingList,
          'updatedAt': Timestamp.now(),
        });
      });
    } catch (e) {
      throw FirestoreException('Failed to join run: ${e.toString()}');
    }
  }

  Future<void> leaveRun(String runId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final runDoc = await transaction.get(_runs.doc(runId));
        
        if (!runDoc.exists) {
          throw FirestoreException('Run not found');
        }

        final run = Run.fromMap(runDoc.data() as Map<String, dynamic>, runDoc.id);
        
        List<String> updatedParticipants = List.from(run.participants);
        List<String> updatedWaitingList = List.from(run.waitingList);

        updatedParticipants.remove(userId);
        updatedWaitingList.remove(userId);

        if (updatedWaitingList.isNotEmpty && updatedParticipants.length < run.maxParticipants) {
          final nextUser = updatedWaitingList.removeAt(0);
          updatedParticipants.add(nextUser);
        }

        transaction.update(_runs.doc(runId), {
          'participants': updatedParticipants,
          'waitingList': updatedWaitingList,
          'updatedAt': Timestamp.now(),
        });
      });
    } catch (e) {
      throw FirestoreException('Failed to leave run: ${e.toString()}');
    }
  }

  Future<String> sendMessage(Message message) async {
    try {
      final docRef = await _messages.add(message.toMap());
      
      await _updateChatMetadata(message.runId, message);
      
      return docRef.id;
    } catch (e) {
      throw FirestoreException('Failed to send message: ${e.toString()}');
    }
  }

  Stream<List<Message>> getRunMessages(String runId, {int limit = 50}) {
    return _messages
        .where('runId', isEqualTo: runId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList()
            .reversed
            .toList());
  }

  Future<void> markMessageAsRead(String messageId, String userId) async {
    try {
      await _messages.doc(messageId).update({
        'readBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw FirestoreException('Failed to mark message as read: ${e.toString()}');
    }
  }

  Future<void> _updateChatMetadata(String runId, Message message) async {
    try {
      await _chats.doc(runId).set({
        'runId': runId,
        'lastMessageAt': message.timestamp,
        'lastMessage': message.content,
        'lastMessageSender': message.senderName,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw FirestoreException('Failed to update chat metadata: ${e.toString()}');
    }
  }

  Stream<List<ChatMetadata>> getUserChats(String userId) {
    return _runs
        .where('participants', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<ChatMetadata> chats = [];
      
      for (var doc in snapshot.docs) {
        final chatDoc = await _chats.doc(doc.id).get();
        if (chatDoc.exists) {
          chats.add(ChatMetadata.fromMap(chatDoc.data() as Map<String, dynamic>));
        }
      }
      
      chats.sort((a, b) => (b.lastMessageAt ?? b.createdAt)
          .compareTo(a.lastMessageAt ?? a.createdAt));
      
      return chats;
    });
  }

  Future<List<UserProfile>> searchUsers({
    String? displayName,
    int limit = 20,
  }) async {
    try {
      Query query = _users.limit(limit);
      
      if (displayName != null && displayName.isNotEmpty) {
        query = query
            .where('displayName', isGreaterThanOrEqualTo: displayName)
            .where('displayName', isLessThan: '${displayName}z');
      }
      
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw FirestoreException('Failed to search users: ${e.toString()}');
    }
  }

  Future<void> blockUser(String currentUserId, String userToBlockId) async {
    try {
      await _users.doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayUnion([userToBlockId]),
      });
    } catch (e) {
      throw FirestoreException('Failed to block user: ${e.toString()}');
    }
  }

  Future<void> reportUser(String currentUserId, String userToReportId, String reason) async {
    try {
      await _firestore.collection('reports').add({
        'reporterId': currentUserId,
        'reportedUserId': userToReportId,
        'reason': reason,
        'timestamp': Timestamp.now(),
        'status': 'pending',
      });

      await _users.doc(currentUserId).update({
        'reportedUsers': FieldValue.arrayUnion([userToReportId]),
      });
    } catch (e) {
      throw FirestoreException('Failed to report user: ${e.toString()}');
    }
  }
}

class FirestoreException implements Exception {
  final String message;

  FirestoreException(this.message);

  @override
  String toString() => message;
}