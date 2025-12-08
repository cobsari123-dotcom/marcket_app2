import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/user.dart';

class UserListTab extends StatefulWidget {
  final Stream<DatabaseEvent> stream;
  final Function(UserModel) onUserTap;
  final String currentUserId;

  const UserListTab({
    super.key,
    required this.stream,
    required this.onUserTap,
    required this.currentUserId,
  });

  @override
  UserListTabState createState() => UserListTabState();
}

class UserListTabState extends State<UserListTab>
    with AutomaticKeepAliveClientMixin {
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
          return const Center(child: Text('No hay usuarios registrados.'));
        }

        final usersData =
            Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        final users = usersData.entries
            .map((entry) {
              return UserModel.fromMap(
                  Map<String, dynamic>.from(entry.value as Map), entry.key);
            })
            .where((user) => user.id != widget.currentUserId)
            .toList();

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: user.profilePicture != null
                    ? NetworkImage(user.profilePicture!)
                    : null,
                child: user.profilePicture == null
                    ? Icon(
                        user.userType == 'Seller' ? Icons.store : Icons.person)
                    : null,
              ),
              title: Text(user.fullName),
              subtitle: Text(user.businessName ?? user.userType),
              onTap: () => widget.onUserTap(user),
            );
          },
        );
      },
    );
  }
}
