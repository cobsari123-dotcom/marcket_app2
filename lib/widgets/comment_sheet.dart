import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marcket_app/models/comment.dart';
import 'package:marcket_app/services/publication_service.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:intl/intl.dart';

class CommentSheet extends StatefulWidget {
  final String publicationId;

  const CommentSheet({super.key, required this.publicationId});

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  final PublicationService _publicationService = PublicationService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  File? _imageFile;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _postComment() {
    if (_commentController.text.trim().isEmpty && _imageFile == null) {
      return;
    }
    if (_currentUserId == null) return;

    setState(() {
      _isUploading = true;
    });

    _publicationService.addComment(
      publicationId: widget.publicationId,
      commentText: _commentController.text.trim(),
      imageFile: _imageFile,
    ).then((_) {
      _commentController.clear();
      setState(() {
        _imageFile = null;
        _isUploading = false;
      });
    }).catchError((error) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al publicar el comentario: $error'), backgroundColor: AppTheme.error),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) {
          return Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Comentarios', style: Theme.of(context).textTheme.titleLarge),
              ),
              const Divider(),
              // Comments List
              Expanded(
                child: StreamBuilder(
                  stream: _publicationService.getCommentsStream(widget.publicationId),
                  builder: (context, AsyncSnapshot<List<Comment>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No hay comentarios aún. ¡Sé el primero!'));
                    }
                    final comments = snapshot.data!;
                    return ListView.builder(
                      controller: controller,
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(comment.userImageUrl),
                          ),
                          title: Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(comment.comment),
                              if (comment.imageUrl != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Image.network(comment.imageUrl!),
                                ),
                            ],
                          ),
                          trailing: Text(
                            DateFormat('dd/MM HH:mm').format(comment.timestamp),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Input Area
              _buildCommentInput(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_imageFile != null)
            Stack(
              children: [
                Image.file(_imageFile!, height: 100),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _imageFile = null),
                  ),
                ),
              ],
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.photo_camera),
                onPressed: _pickImage,
              ),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration.collapsed(hintText: 'Añadir un comentario...'),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              IconButton(
                icon: _isUploading ? const CircularProgressIndicator() : const Icon(Icons.send),
                onPressed: (_isUploading || (_commentController.text.trim().isEmpty && _imageFile == null))
                    ? null
                    : _postComment,
                color: AppTheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
