import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String runId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final List<String> readBy;
  final String? replyToMessageId;
  final List<String>? imageUrls;
  final Map<String, dynamic>? locationData;

  const Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.runId,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.isRead = false,
    this.readBy = const [],
    this.replyToMessageId,
    this.imageUrls,
    this.locationData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'runId': runId,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'readBy': readBy,
      'replyToMessageId': replyToMessageId,
      'imageUrls': imageUrls,
      'locationData': locationData,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map, String documentId) {
    return Message(
      id: documentId,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderPhotoUrl: map['senderPhotoUrl'],
      runId: map['runId'] ?? '',
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      readBy: List<String>.from(map['readBy'] ?? []),
      replyToMessageId: map['replyToMessageId'],
      imageUrls: map['imageUrls'] != null 
          ? List<String>.from(map['imageUrls']) 
          : null,
      locationData: map['locationData'],
    );
  }

  Message copyWith({
    String? content,
    bool? isRead,
    List<String>? readBy,
  }) {
    return Message(
      id: id,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      runId: runId,
      content: content ?? this.content,
      type: type,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      readBy: readBy ?? this.readBy,
      replyToMessageId: replyToMessageId,
      imageUrls: imageUrls,
      locationData: locationData,
    );
  }

  bool get isSystemMessage => type == MessageType.system;
  bool get hasImages => imageUrls != null && imageUrls!.isNotEmpty;
  bool get hasLocation => locationData != null;
  bool get isReply => replyToMessageId != null;
}

enum MessageType {
  text,
  image,
  location,
  system,
}

class ChatMetadata {
  final String runId;
  final List<String> participants;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String? lastMessage;
  final String? lastMessageSender;
  final int unreadCount;
  final bool isActive;

  const ChatMetadata({
    required this.runId,
    required this.participants,
    required this.createdAt,
    this.lastMessageAt,
    this.lastMessage,
    this.lastMessageSender,
    this.unreadCount = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'runId': runId,
      'participants': participants,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageAt': lastMessageAt != null 
          ? Timestamp.fromDate(lastMessageAt!) 
          : null,
      'lastMessage': lastMessage,
      'lastMessageSender': lastMessageSender,
      'unreadCount': unreadCount,
      'isActive': isActive,
    };
  }

  factory ChatMetadata.fromMap(Map<String, dynamic> map) {
    return ChatMetadata(
      runId: map['runId'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastMessageAt: map['lastMessageAt'] != null 
          ? (map['lastMessageAt'] as Timestamp).toDate() 
          : null,
      lastMessage: map['lastMessage'],
      lastMessageSender: map['lastMessageSender'],
      unreadCount: map['unreadCount'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }

  ChatMetadata copyWith({
    List<String>? participants,
    DateTime? lastMessageAt,
    String? lastMessage,
    String? lastMessageSender,
    int? unreadCount,
    bool? isActive,
  }) {
    return ChatMetadata(
      runId: runId,
      participants: participants ?? this.participants,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
    );
  }
}