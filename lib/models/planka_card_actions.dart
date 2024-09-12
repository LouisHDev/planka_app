import 'package:planka_app/models/planka_user.dart';

class PlankaCardAction {
  final String id;
  final String createdAt;
  final String? updatedAt;
  final String type;
  final PlankaCardActionData data;
  final String cardId;
  final String userId;
  final PlankaUser? user;

  PlankaCardAction({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.type,
    required this.data,
    required this.cardId,
    required this.userId,
    this.user,
  });

  factory PlankaCardAction.fromJson(Map<String, dynamic> json, Map<String, dynamic> included) {
    PlankaUser? user;
    if (included.containsKey('users')) {
      user = (included['users'] as List)
          .map((userJson) => PlankaUser.fromJson(userJson))
          .firstWhere((u) => u.id == json['userId'], orElse: () => PlankaUser(id: "id", email: "email", name: "name", username: "username"));
    }

    return PlankaCardAction(
      id: json['id'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      type: json['type'],
      data: PlankaCardActionData.fromJson(json['data']),
      cardId: json['cardId'],
      userId: json['userId'],
      user: user,
    );
  }
}

class PlankaCardActionData {
  final String text;

  PlankaCardActionData({required this.text});

  factory PlankaCardActionData.fromJson(Map<String, dynamic> json) {
    return PlankaCardActionData(
      text: json['text'],
    );
  }
}

class PlankaCardActionsResponse {
  final List<PlankaCardAction> actions;
  final List<PlankaUser> users;

  PlankaCardActionsResponse({
    required this.actions,
    required this.users,
  });

  factory PlankaCardActionsResponse.fromJson(Map<String, dynamic> json) {
    List<PlankaCardAction> actions = (json['items'] as List).map((actionJson) {
      return PlankaCardAction.fromJson(actionJson, json['included']);
    }).toList();

    List<PlankaUser> users = [];
    if (json['included'].containsKey('users')) {
      users = (json['included']['users'] as List)
          .map((userJson) => PlankaUser.fromJson(userJson))
          .toList();
    }

    return PlankaCardActionsResponse(
      actions: actions,
      users: users,
    );
  }
}