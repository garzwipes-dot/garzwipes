import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream_chat;
import '../../providers/chat_provider.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      if (chatProvider.isConnected) {
        chatProvider.refreshMatches();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0E0F0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0F0E),
        title: const Text(
          'Chats',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          if (chatProvider.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF8B1538),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildChatList(chatProvider),
    );
  }

  Widget _buildChatList(ChatProvider chatProvider) {
    if (chatProvider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF8B1538)),
            SizedBox(height: 16),
            Text(
              'Cargando chats...',
              style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
            ),
          ],
        ),
      );
    }

    if (!chatProvider.isConnected) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Chat no disponible',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Conectando con el servicio de chat...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }

    if (chatProvider.userChannels.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No tienes chats aún',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'Cuando hagas match con alguien, aparecerán tus chats aquí',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: chatProvider.userChannels.length,
      itemBuilder: (context, index) {
        final channel = chatProvider.userChannels[index];
        final lastMessage = channel.state?.messages.isNotEmpty == true
            ? channel.state!.messages.last
            : null;
        final otherMember = _getOtherMember(channel);

        return _buildChatItem(channel, otherMember, lastMessage);
      },
    );
  }

  stream_chat.User? _getOtherMember(stream_chat.Channel channel) {
    final currentUserId =
        context.read<ChatProvider>().client?.state.currentUser?.id;
    if (currentUserId == null) return null;

    final otherMembers = channel.state?.members
        .where((member) => member.userId != currentUserId)
        .toList();

    return otherMembers?.isNotEmpty == true ? otherMembers!.first.user : null;
  }

  Widget _buildChatItem(stream_chat.Channel channel,
      stream_chat.User? otherUser, stream_chat.Message? lastMessage) {
    final displayName = otherUser?.name ?? 'Usuario';
    final lastMessageText = lastMessage?.text ?? 'Sin mensajes';
    final lastMessageTime = lastMessage?.createdAt ?? channel.createdAt;

    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF8B1538),
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          displayName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Text(
          lastMessageText,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: lastMessageTime != null
            ? Text(
                _formatTime(lastMessageTime),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              )
            : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => ChatScreen(channel: channel),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }
}
