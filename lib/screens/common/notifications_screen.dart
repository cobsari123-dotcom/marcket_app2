import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:marcket_app/models/user.dart'; // Add this import
import 'package:marcket_app/models/chat_room.dart'; // Add this import

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => NotificationsScreenState();
}

class NotificationsScreenState extends State<NotificationsScreen> {
  final DatabaseReference _notificationsRef =
      FirebaseDatabase.instance.ref('notifications');
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  UserModel? _currentUserModel;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserModel();
  }

  Future<void> _loadCurrentUserModel() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot =
            await FirebaseDatabase.instance.ref('users/${user.uid}').get();
        if (snapshot.exists && mounted) {
          setState(() {
            _currentUserModel = UserModel.fromMap(
              Map<String, dynamic>.from(snapshot.value as Map),
              user.uid,
            );
          });
        }
      } catch (e) {
        // Handle error if needed
      }
    }
  }

  Future<void> _navigateToSupportChat() async {
    if (_userId == null || _currentUserModel == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se pudo cargar la información del usuario.')),
      );
      return;
    }

    const supportId = 'support_admin_user';
    final chatRoomId = _getChatRoomId(_userId, supportId);
    final chatRoomRef = FirebaseDatabase.instance.ref('chat_rooms/$chatRoomId');

    final snapshot = await chatRoomRef.get();
    if (!snapshot.exists) {
      final newChatRoomData = ChatRoom(
        id: chatRoomId,
        participants: {
          _userId: true,
          supportId: true,
        },
        lastMessage: 'Chat iniciado desde una notificación.',
        lastMessageTimestamp: DateTime.now(),
        participantInfo: {
          _userId: {
            'fullName': _currentUserModel!.fullName,
            'profilePicture': _currentUserModel!.profilePicture,
          },
          supportId: {
            'fullName': 'Soporte de Manos del Mar',
            'profilePicture': null,
          },
        },
      );
      await chatRoomRef.set(newChatRoomData.toMap());
    }

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'chatRoomId': chatRoomId,
        'otherUserName': 'Soporte Técnico',
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
    // For consistency, user chat should not be created here, but if it were:
    if (userId1.compareTo(userId2) > 0) {
      return '$userId1-$userId2';
    } else {
      return '$userId2-$userId1';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: _userId == null
          ? Center(
              child: Text('Inicia sesión para ver tus notificaciones.',
                  style: Theme.of(context).textTheme.titleMedium))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: StreamBuilder<DatabaseEvent>(
                  stream: _notificationsRef.child(_userId).onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Error: ${snapshot.error}',
                              style: Theme.of(context).textTheme.titleMedium));
                    }
                    if (!snapshot.hasData ||
                        snapshot.data!.snapshot.value == null) {
                      return Center(
                          child: Text('No tienes notificaciones.',
                              style: Theme.of(context).textTheme.titleMedium));
                    }

                    final notificationsMap = Map<String, dynamic>.from(
                        snapshot.data!.snapshot.value as Map);
                    final notifications = notificationsMap.entries.map((entry) {
                      final notification =
                          Map<String, dynamic>.from(entry.value as Map);
                      notification['id'] = entry.key;
                      return notification;
                    }).toList();

                    notifications.sort((a, b) =>
                        (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

                    return ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final timestamp = notification['timestamp'] != null
                            ? DateTime.fromMillisecondsSinceEpoch(
                                notification['timestamp'])
                            : null;
                        final formattedDate = timestamp != null
                            ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp)
                            : 'Fecha desconocida';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification['message'] ?? 'Sin mensaje.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      formattedDate,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              fontStyle: FontStyle.italic),
                                    ),
                                    const Spacer(),
                                    if (_currentUserModel != null)
                                      OutlinedButton(
                                        onPressed: _navigateToSupportChat,
                                        child: const Text('Responder'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
    );
  }
}
