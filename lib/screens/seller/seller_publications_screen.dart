import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/publication.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:marcket_app/widgets/publication_card.dart';

class SellerPublicationsScreen extends StatefulWidget {
  final String? title;
  const SellerPublicationsScreen({super.key, this.title});

  @override
  SellerPublicationsScreenState createState() =>
      SellerPublicationsScreenState();
}

class SellerPublicationsScreenState extends State<SellerPublicationsScreen> {
  final _database = FirebaseDatabase.instance.ref();
  final _userId = FirebaseAuth.instance.currentUser!.uid;
  String _sellerName = 'Mi Perfil';
  String? _sellerProfilePicture;

  @override
  void initState() {
    super.initState();
    _loadSellerData();
  }

  Future<void> _loadSellerData() async {
    final snapshot = await _database.child('users/$_userId').get();
    if (snapshot.exists && mounted) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _sellerName = data['fullName'] ?? 'Mi Perfil';
        _sellerProfilePicture = data['profilePicture'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.title!,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        Expanded(
          child: StreamBuilder(
            stream: _database
                .child('publications')
                .orderByChild('sellerId')
                .equalTo(_userId)
                .onValue,
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.article_outlined,
                        size: 80,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Aún no tienes publicaciones.',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Usa el botón "+" para crear una nueva historia.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
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

              return LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  int crossAxisCount;
                  if (screenWidth > 1200) {
                    crossAxisCount = 5;
                  } else if (screenWidth > 900) {
                    crossAxisCount = 4;
                  } else if (screenWidth > 600) {
                    crossAxisCount = 3;
                  } else {
                    crossAxisCount = 2;
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 0.70,
                    ),
                    itemCount: publications.length,
                    itemBuilder: (context, index) {
                      final publication = publications[index];
                      return PublicationCard(
                        publication: publication,
                        sellerName: _sellerName,
                        sellerProfilePicture: _sellerProfilePicture,
                        onSellerTap: () {},
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
