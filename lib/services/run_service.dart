import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import '../models/run.dart';
import 'firestore_service.dart';

final runServiceProvider = Provider<RunService>((ref) {
  return RunService(ref.read(firestoreServiceProvider));
});

class RunService {
  final FirestoreService _firestoreService;
  final GeoFlutterFire _geo = GeoFlutterFire();

  RunService(this._firestoreService);

  Future<String> createRun(Run run) async {
    try {
      return await _firestoreService.createRun(run);
    } catch (e) {
      throw RunServiceException('Failed to create run: ${e.toString()}');
    }
  }

  Stream<List<Run>> getNearbyRuns({
    required double latitude,
    required double longitude,
    required double radiusKm,
    int limit = 20,
  }) {
    try {
      return _firestoreService.getNearbyRuns(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        limit: limit,
      );
    } catch (e) {
      throw RunServiceException('Failed to get nearby runs: ${e.toString()}');
    }
  }

  Stream<List<Run>> getUserRuns(String userId) {
    try {
      return _firestoreService.getUserRuns(userId);
    } catch (e) {
      throw RunServiceException('Failed to get user runs: ${e.toString()}');
    }
  }

  Stream<List<Run>> getCreatedRuns(String userId) {
    try {
      return _firestoreService.getCreatedRuns(userId);
    } catch (e) {
      throw RunServiceException('Failed to get created runs: ${e.toString()}');
    }
  }

  Stream<Run?> getRun(String runId) {
    try {
      return _firestoreService.getRun(runId);
    } catch (e) {
      throw RunServiceException('Failed to get run: ${e.toString()}');
    }
  }

  Future<Run?> getRunOnce(String runId) async {
    try {
      return await _firestoreService.getRunOnce(runId);
    } catch (e) {
      throw RunServiceException('Failed to get run: ${e.toString()}');
    }
  }

  Future<void> joinRun(String runId, String userId) async {
    try {
      await _firestoreService.joinRun(runId, userId);
    } catch (e) {
      throw RunServiceException('Failed to join run: ${e.toString()}');
    }
  }

  Future<void> leaveRun(String runId, String userId) async {
    try {
      await _firestoreService.leaveRun(runId, userId);
    } catch (e) {
      throw RunServiceException('Failed to leave run: ${e.toString()}');
    }
  }

  Future<void> updateRun(Run run) async {
    try {
      await _firestoreService.updateRun(run);
    } catch (e) {
      throw RunServiceException('Failed to update run: ${e.toString()}');
    }
  }

  Future<void> deleteRun(String runId) async {
    try {
      await _firestoreService.deleteRun(runId);
    } catch (e) {
      throw RunServiceException('Failed to delete run: ${e.toString()}');
    }
  }

  Future<void> cancelRun(String runId, String creatorId) async {
    try {
      final run = await getRunOnce(runId);
      if (run == null) {
        throw RunServiceException('Run not found');
      }
      
      if (run.creatorId != creatorId) {
        throw RunServiceException('Only the creator can cancel the run');
      }

      final cancelledRun = run.copyWith(
        status: 'cancelled',
        updatedAt: DateTime.now(),
      );

      await updateRun(cancelledRun);
    } catch (e) {
      throw RunServiceException('Failed to cancel run: ${e.toString()}');
    }
  }

  Future<List<Run>> searchRuns({
    double? latitude,
    double? longitude,
    double? radiusKm,
    DateTime? startDate,
    DateTime? endDate,
    String? difficulty,
    List<String>? tags,
    int limit = 20,
  }) async {
    try {
      final collection = FirebaseFirestore.instance.collection('runs');
      Query query = collection;

      if (startDate != null) {
        query = query.where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      if (difficulty != null) {
        query = query.where('difficulty', isEqualTo: difficulty);
      }

      if (tags != null && tags.isNotEmpty) {
        query = query.where('tags', arrayContainsAny: tags);
      }

      query = query
          .where('status', isEqualTo: 'scheduled')
          .where('isPublic', isEqualTo: true)
          .limit(limit);

      final snapshot = await query.get();
      List<Run> runs = snapshot.docs
          .map((doc) => Run.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((run) => run.isUpcoming)
          .toList();

      if (latitude != null && longitude != null && radiusKm != null) {
        final center = _geo.point(latitude: latitude, longitude: longitude);
        runs = runs.where((run) {
          final distance = _geo.distance(
            lat1: center.latitude,
            lng1: center.longitude,
            lat2: run.startLocation.latitude,
            lng2: run.startLocation.longitude,
          );
          return distance <= radiusKm;
        }).toList();
      }

      runs.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return runs;
    } catch (e) {
      throw RunServiceException('Failed to search runs: ${e.toString()}');
    }
  }

  Future<bool> canUserJoinRun(String runId, String userId) async {
    try {
      final run = await getRunOnce(runId);
      if (run == null) return false;

      if (!run.isUpcoming) return false;
      if (!run.isPublic) return false;
      if (run.status != 'scheduled') return false;
      if (run.participants.contains(userId)) return false;
      if (run.creatorId == userId) return false;

      return !run.isFull || (run.allowWaitingList && !run.waitingList.contains(userId));
    } catch (e) {
      throw RunServiceException('Failed to check if user can join run: ${e.toString()}');
    }
  }

  Future<bool> isUserOnWaitingList(String runId, String userId) async {
    try {
      final run = await getRunOnce(runId);
      return run?.waitingList.contains(userId) ?? false;
    } catch (e) {
      throw RunServiceException('Failed to check waiting list status: ${e.toString()}');
    }
  }

  Future<List<String>> getRunParticipants(String runId) async {
    try {
      final run = await getRunOnce(runId);
      return run?.participants ?? [];
    } catch (e) {
      throw RunServiceException('Failed to get run participants: ${e.toString()}');
    }
  }

  Future<int> getAvailableSpots(String runId) async {
    try {
      final run = await getRunOnce(runId);
      return run?.availableSpots ?? 0;
    } catch (e) {
      throw RunServiceException('Failed to get available spots: ${e.toString()}');
    }
  }
}

class RunServiceException implements Exception {
  final String message;

  RunServiceException(this.message);

  @override
  String toString() => message;
}