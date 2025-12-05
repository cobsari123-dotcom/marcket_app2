import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/models/publication.dart';
import 'package:marcket_app/models/product.dart';
import 'package:marcket_app/models/chat_room.dart';
import 'package:marcket_app/screens/seller/product_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marcket_app/widgets/product_card.dart';
import 'package:marcket_app/widgets/publication_card.dart';

class PublicSellerProfileScreen extends StatefulWidget {
  final String sellerId;
  final bool isAdmin;

  const PublicSellerProfileScreen({super.key, required this.sellerId, this.isAdmin = false});

  @override
  State<PublicSellerProfileScreen> createState() =>
      PublicSellerProfileScreenState();
}

class PublicSellerProfileScreenState extends State<PublicSellerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserModel? _seller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSellerData();
  }

  Future<void> _loadSellerData() async {
    final snapshot = await FirebaseDatabase.instance
        .ref('users/${widget.sellerId}')
        .get();
    if (snapshot.exists && mounted) {
      setState(() {
        _seller = UserModel.fromMap(
          Map<String, dynamic>.from(snapshot.value as Map),
          snapshot.key!,
        );
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _navigateToChat() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, inicia sesión para chatear.')),
      );
      return;
    }

    if (currentUser.uid == widget.sellerId) {
      if (!mounted) return;
      Navigator.pushNamed(context, '/chat_list');
      return;
    }

    final currentUserSnapshot = await FirebaseDatabase.instance
        .ref('users/${currentUser.uid}')
        .get();
    if (!currentUserSnapshot.exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo encontrar tu perfil de usuario.'),
        ),
      );
      return;
    }
    final currentUserModel = UserModel.fromMap(
      Map<String, dynamic>.from(currentUserSnapshot.value as Map),
      currentUserSnapshot.key!,
    );

    final chatRoomId = _getChatRoomId(currentUser.uid, widget.sellerId);
    final chatRoomRef = FirebaseDatabase.instance.ref('chat_rooms/$chatRoomId');

    DataSnapshot snapshot = await chatRoomRef.get();
    if (!snapshot.exists) {
      final newChatRoom = ChatRoom(
        id: chatRoomId,
        participants: {currentUser.uid: true, widget.sellerId: true},
        lastMessage: 'Chat iniciado.',
        lastMessageTimestamp: DateTime.now(),
        participantInfo: {
          currentUser.uid: {
            'fullName': currentUserModel.fullName,
            'profilePicture': currentUserModel.profilePicture,
          },
          widget.sellerId: {
            'fullName': _seller?.fullName,
            'profilePicture': _seller?.profilePicture,
          },
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
        'otherUserName': _seller?.fullName ?? 'Vendedor',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_seller?.fullName ?? 'Perfil del Vendedor'),
        actions: [
          if (_seller != null)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: _navigateToChat,
              tooltip: 'Contactar al vendedor',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.article), text: 'Publicaciones'),
            Tab(icon: Icon(Icons.store), text: 'Productos'),
            Tab(icon: Icon(Icons.person), text: 'Perfil'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withAlpha(178),
        ),
      ),
      body: _seller == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                PublicPublicationsList(
                  sellerId: widget.sellerId,
                  sellerName: _seller?.fullName ?? 'Vendedor',
                  sellerProfilePicture: _seller?.profilePicture,
                  isAdmin: widget.isAdmin,
                ),
                PublicProductsList(sellerId: widget.sellerId, isAdmin: widget.isAdmin),
                SellerProfileInfoTab(seller: _seller!),
              ],
            ),
    );
  }

  String _getChatRoomId(String userId1, String userId2) {
    if (userId1.compareTo(userId2) > 0) {
      return '$userId1-$userId2';
    } else {
      return '$userId2-$userId1';
    }
  }
}

class SellerProfileInfoTab extends StatelessWidget {
  final UserModel seller;

  const SellerProfileInfoTab({super.key, required this.seller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (seller.businessName != null && seller.businessName!.isNotEmpty) ...[
            Text(
              seller.businessName!,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
          ],
          Text(
            seller.fullName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.email),
            title: Text(seller.email),
          ),
          if (seller.phoneNumber != null)
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text(seller.phoneNumber!),
            ),
          if (seller.businessAddress != null)
            ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(seller.businessAddress!),
            ),
        ],
      ),
    );
  }
}


// CORREGIDO: Renombrado para evitar advertencia de linter (sin guion bajo si es usada fuera)
int getCrossAxisCount(double screenWidth) {
  if (screenWidth > 1200) {
    return 5;
  } else if (screenWidth > 900) {
    return 4;
  } else if (screenWidth > 600) {
    return 3;
  } else {
    return 2;
  }
}

class PublicPublicationsList extends StatelessWidget {
  final String sellerId;
  final String sellerName;
  final String? sellerProfilePicture;
  final bool isAdmin;

  const PublicPublicationsList({
    super.key,
    required this.sellerId,
    required this.sellerName,
    this.sellerProfilePicture,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final database = FirebaseDatabase.instance.ref();
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = getCrossAxisCount(
      screenWidth,
    ); // Usando nombre corregido

    return StreamBuilder(
      stream: database
          .child('publications')
          .orderByChild('sellerId')
          .equalTo(sellerId)
          .onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return Center(
            child: Text(
              'Este vendedor aún no tiene publicaciones.',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
          );
        }

        final data = Map<String, dynamic>.from(
          snapshot.data!.snapshot.value as Map,
        );
        final publications = data.entries.map((entry) {
          return Publication.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
            entry.key,
          );
        }).toList();
        publications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.75,
          ),
          itemCount: publications.length,
          itemBuilder: (context, index) {
            final publication = publications[index];
            return PublicationCard(
              publication: publication,
              sellerName: sellerName,
              sellerProfilePicture: sellerProfilePicture,
              isAdmin: isAdmin,
              onSellerTap: null,
            );
          },
        );
      },
    );
  }
}

class PublicProductsList extends StatelessWidget {
  final String sellerId;
  final bool isAdmin;

  const PublicProductsList({super.key, required this.sellerId, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    final database = FirebaseDatabase.instance.ref();
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = getCrossAxisCount(
      screenWidth,
    ); // Usando nombre corregido

    return StreamBuilder(
      stream: database.child('products').child(sellerId).onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return Center(
            child: Text(
              'Este vendedor aún no tiene productos.',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
          );
        }

        final data = Map<String, dynamic>.from(
          snapshot.data!.snapshot.value as Map,
        );
        final products = data.entries.map((entry) {
          return Product.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
            entry.key,
            sellerIdParam: sellerId,
          );
        }).toList();

        return GridView.builder(
          padding: const EdgeInsets.all(12.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCard(
              product: product,
              isAdmin: isAdmin,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProductDetailsScreen(product: product, isAdmin: isAdmin),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
