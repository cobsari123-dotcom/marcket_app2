import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:marcket_app/models/chat_room.dart';
import 'package:marcket_app/screens/common/complaint_suggestion_screen.dart';
import 'package:marcket_app/screens/common/faq_screen.dart';
import 'package:marcket_app/screens/common/my_complaints_screen.dart';
import 'package:marcket_app/screens/common/terms_of_service_screen.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/user.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  UserModel? _currentUserModel;
  bool _isLoading = true; // Variable para controlar el estado de carga

  @override
  void initState() {
    super.initState();
    _loadCurrentUserModel();
  }

  Future<void> _loadCurrentUserModel() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseDatabase.instance
            .ref('users/${user.uid}')
            .get();
        if (snapshot.exists && mounted) {
          setState(() {
            _currentUserModel = UserModel.fromMap(
              Map<String, dynamic>.from(snapshot.value as Map),
              user.uid,
            );
            _isLoading = false;
          });
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      } catch (e) {
        // En caso de error, dejamos de cargar para no bloquear la pantalla
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // CORRECCIÓN AQUI: Usamos _isLoading para decidir qué mostrar
    return _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 900,
                ), // Limit overall width for larger screens
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent:
                                  300, // Maximum width of each item
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio:
                                  1.0, // Adjust as needed to prevent overflow
                            ),
                        itemCount:
                            5, // Number of support cards (feedback, complaints, chat, faq, terms)
                        itemBuilder: (context, index) {
                          switch (index) {
                            case 0:
                              return _buildSupportCard(
                                context,
                                icon: Icons.feedback,
                                title: 'Buzón de Quejas y Sugerencias',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ComplaintSuggestionScreen(),
                                    ),
                                  );
                                },
                              );
                            case 1:
                              return _buildSupportCard(
                                context,
                                icon: Icons.history,
                                title: 'Mis Quejas y Sugerencias',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const MyComplaintsScreen(),
                                    ),
                                  );
                                },
                              );
                            case 2:
                              return _buildSupportCard(
                                context,
                                icon: Icons.chat,
                                title: 'Chat en Línea con Administrador',
                                onTap: () async {
                                  final user =
                                      FirebaseAuth.instance.currentUser;

                                  // Verificaciones de seguridad
                                  if (user == null) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Debes iniciar sesión para chatear con soporte.',
                                        ),
                                        backgroundColor: AppTheme.error,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                    return;
                                  }

                                  if (_currentUserModel == null) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No se pudo cargar tu perfil. Intenta reiniciar la app.',
                                        ),
                                        backgroundColor: AppTheme.error,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                    return;
                                  }

                                  const supportId = 'support_admin_user';

                                  final database = FirebaseDatabase.instance
                                      .ref();
                                  final currentUserSnapshot = await database
                                      .child('users/${user.uid}')
                                      .get();

                                  if (!currentUserSnapshot.exists) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No se pudo obtener la información del usuario.',
                                        ),
                                        backgroundColor: AppTheme.error,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                    return;
                                  }

                                  final chatRoomId = _getChatRoomId(
                                    user.uid,
                                    supportId,
                                  );
                                  final chatRoomRef = FirebaseDatabase.instance
                                      .ref('chat_rooms/$chatRoomId');

                                  final snapshot = await chatRoomRef.get();
                                  if (!snapshot.exists) {
                                    final newChatRoomData = ChatRoom(
                                      id: chatRoomId,
                                      participants: {
                                        user.uid: true,
                                        supportId: true,
                                      },
                                      lastMessage: 'Chat iniciado.',
                                      lastMessageTimestamp: DateTime.now(),
                                      participantInfo: {
                                        user.uid: {
                                          'fullName':
                                              _currentUserModel!.fullName,
                                          'profilePicture':
                                              _currentUserModel!.profilePicture,
                                        },
                                        supportId: {
                                          'fullName':
                                              'Soporte de Manos del Mar',
                                          'profilePicture': null,
                                        },
                                      },
                                    );
                                    await chatRoomRef.set(
                                      newChatRoomData.toMap(),
                                    );
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
                                }, // <--- AQUI FALTABA ESTA LLAVE DE CIERRE
                              );
                            case 3:
                              return _buildSupportCard(
                                context,
                                icon: Icons.quiz,
                                title: 'Preguntas Frecuentes (FAQ)',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const FaqScreen(),
                                    ),
                                  );
                                },
                              );
                            case 4:
                              return _buildSupportCard(
                                context,
                                icon: Icons.description,
                                title: 'Términos de Servicio',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const TermsOfServiceScreen(),
                                    ),
                                  );
                                },
                              );
                            default:
                              return Container(); // Should not happen
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Para consultas urgentes, por favor, contáctanos directamente a:',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'soporte@marcketapp.com', // Placeholder email
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              FontAwesomeIcons.facebook,
                              color: AppTheme.primary,
                            ),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(
                              FontAwesomeIcons.instagram,
                              color: AppTheme.primary,
                            ),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(
                              FontAwesomeIcons.tiktok,
                              color: AppTheme.primary,
                            ),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(
                              FontAwesomeIcons.whatsapp,
                              color: AppTheme.primary,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
  }

  Widget _buildSupportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: AppTheme.primary),
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getChatRoomId(String userId1, String userId2) {
    const supportAdminId = 'support_admin_user';
    // Asegurar que el ID del chat con soporte siempre empiece con support_admin_user
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
