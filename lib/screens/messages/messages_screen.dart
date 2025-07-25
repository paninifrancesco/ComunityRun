import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/message.dart';
import '../../services/auth_service.dart';
import '../../services/message_service.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Please sign in to view messages'),
            );
          }
          return _buildMessagesList(context, ref, user.uid);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context, WidgetRef ref, String userId) {
    final messageService = ref.read(messageServiceProvider);
    
    return StreamBuilder<List<ChatMetadata>>(
      stream: messageService.getUserChats(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Error loading messages: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: () {
                    // Trigger rebuild
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        final chats = snapshot.data ?? [];
        
        if (chats.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Join a run to start chatting with other runners!',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            return _buildChatTile(context, chat, userId);
          },
        );
      },
    );
  }

  Widget _buildChatTile(BuildContext context, ChatMetadata chat, String userId) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.group, color: Colors.white),
        ),
        title: Text(
          'Run Chat',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chat.lastMessage != null) ...[
              Text(
                chat.lastMessage!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: chat.unreadCount > 0 
                    ? Colors.black87 
                    : Colors.grey[600],
                  fontWeight: chat.unreadCount > 0 
                    ? FontWeight.w500 
                    : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              _formatLastMessageTime(chat.lastMessageAt ?? chat.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: chat.unreadCount > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
              child: Text(
                '${chat.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : null,
        onTap: () {
          context.push('/chat/${chat.runId}');
        },
      ),
    );
  }

  String _formatLastMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}