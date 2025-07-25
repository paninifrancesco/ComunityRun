import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:communityrun/models/run.dart';

void main() {
  group('Run Model Tests', () {
    late GeoFlutterFire geo;
    late GeoFirePoint testLocation;
    late Run testRun;

    setUpAll(() {
      geo = GeoFlutterFire();
      testLocation = geo.point(latitude: 45.4642, longitude: 9.1900); // Milan coordinates
    });

    setUp(() {
      testRun = Run(
        id: 'test_run_id',
        creatorId: 'creator_123',
        title: 'Morning Jog in Milano',
        description: 'Easy 5K run through the city center',
        dateTime: DateTime(2024, 3, 15, 7, 0),
        startLocation: testLocation,
        startLocationName: 'Piazza Duomo, Milan',
        route: 'Central Milan loop',
        estimatedDistance: 5.0,
        estimatedPace: '5:30',
        estimatedDurationMinutes: 30,
        maxParticipants: 8,
        participants: ['creator_123', 'participant_456'],
        waitingList: [],
        difficulty: 'easy',
        tags: ['morning', 'city', 'easy'],
        isPublic: true,
        allowWaitingList: true,
        meetingInstructions: 'Meet by the cathedral steps',
        status: 'scheduled',
        createdAt: DateTime(2024, 3, 10, 10, 0),
        updatedAt: DateTime(2024, 3, 10, 10, 0),
        weather: {'temperature': 15, 'condition': 'sunny'},
        groupChatId: 'chat_123',
      );
    });

    test('should create Run with all properties', () {
      expect(testRun.id, 'test_run_id');
      expect(testRun.title, 'Morning Jog in Milano');
      expect(testRun.creatorId, 'creator_123');
      expect(testRun.estimatedDistance, 5.0);
      expect(testRun.participants.length, 2);
      expect(testRun.isPublic, true);
    });

    test('should convert Run to Map correctly', () {
      final map = testRun.toMap();
      
      expect(map['id'], 'test_run_id');
      expect(map['title'], 'Morning Jog in Milano');
      expect(map['creatorId'], 'creator_123');
      expect(map['estimatedDistance'], 5.0);
      expect(map['participants'], ['creator_123', 'participant_456']);
      expect(map['dateTime'], isA<Timestamp>());
      expect(map['startLocation'], isA<Map<String, dynamic>>());
      expect(map['weather'], {'temperature': 15, 'condition': 'sunny'});
    });

    test('should create Run from Map correctly', () {
      final map = testRun.toMap();
      final recreatedRun = Run.fromMap(map, 'test_run_id');
      
      expect(recreatedRun.id, testRun.id);
      expect(recreatedRun.title, testRun.title);
      expect(recreatedRun.creatorId, testRun.creatorId);
      expect(recreatedRun.estimatedDistance, testRun.estimatedDistance);
      expect(recreatedRun.participants, testRun.participants);
      expect(recreatedRun.startLocationName, testRun.startLocationName);
      expect(recreatedRun.isPublic, testRun.isPublic);
    });

    test('should handle copyWith correctly', () {
      final updatedRun = testRun.copyWith(
        title: 'Evening Run',
        maxParticipants: 10,
        difficulty: 'moderate',
      );
      
      expect(updatedRun.title, 'Evening Run');
      expect(updatedRun.maxParticipants, 10);
      expect(updatedRun.difficulty, 'moderate');
      // Original values should remain unchanged
      expect(updatedRun.creatorId, testRun.creatorId);
      expect(updatedRun.estimatedDistance, testRun.estimatedDistance);
      expect(updatedRun.startLocationName, testRun.startLocationName);
    });

    test('should calculate available spots correctly', () {
      expect(testRun.availableSpots, 6); // 8 max - 2 participants = 6
      
      final fullRun = testRun.copyWith(
        participants: List.generate(8, (index) => 'user_$index'),
      );
      expect(fullRun.availableSpots, 0);
    });

    test('should check if run is full correctly', () {
      expect(testRun.isFull, false);
      
      final fullRun = testRun.copyWith(
        participants: List.generate(8, (index) => 'user_$index'),
      );
      expect(fullRun.isFull, true);
    });

    test('should check if run is upcoming correctly', () {
      final futureRun = testRun.copyWith(
        dateTime: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(futureRun.isUpcoming, true);
      
      final pastRun = testRun.copyWith(
        dateTime: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(pastRun.isUpcoming, false);
    });

    test('should check run status correctly', () {
      expect(testRun.isActive, false);
      expect(testRun.isCompleted, false);
      expect(testRun.isCancelled, false);
      
      final activeRun = testRun.copyWith(status: 'active');
      expect(activeRun.isActive, true);
      
      final completedRun = testRun.copyWith(status: 'completed');
      expect(completedRun.isCompleted, true);
      
      final cancelledRun = testRun.copyWith(status: 'cancelled');
      expect(cancelledRun.isCancelled, true);
    });

    test('should calculate total interested users correctly', () {
      final runWithWaitlist = testRun.copyWith(
        waitingList: ['waiting_user_1', 'waiting_user_2'],
      );
      
      expect(runWithWaitlist.totalInterestedUsers, 4); // 2 participants + 2 waiting
    });

    test('should handle missing optional fields in fromMap', () {
      final minimalMap = {
        'creatorId': 'creator_123',
        'title': 'Test Run',
        'dateTime': Timestamp.fromDate(DateTime.now()),
        'startLocation': {
          'geopoint': GeoPoint(45.4642, 9.1900),
          'geohash': 'test_hash'
        },
        'startLocationName': 'Test Location',
        'createdAt': Timestamp.fromDate(DateTime.now()),
      };
      
      final run = Run.fromMap(minimalMap, 'test_id');
      
      expect(run.id, 'test_id');
      expect(run.title, 'Test Run');
      expect(run.description, null);
      expect(run.estimatedDistance, null);
      expect(run.participants, isEmpty);
      expect(run.maxParticipants, 10); // default value
      expect(run.difficulty, 'moderate'); // default value
      expect(run.isPublic, true); // default value
    });
  });

  group('RunParticipant Model Tests', () {
    late RunParticipant testParticipant;

    setUp(() {
      testParticipant = const RunParticipant(
        userId: 'user_123',
        displayName: 'John Runner',
        photoUrl: 'https://example.com/photo.jpg',
        joinedAt: DateTime(2024, 3, 10, 9, 0),
        status: 'confirmed',
        isCreator: false,
      );
    });

    test('should create RunParticipant with all properties', () {
      expect(testParticipant.userId, 'user_123');
      expect(testParticipant.displayName, 'John Runner');
      expect(testParticipant.photoUrl, 'https://example.com/photo.jpg');
      expect(testParticipant.status, 'confirmed');
      expect(testParticipant.isCreator, false);
    });

    test('should convert RunParticipant to Map correctly', () {
      final map = testParticipant.toMap();
      
      expect(map['userId'], 'user_123');
      expect(map['displayName'], 'John Runner');
      expect(map['photoUrl'], 'https://example.com/photo.jpg');
      expect(map['status'], 'confirmed');
      expect(map['isCreator'], false);
      expect(map['joinedAt'], isA<Timestamp>());
    });

    test('should create RunParticipant from Map correctly', () {
      final map = testParticipant.toMap();
      final recreatedParticipant = RunParticipant.fromMap(map);
      
      expect(recreatedParticipant.userId, testParticipant.userId);
      expect(recreatedParticipant.displayName, testParticipant.displayName);
      expect(recreatedParticipant.photoUrl, testParticipant.photoUrl);
      expect(recreatedParticipant.status, testParticipant.status);
      expect(recreatedParticipant.isCreator, testParticipant.isCreator);
    });

    test('should handle missing optional fields in fromMap', () {
      final minimalMap = {
        'userId': 'user_123',
        'displayName': 'John Runner',
        'joinedAt': Timestamp.fromDate(DateTime.now()),
      };
      
      final participant = RunParticipant.fromMap(minimalMap);
      
      expect(participant.userId, 'user_123');
      expect(participant.displayName, 'John Runner');
      expect(participant.photoUrl, null);
      expect(participant.status, 'confirmed'); // default value
      expect(participant.isCreator, false); // default value
    });
  });
}