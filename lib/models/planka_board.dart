import 'package:planka_app/models/planka_user.dart';

class PlankaBoard {
  String id;
  String name;
  num position;
  List<PlankaUser> users;  // List of users assigned to the board

  PlankaBoard({
    required this.id,
    required this.name,
    required this.users,
    required this.position,
  });

  // Factory to convert JSON response into PlankaBoard object
  factory PlankaBoard.fromJson(Map<String, dynamic> json, Map<String, dynamic> included) {
    List<PlankaUser> users = [];

    // Extract users
    if (included.containsKey('users') && included['users'] is List) {
      users = (included['users'] as List)
          .cast<Map<String, dynamic>>()  // Ensure correct type
          .map((userJson) => PlankaUser.fromJson(userJson))
          .toList();
    }

    return PlankaBoard(
      id: json['id'],
      name: json['name'],
      position: json['position'],
      users: users,
    );
  }
}