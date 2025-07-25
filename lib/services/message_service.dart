import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import 'firestore_service.dart';

final messageServiceProvider = Provider<MessageService>((ref) {
  return MessageService(ref.read(firestoreServiceProvider));
});

class MessageService {
  final FirestoreService _firestoreService;

  MessageService(this._firestoreService);

  Future<String> sendMessage(Message message) async {
    try {
      return await _firestoreService.sendMessage(message);
    } catch (e) {
      throw MessageServiceException('Failed to send message: ${e.toString()}');
    }
  }

  Stream<List<Message>> getRunMessages(String runId, {int limit = 50}) {
    try {
      return _firestoreService.getRunMessages(runId, limit: limit);
    } catch (e) {
      throw MessageServiceException('Failed to get run messages: ${e.toString()}');
    }
  }

  Future<void> markMessageAsRead(String messageId, String userId) async {
    try {
      await _firestoreService.markMessageAsRead(messageId, userId);
    } catch (e) {
      throw MessageServiceException('Failed to mark message as read: ${e.toString()}');
    }
  }

  Stream<List<ChatMetadata>> getUserChats(String userId) {
    try {
      return _firestoreService.getUserChats(userId);
    } catch (e) {
      throw MessageServiceException('Failed to get user chats: ${e.toString()}');
    }
  }

  Future<String> sendTextMessage({
    required String runId,
    required String senderId,
    required String senderName,
    required String content,
    String? senderPhotoUrl,
    String? replyToMessageId,
  }) async {
    try {
      final message = Message(
        id: '', // Will be set by Firestore
        runId: runId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        content: content,
        type: MessageType.text,
        timestamp: DateTime.now(),
        replyToMessageId: replyToMessageId,
      );
      
      return await sendMessage(message);
    } catch (e) {
      throw MessageServiceException('Failed to send text message: ${e.toString()}');
    }
  }

  Future<String> sendLocationMessage({
    required String runId,
    required String senderId,
    required String senderName,
    required Map<String, dynamic> locationData,
    String? senderPhotoUrl,
    String content = 'Shared location',
  }) async {
    try {
      final message = Message(
        id: '', // Will be set by Firestore
        runId: runId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        content: content,
        type: MessageType.location,
        timestamp: DateTime.now(),
        locationData: locationData,
      );
      
      return await sendMessage(message);
    } catch (e) {
      throw MessageServiceException('Failed to send location message: ${e.toString()}');
    }
  }

  Future<String> sendImageMessage({
    required String runId,
    required String senderId,
    required String senderName,
    required List<String> imageUrls,
    String? senderPhotoUrl,
    String content = 'Shared image',
  }) async {
    try {
      final message = Message(
        id: '', // Will be set by Firestore
        runId: runId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        content: content,
        type: MessageType.image,
        timestamp: DateTime.now(),
        imageUrls: imageUrls,
      );
      
      return await sendMessage(message);
    } catch (e) {
      throw MessageServiceException('Failed to send image message: ${e.toString()}');
    }
  }

  Future<String> sendSystemMessage({
    required String runId,
    required String content,
    String senderId = 'system',
    String senderName = 'System',
  }) async {
    try {
      final message = Message(
        id: '', // Will be set by Firestore
        runId: runId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        type: MessageType.system,
        timestamp: DateTime.now(),
      );
      
      return await sendMessage(message);
    } catch (e) {
      throw MessageServiceException('Failed to send system message: ${e.toString()}');
    }
  }

  Future<void> markAllMessagesAsRead(String runId, String userId) async {
    try {
      final messages = await getRunMessages(runId).first;
      for (final message in messages) {
        if (!message.readBy.contains(userId)) {
          await markMessageAsRead(message.id, userId);
        }
      }
    } catch (e) {
      throw MessageServiceException('Failed to mark all messages as read: ${e.toString()}');
    }
  }

  Future<int> getUnreadMessageCount(String runId, String userId) async {
    try {
      final messages = await getRunMessages(runId).first;
      return messages.where((message) => 
        message.senderId != userId && !message.readBy.contains(userId)
      ).length;
    } catch (e) {
      throw MessageServiceException('Failed to get unread message count: ${e.toString()}');
    }
  }

  Stream<int> getUnreadMessageCountStream(String runId, String userId) {
    try {
      return getRunMessages(runId).map((messages) =>
        messages.where((message) => 
          message.senderId != userId && !message.readBy.contains(userId)
        ).length
      );
    } catch (e) {
      throw MessageServiceException('Failed to get unread message count stream: ${e.toString()}');
    }
  }

  Future<void> sendUserJoinedMessage(String runId, String userName) async {
    await sendSystemMessage(
      runId: runId,
      content: '$userName joined the run',
    );
  }

  Future<void> sendUserLeftMessage(String runId, String userName) async {
    await sendSystemMessage(
      runId: runId,
      content: '$userName left the run',
    );
  }

  Future<void> sendRunUpdatedMessage(String runId, String updateDescription) async {
    await sendSystemMessage(
      runId: runId,
      content: 'Run updated: $updateDescription',
    );
  }

  Future<void> sendRunCancelledMessage(String runId) async {
    await sendSystemMessage(
      runId: runId,
      content: 'This run has been cancelled by the organizer',
    );
  }

  Future<void> sendWaitlistPromotedMessage(String runId, String userName) async {
    await sendSystemMessage(
      runId: runId,
      content: '$userName was promoted from the waiting list',
    );
  }
}

class MessageServiceException implements Exception {
  final String message;

  MessageServiceException(this.message);

  @override
  String toString() => message;
}