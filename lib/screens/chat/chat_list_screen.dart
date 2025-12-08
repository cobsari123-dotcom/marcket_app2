import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/chat_room.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/screens/chat/chat_tab.dart';
import 'package:marcket_app/screens/chat/user_list_tab.dart';
import 'package:provider/provider.dart';
import 'package:marcket_app/providers/user_profile_provider.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => ChatListScreenState();
}

class ChatListScreenState extends State<ChatListScreen>
    with AutomaticKeepAliveClientMixin {
  final _database = FirebaseDatabase.instance.ref();
  String? _currentUserId;
  Stream<DatabaseEvent>? _chatRoomsStream;
  Stream<DatabaseEvent>? _usersStream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _initializeStreams();
  }

  void _initializeStreams() {
    if (_currentUserId == null) return;

    _chatRoomsStream = _database
        .child('chat_rooms')
        .orderByChild('participants/$_currentUserId')
        .equalTo(true)
        .onValue
        .asBroadcastStream();

    _database
        .child('users/$_currentUserId')
        .get()
        .then((DataSnapshot snapshot) {
      if (snapshot.exists && snapshot.value != null && mounted) {
        final currentUserModel = UserModel.fromMap(
            Map<String, dynamic>.from(snapshot.value as Map), snapshot.key!);
        setState(() {
          if (currentUserModel.userType == 'Seller') {
            _usersStream = _database
                .child('users')
                .orderByChild('userType')
                .equalTo('Buyer')
                .onValue
                .asBroadcastStream();
          } else if (currentUserModel.userType == 'Buyer') {
            _usersStream = _database
                .child('users')
                .orderByChild('userType')
                .equalTo('Seller')
                .onValue
                .asBroadcastStream();
          } else if (currentUserModel.userType == 'Admin') {
            _usersStream = _database.child('users').onValue.asBroadcastStream();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userProfileProvider = Provider.of<UserProfileProvider>(context);
    final currentUserModel = userProfileProvider.currentUserModel;

    if (currentUserModel == null) {
      return const Center(child: Text('Inicia sesión para ver tus mensajes.'));
    }

    if (_chatRoomsStream == null || _usersStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: currentUserModel.userType == 'Admin'
                ? const [
                    Tab(text: 'Chats de Soporte'),
                    Tab(text: 'Todos los Usuarios')
                  ]
                : currentUserModel.userType == 'Seller'
                    ? const [Tab(text: 'Chats'), Tab(text: 'Compradores')]
                    : const [Tab(text: 'Chats'), Tab(text: 'Vendedores')],
          ),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: TabBarView(
                children: [
                  ChatTab(
                      stream: _chatRoomsStream!,
                      currentUserId: currentUserModel.id),
                  UserListTab(
                    stream: _usersStream!,
                    currentUserId: currentUserModel.id,
                    onUserTap: (user) {
                      _navigateToChatWithUser(
                          user, currentUserModel.id, currentUserModel);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToChatWithUser(
      UserModel user, String currentUserId, UserModel currentUserModel) async {
    final chatRoomId = _getChatRoomId(currentUserId, user.id);
    final chatRoomRef = FirebaseDatabase.instance.ref('chat_rooms/$chatRoomId');

    DataSnapshot snapshot = await chatRoomRef.get();
    if (!snapshot.exists) {
      final newChatRoom = ChatRoom(
        id: chatRoomId,
        participants: {currentUserId: true, user.id: true},
        lastMessage: 'Chat iniciado.',
        lastMessageTimestamp: DateTime.now(),
        participantInfo: {
          currentUserId: {
            'fullName': currentUserModel.fullName,
            'profilePicture': currentUserModel.profilePicture,
          },
          user.id: {
            'fullName': user.fullName,
            'profilePicture': user.profilePicture,
          }
        },
      );
      await chatRoomRef.set(newChatRoom.toMap());
    }

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'chatRoomId': chatRoomId,
        'otherUserName': user.fullName,
      },
    );
  }

  String _getChatRoomId(String userId1, String userId2) {
    const supportAdminId = 'support_admin_user';
    if (userId1 == supportAdminId) {
      return '$supportAdminId-$userId2';
    } else if (userId2 == supportAdminId) {
      return '$supportAdminId-$userId1';
    }

    if (userId1.compareTo(userId2) > 0) {
      return '$userId1-$userId2';
    } else {
      return '$userId2-$userId1';
    }
  }
}
