import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/chat_room.dart';
import 'package:marcket_app/screens/chat/chat_list_item.dart';

class ChatTab extends StatefulWidget {
  final Stream<DatabaseEvent> stream;
  final String currentUserId;

  const ChatTab({super.key, required this.stream, required this.currentUserId});

  @override
  ChatTabState createState() => ChatTabState();
}

class ChatTabState extends State<ChatTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder(
      stream: widget.stream,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text('No tienes mensajes.'));
        }

        final chatRoomsData = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        final allChatRooms = chatRoomsData.entries.map((entry) {
          return ChatRoom.fromMap(Map<String, dynamic>.from(entry.value as Map), entry.key);
        }).toList();
        
        // Filter out support chats, they are handled in a different section
        final filteredChatRooms = allChatRooms.where((cr) => !cr.id.contains('support_admin_user')).toList();

        if (filteredChatRooms.isEmpty) {
          return const Center(child: Text('No tienes conversaciones con otros usuarios.'));
        }

        filteredChatRooms.sort((a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp));

        return ListView.builder(
          itemCount: filteredChatRooms.length,
          itemBuilder: (context, index) {
            final chatRoom = filteredChatRooms[index];
            return ChatListItem(chatRoom: chatRoom, currentUserId: widget.currentUserId);
          },
        );
      },
    );
  }
}
