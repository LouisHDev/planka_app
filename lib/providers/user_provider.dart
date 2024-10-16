import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:planka_app/models/planka_user.dart';
import 'dart:convert';
import 'auth_provider.dart';

class UserProvider with ChangeNotifier {
  final List<PlankaUser> _users = [];
  PlankaUser _specificUser = PlankaUser(id: "id", email: "email", name: "name", username: "username");
  final AuthProvider authProvider;

  UserProvider(this.authProvider);

  List<PlankaUser> get users => _users;
  PlankaUser get specificUser => _specificUser;

  Future<void> fetchUsers() async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/users/');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final usersData = responseData['items'] as List<dynamic>;

        _users.clear();

        for (var userData in usersData) {
          PlankaUser user = PlankaUser(
            id: userData['id'],
            createdAt: userData['createdAt'],
            updatedAt: userData['updatedAt'],
            email: userData['email'],
            isAdmin: userData['isAdmin'],
            name: userData['name'],
            username: userData['username'],
            organization: userData['organization'],
            subscribeToOwnCards: userData['subscribeToOwnCards'],
            isLocked: userData['isLocked'],
            isRoleLocked: userData['isRoleLocked'],
            isUsernameLocked: userData['isUsernameLocked'],
            isDeletionLocked: userData['isDeletionLocked'],
            avatarUrl: userData['avatarUrl'],
          );
          _users.add(user);
        }

        notifyListeners();
      } else {
        debugPrint('Failed to load users: ${response.statusCode}');
        throw Exception('Failed to load users');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to load users');
    }
  }

  Future<void> fetchSpecificUser(String userId) async {
    final url = Uri.parse('${authProvider.selectedProtocol}://${authProvider.domain}/api/users/$userId');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);

        _specificUser = PlankaUser(
          id: userData['id'],
          createdAt: userData['createdAt'],
          updatedAt: userData['updatedAt'],
          email: userData['email'],
          isAdmin: userData['isAdmin'],
          name: userData['name'],
          username: userData['username'],
          organization: userData['organization'],
          subscribeToOwnCards: userData['subscribeToOwnCards'],
          isLocked: userData['isLocked'],
          isRoleLocked: userData['isRoleLocked'],
          isUsernameLocked: userData['isUsernameLocked'],
          isDeletionLocked: userData['isDeletionLocked'],
          avatarUrl: userData['avatarUrl'],
        );

        notifyListeners();
      } else {
        debugPrint('Failed to load user: ${response.statusCode}');
        throw Exception('Failed to load user');
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to load user');
    }
  }
}
