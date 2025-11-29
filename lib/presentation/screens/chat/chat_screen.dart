import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/chat_provider.dart';
import '../profile/profile_view_screen.dart';

class ChatScreen extends StatefulWidget {
  final Channel channel;

  const ChatScreen({
    super.key,
    required this.channel,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  StreamSubscription? _messageSubscription;

  Message? _selectedMessage;
  bool _isSelectingMessage = false;
  bool _isDeletingMessage = false;

  final Set<String> _deletedMessageIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _listenToNewMessages();
  }

  void _loadMessages() {
    try {
      final initialMessages = widget.channel.state?.messages ?? [];
      setState(() {
        _messages = initialMessages;
      });
      _scrollToBottom();
    } catch (e) {
      // Error handling
    }
  }

  void _listenToNewMessages() {
    final messagesStream = widget.channel.state?.messagesStream;
    if (messagesStream == null) return;

    _messageSubscription = messagesStream.listen((event) {
      if (mounted) {
        setState(() {
          _messages = event;
          _deletedMessageIds
              .removeWhere((id) => !event.any((message) => message.id == id));
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      await widget.channel.sendMessage(Message(text: text));
      _messageController.clear();
    } catch (e) {
      // Error handling
    }
  }

  List<Message> get _visibleMessages {
    return _messages.where((message) {
      return message.type != 'deleted' &&
          !_deletedMessageIds.contains(message.id);
    }).toList();
  }

  void _selectMessage(Message message) {
    setState(() {
      _selectedMessage = message;
      _isSelectingMessage = true;
    });

    _showMessageOptions(message);
  }

  void _deselectMessage() {
    setState(() {
      _selectedMessage = null;
      _isSelectingMessage = false;
    });
  }

  void _showMessageOptions(Message message) {
    final isCurrentUser =
        message.user?.id == widget.channel.client.state.currentUser?.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCurrentUser) ...[
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Eliminar mensaje',
                    style: TextStyle(color: Colors.red, fontFamily: 'Poppins'),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteMessage(message);
                  },
                ),
                const Divider(color: Colors.grey),
              ],
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.white),
                title: const Text(
                  'Copiar texto',
                  style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _copyMessageText(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.grey),
                title: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deselectMessage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteMessage(Message message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Eliminar Mensaje',
          style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
        ),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este mensaje? Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
              _deselectMessage();
            },
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red, fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteMessage(message);
    } else {
      _deselectMessage();
    }
  }

  Future<void> _deleteMessage(Message message) async {
    if (_isDeletingMessage) return;

    final messageId = message.id;

    if (message.type == 'deleted' || _deletedMessageIds.contains(messageId)) {
      _markMessageAsDeleted(messageId);
      return;
    }

    try {
      setState(() {
        _isDeletingMessage = true;
      });

      await widget.channel.deleteMessage(message);

      _markMessageAsDeleted(messageId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mensaje eliminado correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Error al eliminar mensaje';

      if (e.toString().contains('has been deleted') ||
          e.toString().contains('404') ||
          e.toString().contains('not found')) {
        errorMessage = 'El mensaje ya fue eliminado';
        _markMessageAsDeleted(messageId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() {
        _isDeletingMessage = false;
        _selectedMessage = null;
        _isSelectingMessage = false;
      });
    }
  }

  void _markMessageAsDeleted(String messageId) {
    setState(() {
      _deletedMessageIds.add(messageId);
    });
  }

  void _copyMessageText(Message message) {
    final text = message.text ?? '';
    if (text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Texto copiado: $text'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
    _deselectMessage();
  }

  User? _getOtherUser() {
    final currentUserId = widget.channel.client.state.currentUser?.id;
    final members = widget.channel.state?.members ?? [];
    final otherMembers =
        members.where((member) => member.userId != currentUserId).toList();
    return otherMembers.isNotEmpty ? otherMembers.first.user : null;
  }

  void _viewProfile() {
    final otherUser = _getOtherUser();
    if (otherUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cargar el perfil'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileViewScreen(userId: otherUser.id),
      ),
    );
  }

  Future<void> _deleteMatch() async {
    final otherUser = _getOtherUser();
    if (otherUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Eliminar Match',
          style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar el match con ${otherUser.name}? Se eliminará el chat completo y no podrás recuperarlo.',
          style: const TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red, fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final chatProvider = context.read<ChatProvider>();
      final success = await chatProvider.deleteMatch(otherUser.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar el match'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final currentUser = chatProvider.client?.state.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0F0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildAppBarTitle(),
        actions: [
          if (_isDeletingMessage)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: _showChatOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSelectingMessage && _selectedMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF8B1538),
              child: Row(
                children: [
                  const Icon(Icons.message, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mensaje seleccionado: ${_selectedMessage!.text ?? ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: _deselectMessage,
                  ),
                ],
              ),
            ),
          Expanded(
            child: _visibleMessages.isEmpty
                ? const Center(
                    child: Text(
                      'No hay mensajes aún',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _visibleMessages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageItem(
                          _visibleMessages[index], currentUser);
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: const Text(
                  'Ver perfil',
                  style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _viewProfile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Eliminar match',
                  style: TextStyle(color: Colors.red, fontFamily: 'Poppins'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMatch();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBarTitle() {
    final otherUser = _getOtherUser();
    final displayName = otherUser?.name ?? 'Usuario';

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFF8B1538),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const Text(
                'En línea',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageItem(Message message, User? currentUser) {
    final messageId = message.id;
    if (message.type == 'deleted' || _deletedMessageIds.contains(messageId)) {
      return const SizedBox.shrink();
    }

    final isCurrentUser = message.user?.id == currentUser?.id;

    String getFirstLetter(String? name) {
      if (name == null || name.isEmpty) return 'U';
      return name[0].toUpperCase();
    }

    final isSelected = _selectedMessage?.id == messageId;

    return GestureDetector(
      onLongPress: () => _selectMessage(message),
      onTap: () {
        if (_isSelectingMessage) {
          _deselectMessage();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: const Color(0xFF8B1538), width: 2)
              : null,
        ),
        child: Row(
          mainAxisAlignment:
              isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isCurrentUser) ...[
              CircleAvatar(
                backgroundColor: const Color(0xFF8B1538),
                radius: 16,
                child: Text(
                  getFirstLetter(message.user?.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? const Color(0xFF8B1538)
                      : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isCurrentUser)
                      Text(
                        message.user?.name ?? 'Usuario',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    Text(
                      message.text ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatMessageTime(message.createdAt),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 10,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: const Color(0xFF8B1538),
                radius: 16,
                child: Text(
                  getFirstLetter(currentUser?.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1A1A1A),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF8B1538),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
