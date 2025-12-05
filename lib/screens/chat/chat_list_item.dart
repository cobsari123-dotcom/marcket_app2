import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Necesario para borrar
import 'package:marcket_app/models/chat_room.dart';
import 'package:marcket_app/screens/chat/chat_screen.dart';
import 'package:intl/intl.dart';

class ChatListItem extends StatelessWidget {
  final ChatRoom chatRoom;
  final String currentUserId;

  const ChatListItem({
    super.key,
    required this.chatRoom,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    // Protección contra datos incompletos en participants
    final otherUserId = chatRoom.participants.keys.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    // Si no hay otro usuario válido, no mostramos nada para evitar errores visuales
    if (otherUserId.isEmpty) {
      return const SizedBox.shrink();
    }

    final otherUserInfo = chatRoom.participantInfo[otherUserId];
    final otherUserName = otherUserInfo?['fullName'] ?? 'Usuario';
    final otherUserProfilePicture = otherUserInfo?['profilePicture'];

    final formattedTime = DateFormat('HH:mm').format(chatRoom.lastMessageTimestamp);

    // ENVOLVEMOS EN DISMISSIBLE PARA PERMITIR DESLIZAR
    return Dismissible(
      // LA CLAVE ES CRÍTICA: Debe ser única para evitar el crash "Element not in tree"
      key: ValueKey(chatRoom.id),
      direction:
          DismissDirection.endToStart, // Solo deslizar de derecha a izquierda
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        // Opcional: Confirmar antes de borrar
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirmar"),
              content: const Text("¿Quieres eliminar este chat de tu lista?"),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    "Eliminar",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        // LÓGICA DE BORRADO SEGURA
        // No borramos todo el chat (para no afectarle al otro usuario),
        // solo quitamos al usuario actual de la lista de participantes.
        // Gracias al query en chat_list_screen, el chat desaparecerá de tu lista.
        FirebaseDatabase.instance
            .ref('chat_rooms/${chatRoom.id}/participants/$currentUserId')
            .remove();

        // Feedback visual
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat eliminado de tu lista')),
        );
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: otherUserProfilePicture != null
              ? NetworkImage(otherUserProfilePicture)
              : null,
          child: otherUserProfilePicture == null
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(otherUserName),
        subtitle: Text(
          chatRoom.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(formattedTime),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatRoomId: chatRoom.id,
                otherUserName: otherUserName,
              ),
            ),
          );
        },
      ),
    );
  }
}
