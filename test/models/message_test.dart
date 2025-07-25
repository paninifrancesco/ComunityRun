import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:communityrun/models/message.dart';

void main() {
  group('Message Model Tests', () {
    late Message testMessage;

    setUp(() {
      testMessage = const Message(
        id: 'message_123',
        senderId: 'user_456',
        senderName: 'Mario Rossi',
        senderPhotoUrl: 'https://example.com/photo.jpg',
        runId: 'run_789',
        content: 'Ciao a tutti! Ci vediamo alle 7:00 domani mattina!',
        type: MessageType.text,
        timestamp: DateTime(2024, 3, 10, 20, 30),
        isRead: false,
        readBy: ['user_111', 'user_222'],
        replyToMessageId: 'message_122',
        imageUrls: null,
        locationData: null,
      );
    });

    test('should create Message with all properties', () {
      expect(testMessage.id, 'message_123');
      expect(testMessage.senderId, 'user_456');
      expect(testMessage.senderName, 'Mario Rossi');
      expect(testMessage.runId, 'run_789');
      expect(testMessage.content, 'Ciao a tutti! Ci vediamo alle 7:00 domani mattina!');
      expect(testMessage.type, MessageType.text);
      expect(testMessage.isRead, false);
      expect(testMessage.readBy, ['user_111', 'user_222']);
      expect(testMessage.replyToMessageId, 'message_122');
    });

    test('should convert Message to Map correctly', () {
      final map = testMessage.toMap();
      
      expect(map['id'], 'message_123');
      expect(map['senderId'], 'user_456');
      expect(map['senderName'], 'Mario Rossi');
      expect(map['runId'], 'run_789');
      expect(map['content'], 'Ciao a tutti! Ci vediamo alle 7:00 domani mattina!');
      expect(map['type'], 'text');
      expect(map['isRead'], false);
      expect(map['readBy'], ['user_111', 'user_222']);
      expect(map['replyToMessageId'], 'message_122');
      expect(map['timestamp'], isA<Timestamp>());
      expect(map['imageUrls'], null);
      expect(map['locationData'], null);
    });

    test('should create Message from Map correctly', () {
      final map = testMessage.toMap();
      final recreatedMessage = Message.fromMap(map, 'message_123');
      
      expect(recreatedMessage.id, testMessage.id);
      expect(recreatedMessage.senderId, testMessage.senderId);
      expect(recreatedMessage.senderName, testMessage.senderName);
      expect(recreatedMessage.runId, testMessage.runId);
      expect(recreatedMessage.content, testMessage.content);
      expect(recreatedMessage.type, testMessage.type);
      expect(recreatedMessage.isRead, testMessage.isRead);
      expect(recreatedMessage.readBy, testMessage.readBy);
      expect(recreatedMessage.replyToMessageId, testMessage.replyToMessageId);
    });

    test('should handle copyWith correctly', () {
      final updatedMessage = testMessage.copyWith(
        content: 'Updated message content',
        isRead: true,
        readBy: ['user_111', 'user_222', 'user_333'],
      );
      
      expect(updatedMessage.content, 'Updated message content');
      expect(updatedMessage.isRead, true);
      expect(updatedMessage.readBy, ['user_111', 'user_222', 'user_333']);
      // Original values should remain unchanged for other fields
      expect(updatedMessage.id, testMessage.id);
      expect(updatedMessage.senderId, testMessage.senderId);
      expect(updatedMessage.type, testMessage.type);
    });

    test('should handle different message types correctly', () {
      final textMessage = testMessage.copyWith();
      expect(textMessage.type, MessageType.text);
      expect(textMessage.isSystemMessage, false);

      const systemMessage = Message(
        id: 'sys_msg_1',
        senderId: 'system',
        senderName: 'System',
        runId: 'run_789',
        content: 'User joined the run',
        type: MessageType.system,
        timestamp: DateTime(2024, 3, 10, 20, 35),
      );
      expect(systemMessage.isSystemMessage, true);

      const imageMessage = Message(
        id: 'img_msg_1',
        senderId: 'user_456',
        senderName: 'Mario Rossi',
        runId: 'run_789',
        content: 'Check out this photo!',
        type: MessageType.image,
        timestamp: DateTime(2024, 3, 10, 20, 40),
        imageUrls: ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
      );
      expect(imageMessage.type, MessageType.image);
      expect(imageMessage.hasImages, true);
    });

    test('should check convenience properties correctly', () {
      expect(testMessage.isSystemMessage, false);
      expect(testMessage.hasImages, false);
      expect(testMessage.hasLocation, false);
      expect(testMessage.isReply, true); // has replyToMessageId

      const messageWithImages = Message(
        id: 'img_msg',
        senderId: 'user_456',
        senderName: 'Mario Rossi',
        runId: 'run_789',
        content: 'Photo message',
        type: MessageType.image,
        timestamp: DateTime(2024, 3, 10, 20, 40),
        imageUrls: ['https://example.com/image.jpg'],
      );
      expect(messageWithImages.hasImages, true);

      const messageWithLocation = Message(
        id: 'loc_msg',
        senderId: 'user_456',
        senderName: 'Mario Rossi',
        runId: 'run_789',
        content: 'My location',
        type: MessageType.location,
        timestamp: DateTime(2024, 3, 10, 20, 45),
        locationData: {'latitude': 45.4642, 'longitude': 9.1900},
      );
      expect(messageWithLocation.hasLocation, true);

      const messageWithoutReply = Message(
        id: 'no_reply_msg',
        senderId: 'user_456',
        senderName: 'Mario Rossi',
        runId: 'run_789',
        content: 'Regular message',
        timestamp: DateTime(2024, 3, 10, 20, 50),
      );
      expect(messageWithoutReply.isReply, false);
    });

    test('should handle missing optional fields in fromMap', () {
      final minimalMap = {
        'senderId': 'user_456',
        'senderName': 'Mario Rossi',
        'runId': 'run_789',
        'content': 'Test message',
        'timestamp': Timestamp.fromDate(DateTime.now()),
      };
      
      final message = Message.fromMap(minimalMap, 'test_id');
      
      expect(message.id, 'test_id');
      expect(message.senderId, 'user_456');
      expect(message.senderName, 'Mario Rossi');
      expect(message.content, 'Test message');
      expect(message.type, MessageType.text); // default value
      expect(message.isRead, false); // default value
      expect(message.readBy, isEmpty);
      expect(message.senderPhotoUrl, null);
      expect(message.replyToMessageId, null);
      expect(message.imageUrls, null);
      expect(message.locationData, null);
    });

    test('should handle MessageType enum conversion correctly', () {
      const systemMessage = Message(
        id: 'sys_1',
        senderId: 'system',
        senderName: 'System',
        runId: 'run_1',
        content: 'System message',
        type: MessageType.system,
        timestamp: DateTime(2024, 3, 10, 20, 0),
      );

      final map = systemMessage.toMap();
      expect(map['type'], 'system');

      final recreated = Message.fromMap(map, 'sys_1');
      expect(recreated.type, MessageType.system);
    });
  });

  group('ChatMetadata Model Tests', () {
    late ChatMetadata testChatMetadata;

    setUp(() {
      testChatMetadata = const ChatMetadata(
        runId: 'run_123',
        participants: ['user_1', 'user_2', 'user_3'],
        createdAt: DateTime(2024, 3, 10, 18, 0),
        lastMessageAt: DateTime(2024, 3, 10, 20, 30),
        lastMessage: 'See you tomorrow!',
        lastMessageSender: 'Mario Rossi',
        unreadCount: 3,
        isActive: true,
      );
    });

    test('should create ChatMetadata with all properties', () {
      expect(testChatMetadata.runId, 'run_123');
      expect(testChatMetadata.participants, ['user_1', 'user_2', 'user_3']);
      expect(testChatMetadata.lastMessage, 'See you tomorrow!');
      expect(testChatMetadata.lastMessageSender, 'Mario Rossi');
      expect(testChatMetadata.unreadCount, 3);
      expect(testChatMetadata.isActive, true);
    });

    test('should convert ChatMetadata to Map correctly', () {
      final map = testChatMetadata.toMap();
      
      expect(map['runId'], 'run_123');
      expect(map['participants'], ['user_1', 'user_2', 'user_3']);
      expect(map['lastMessage'], 'See you tomorrow!');
      expect(map['lastMessageSender'], 'Mario Rossi');
      expect(map['unreadCount'], 3);
      expect(map['isActive'], true);
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['lastMessageAt'], isA<Timestamp>());
    });

    test('should create ChatMetadata from Map correctly', () {
      final map = testChatMetadata.toMap();
      final recreatedChatMetadata = ChatMetadata.fromMap(map);
      
      expect(recreatedChatMetadata.runId, testChatMetadata.runId);
      expect(recreatedChatMetadata.participants, testChatMetadata.participants);
      expect(recreatedChatMetadata.lastMessage, testChatMetadata.lastMessage);
      expect(recreatedChatMetadata.lastMessageSender, testChatMetadata.lastMessageSender);
      expect(recreatedChatMetadata.unreadCount, testChatMetadata.unreadCount);
      expect(recreatedChatMetadata.isActive, testChatMetadata.isActive);
    });

    test('should handle copyWith correctly', () {
      final updatedChatMetadata = testChatMetadata.copyWith(
        lastMessage: 'Updated last message',
        unreadCount: 5,
        isActive: false,
      );
      
      expect(updatedChatMetadata.lastMessage, 'Updated last message');
      expect(updatedChatMetadata.unreadCount, 5);
      expect(updatedChatMetadata.isActive, false);
      // Original values should remain unchanged for other fields
      expect(updatedChatMetadata.runId, testChatMetadata.runId);
      expect(updatedChatMetadata.participants, testChatMetadata.participants);
      expect(updatedChatMetadata.lastMessageSender, testChatMetadata.lastMessageSender);
    });

    test('should handle missing optional fields in fromMap', () {
      final minimalMap = {
        'runId': 'run_123',
        'participants': ['user_1', 'user_2'],
        'createdAt': Timestamp.fromDate(DateTime.now()),
      };
      
      final chatMetadata = ChatMetadata.fromMap(minimalMap);
      
      expect(chatMetadata.runId, 'run_123');
      expect(chatMetadata.participants, ['user_1', 'user_2']);
      expect(chatMetadata.lastMessageAt, null);
      expect(chatMetadata.lastMessage, null);
      expect(chatMetadata.lastMessageSender, null);
      expect(chatMetadata.unreadCount, 0); // default value
      expect(chatMetadata.isActive, true); // default value
    });

    test('should handle null lastMessageAt correctly', () {
      const chatWithoutLastMessage = ChatMetadata(
        runId: 'run_456',
        participants: ['user_1'],
        createdAt: DateTime(2024, 3, 10, 18, 0),
        lastMessageAt: null,
        unreadCount: 0,
        isActive: true,
      );

      final map = chatWithoutLastMessage.toMap();
      expect(map['lastMessageAt'], null);

      final recreated = ChatMetadata.fromMap(map);
      expect(recreated.lastMessageAt, null);
    });
  });

  group('MessageType Enum Tests', () {
    test('should have all expected enum values', () {
      expect(MessageType.values.length, 4);
      expect(MessageType.values, contains(MessageType.text));
      expect(MessageType.values, contains(MessageType.image));
      expect(MessageType.values, contains(MessageType.location));
      expect(MessageType.values, contains(MessageType.system));
    });

    test('should convert enum to string correctly', () {
      expect(MessageType.text.toString().split('.').last, 'text');
      expect(MessageType.image.toString().split('.').last, 'image');
      expect(MessageType.location.toString().split('.').last, 'location');
      expect(MessageType.system.toString().split('.').last, 'system');
    });
  });
}