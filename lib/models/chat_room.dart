class ChatRoom {
  final String id;
  final Map<String, bool> participants;
  final String lastMessage;
  final DateTime lastMessageTimestamp;
  final Map<String, Map<String, String?>> participantInfo;

  const ChatRoom({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTimestamp,
    required this.participantInfo,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map, String id) {
    // Handling participantInfo with proper type checking
    final infoFromMap = map['participantInfo'];
    final Map<String, Map<String, String?>> participantInfo = {};
    if (infoFromMap is Map) {
      infoFromMap.forEach((key, value) {
        if (value is Map) {
          participantInfo[key.toString()] = {
            'fullName': value['fullName'] as String?,
            'profilePicture': value['profilePicture'] as String?,
          };
        }
      });
    }

    return ChatRoom(
      id: id,
      participants: Map<String, bool>.from(map['participants'] ?? {}),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTimestamp: DateTime.fromMillisecondsSinceEpoch((map['lastMessageTimestamp'] as num? ?? 0).toInt()),
      participantInfo: participantInfo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp.millisecondsSinceEpoch,
      'participantInfo': participantInfo,
    };
  }
}

