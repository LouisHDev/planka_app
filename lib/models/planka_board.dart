import 'package:planka_app/models/planka_user.dart';

class PlankaBoard {
  String id;
  String name;
  num position;
  List<PlankaUser>? users;

  PlankaBoard({
    required this.id,
    required this.name,
    required this.users,
    required this.position
  });

  factory PlankaBoard.fromJson(Map<String, dynamic> json, Map<String, dynamic> included) {
    List<PlankaUser> users = [];

    if (included.containsKey('users') && included['users'] is List) {
      users = (included['users'] as List).map((userJson) {
        return PlankaUser.fromJson(userJson);
      }).toList();
    }

    return PlankaBoard(
      id: json['id'],
      name: json['name'],
      position: json['position'],
      users: users,
    );
  }
}
