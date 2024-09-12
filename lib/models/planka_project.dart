import 'package:planka_app/models/planka_board.dart';
import 'package:planka_app/models/planka_user.dart';

class PlankaProject {
  final String id;
  final String name;
  final List<PlankaBoard> boards;
  final List<PlankaUser> users;
  final Map<String, dynamic>? background;
  final Map<String, dynamic>? backgroundImage;

  PlankaProject({
    required this.id,
    required this.name,
    required this.boards,
    required this.users,
    this.background,
    this.backgroundImage,
  });

  factory PlankaProject.fromJson(Map<String, dynamic> json, Map<String, dynamic> included) {
    List<PlankaBoard> boards = [];
    if (included.containsKey('boards') && included['boards'] is List) {
      boards = (included['boards'] as List).map((boardJson) {
        return PlankaBoard.fromJson(boardJson, included);
      }).toList();
    }

    List<PlankaUser> users = [];
    if (included.containsKey('users') && included['users'] is List) {
      users = (included['users'] as List).map((userJson) {
        return PlankaUser.fromJson(userJson);
      }).toList();
    }

    return PlankaProject(
      id: json['id'],
      name: json['name'],
      boards: boards,
      users: users,
      background: json['background'],
      backgroundImage: json['backgroundImage'],
    );
  }
}