import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';

class Run {
  final String id;
  final String creatorId;
  final String title;
  final String? description;
  final DateTime dateTime;
  final GeoFirePoint startLocation;
  final String startLocationName;
  final String? route;
  final double? estimatedDistance;
  final String? estimatedPace;
  final int? estimatedDurationMinutes;
  final int maxParticipants;
  final List<String> participants;
  final List<String> waitingList;
  final String difficulty;
  final List<String> tags;
  final bool isPublic;
  final bool allowWaitingList;
  final String? meetingInstructions;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? weather;
  final String? groupChatId;

  const Run({
    required this.id,
    required this.creatorId,
    required this.title,
    this.description,
    required this.dateTime,
    required this.startLocation,
    required this.startLocationName,
    this.route,
    this.estimatedDistance,
    this.estimatedPace,
    this.estimatedDurationMinutes,
    this.maxParticipants = 10,
    this.participants = const [],
    this.waitingList = const [],
    this.difficulty = 'moderate',
    this.tags = const [],
    this.isPublic = true,
    this.allowWaitingList = true,
    this.meetingInstructions,
    this.status = 'scheduled',
    required this.createdAt,
    this.updatedAt,
    this.weather,
    this.groupChatId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creatorId': creatorId,
      'title': title,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'startLocation': startLocation.data,
      'startLocationName': startLocationName,
      'route': route,
      'estimatedDistance': estimatedDistance,
      'estimatedPace': estimatedPace,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'maxParticipants': maxParticipants,
      'participants': participants,
      'waitingList': waitingList,
      'difficulty': difficulty,
      'tags': tags,
      'isPublic': isPublic,
      'allowWaitingList': allowWaitingList,
      'meetingInstructions': meetingInstructions,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'weather': weather,
      'groupChatId': groupChatId,
    };
  }

  factory Run.fromMap(Map<String, dynamic> map, String documentId) {
    final geo = GeoFlutterFire();
    return Run(
      id: documentId,
      creatorId: map['creatorId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      startLocation: geo.point(
        latitude: map['startLocation']['geopoint'].latitude,
        longitude: map['startLocation']['geopoint'].longitude,
      ),
      startLocationName: map['startLocationName'] ?? '',
      route: map['route'],
      estimatedDistance: map['estimatedDistance']?.toDouble(),
      estimatedPace: map['estimatedPace'],
      estimatedDurationMinutes: map['estimatedDurationMinutes'],
      maxParticipants: map['maxParticipants'] ?? 10,
      participants: List<String>.from(map['participants'] ?? []),
      waitingList: List<String>.from(map['waitingList'] ?? []),
      difficulty: map['difficulty'] ?? 'moderate',
      tags: List<String>.from(map['tags'] ?? []),
      isPublic: map['isPublic'] ?? true,
      allowWaitingList: map['allowWaitingList'] ?? true,
      meetingInstructions: map['meetingInstructions'],
      status: map['status'] ?? 'scheduled',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
      weather: map['weather'],
      groupChatId: map['groupChatId'],
    );
  }

  Run copyWith({
    String? title,
    String? description,
    DateTime? dateTime,
    GeoFirePoint? startLocation,
    String? startLocationName,
    String? route,
    double? estimatedDistance,
    String? estimatedPace,
    int? estimatedDurationMinutes,
    int? maxParticipants,
    List<String>? participants,
    List<String>? waitingList,
    String? difficulty,
    List<String>? tags,
    bool? isPublic,
    bool? allowWaitingList,
    String? meetingInstructions,
    String? status,
    DateTime? updatedAt,
    Map<String, dynamic>? weather,
    String? groupChatId,
  }) {
    return Run(
      id: id,
      creatorId: creatorId,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      startLocation: startLocation ?? this.startLocation,
      startLocationName: startLocationName ?? this.startLocationName,
      route: route ?? this.route,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      estimatedPace: estimatedPace ?? this.estimatedPace,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      participants: participants ?? this.participants,
      waitingList: waitingList ?? this.waitingList,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      isPublic: isPublic ?? this.isPublic,
      allowWaitingList: allowWaitingList ?? this.allowWaitingList,
      meetingInstructions: meetingInstructions ?? this.meetingInstructions,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      weather: weather ?? this.weather,
      groupChatId: groupChatId ?? this.groupChatId,
    );
  }

  bool get isFull => participants.length >= maxParticipants;
  bool get hasWaitingList => waitingList.isNotEmpty;
  bool get isUpcoming => dateTime.isAfter(DateTime.now());
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  int get availableSpots => maxParticipants - participants.length;
  int get totalInterestedUsers => participants.length + waitingList.length;
}

enum RunStatus {
  scheduled,
  active,
  completed,
  cancelled,
}

enum RunDifficulty {
  easy,
  moderate,
  hard,
  expert,
}

class RunParticipant {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final DateTime joinedAt;
  final String status;
  final bool isCreator;

  const RunParticipant({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.joinedAt,
    this.status = 'confirmed',
    this.isCreator = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'status': status,
      'isCreator': isCreator,
    };
  }

  factory RunParticipant.fromMap(Map<String, dynamic> map) {
    return RunParticipant(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'confirmed',
      isCreator: map['isCreator'] ?? false,
    );
  }
}