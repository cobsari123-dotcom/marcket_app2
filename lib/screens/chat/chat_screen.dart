import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:marcket_app/models/chat_message.dart';
import 'package:marcket_app/utils/theme.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String otherUserName;
  final String? initialMessage; // New optional parameter

  const ChatScreen(
      {super.key,
      required this.chatRoomId,
      required this.otherUserName,
      this.initialMessage});

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final _database = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;
  final _messageController = TextEditingController();
  bool _isUploading = false;
  File? _imageFile;
  File? _docFile;
  Stream<DatabaseEvent>? _messagesStream; // Declare the stream here

  @override
  void initState() {
    super.initState();
    _messagesStream = _database
        .child('chat_rooms/${widget.chatRoomId}/messages')
        .orderByChild('timestamp')
        .onValue
        .asBroadcastStream();
    _handleInitialMessage();
  }

  Future<void> _handleInitialMessage() async {
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      final snapshot = await _database
          .child('chat_rooms/${widget.chatRoomId}/messages')
          .get();
      if (!snapshot.exists || snapshot.children.isEmpty) {
        // Check if chat is truly empty
        // Delay sending to ensure UI is built and current user is available
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _sendMessage(text: widget.initialMessage!);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate.isAtSameMomentAs(today)) {
      return DateFormat('HH:mm').format(timestamp);
    } else {
      return DateFormat('dd/MM HH:mm').format(timestamp);
    }
  }

  Future<void> _sendMessage(
      {String text = '', String messageType = 'text', String? mediaUrl}) async {
    if (text.trim().isEmpty &&
        mediaUrl == null &&
        _imageFile == null &&
        _docFile == null) {
      return;
    }

    if (mounted) setState(() => _isUploading = true);

    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isUploading = false);
      return;
    }

    String? finalMediaUrl = mediaUrl;
    String finalMessageType = messageType;
    String lastMessageText = text.trim();

    try {
      if (_imageFile != null) {
        const fileExtension = 'jpg';
        const storagePath = 'chat_images';
        final storageRef = FirebaseStorage.instance.ref().child(storagePath).child(
            '${widget.chatRoomId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension');

        final Uint8List imageData = await _imageFile!.readAsBytes();
        final metadata = SettableMetadata(contentType: "image/jpeg");
        final uploadTask = storageRef.putData(imageData, metadata);

        final snapshot = await uploadTask;
        finalMediaUrl = await snapshot.ref.getDownloadURL();
        finalMessageType = 'image';
        lastMessageText = '[Imagen]';
      } else if (_docFile != null) {
        // ignore: prefer_const_declarations
        final fileExtension = text.split('.').last;
        const storagePath = 'chat_files';
        final storageRef = FirebaseStorage.instance.ref().child(storagePath).child(
            '${widget.chatRoomId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension');

        final uploadTask = storageRef.putFile(_docFile!);
        final snapshot = await uploadTask;
        finalMediaUrl = await snapshot.ref.getDownloadURL();
        finalMessageType = 'file';
        lastMessageText = '[Archivo] $text';
      }

      final newMessageRef =
          _database.child('chat_rooms/${widget.chatRoomId}/messages').push();
      final message = ChatMessage(
        id: newMessageRef.key!,
        senderId: user.uid,
        text: text.trim(),
        messageType: finalMessageType,
        mediaUrl: finalMediaUrl,
        timestamp: DateTime.now(),
      );

      await newMessageRef.set(message.toMap());

      await _database.child('chat_rooms/${widget.chatRoomId}').update({
        'lastMessage': lastMessageText,
        'lastMessageTimestamp': message.timestamp.millisecondsSinceEpoch,
      });

      if (mounted) {
        _messageController.clear();
        setState(() {
          _imageFile = null;
          _docFile = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al enviar el mensaje: $e'),
              backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile == null || !mounted) return;

    setState(() {
      _imageFile = File(pickedFile.path);
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _docFile = File(result.files.single.path!);
        _sendMessage(text: result.files.single.name, messageType: 'file');
      });
    }
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería de Fotos'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Tomar Foto'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Documento'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        // Removed automaticallyImplyLeading: false to show the back button
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              maxWidth: 800), // Limit width for chat content
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder(
                  stream: _messagesStream,
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData ||
                        snapshot.data!.snapshot.value == null) {
                      return const Center(child: Text('Aún no hay mensajes.'));
                    }

                    final messagesData = Map<String, dynamic>.from(
                        snapshot.data!.snapshot.value as Map);
                    final messages = messagesData.entries.map((entry) {
                      return ChatMessage.fromMap(
                          Map<String, dynamic>.from(entry.value as Map),
                          entry.key);
                    }).toList();
                    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

                    return ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == _auth.currentUser!.uid;
                        return _buildMessageBubble(message, isMe);
                      },
                    );
                  },
                ),
              ),
              _buildMessageInputField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final color = isMe ? AppTheme.primary : AppTheme.surface;
    final textColor = isMe ? Colors.white : Colors.black;

    Widget messageContent;
    switch (message.messageType) {
      case 'image':
        messageContent = ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            message.mediaUrl!,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : const CircularProgressIndicator(),
          ),
        );
        break;
      case 'file':
        messageContent = InkWell(
          onTap: () async {
            if (message.mediaUrl != null) {
              final uri = Uri.parse(message.mediaUrl!);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file, color: textColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.text, // File name is stored in the text field
                  style: TextStyle(
                      color: textColor, decoration: TextDecoration.underline),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
        break;
      default: // text
        messageContent = Text(message.text, style: TextStyle(color: textColor));
    }

    return Align(
      alignment: alignment,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            messageContent,
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                _formatTimestamp(message.timestamp),
                style: TextStyle(color: textColor.withAlpha(178), fontSize: 10),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25), // Fixed deprecated
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_imageFile != null)
            Stack(
              children: [
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    image: DecorationImage(
                      image: FileImage(_imageFile!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => setState(() => _imageFile = null),
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file, color: AppTheme.primary),
                onPressed: _showAttachmentMenu,
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (text) => _sendMessage(text: text),
                ),
              ),
              _isUploading
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator())
                  : IconButton(
                      icon: const Icon(Icons.send, color: AppTheme.primary),
                      onPressed: () =>
                          _sendMessage(text: _messageController.text),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
