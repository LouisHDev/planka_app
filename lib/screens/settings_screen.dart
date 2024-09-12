import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:planka_app/models/planka_user.dart';
import 'package:planka_app/providers/user_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr()),
      ),
      body: FutureBuilder(
        future: userProvider.fetchUsers(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('${'error'.tr()}: ${snapshot.error}'));
          } else {
            List<PlankaUser> users = userProvider.users;
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (ctx, index) {
                return ListTile(
                  title: Text(users[index].name),
                  subtitle: Text(users[index].email),
                  leading: _buildAvatar(users[index].avatarUrl),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[300], // Grey color for placeholder
        ),
        child: const Center(
          child: Icon(Icons.person)
        ),
      );
    } else {
      // If user has an avatar, return Image.network widget
      return CircleAvatar(
        backgroundImage: NetworkImage(avatarUrl),
      );
    }
  }
}
