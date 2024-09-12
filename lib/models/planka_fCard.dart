import 'package:planka_app/models/card_models/planka_card_membership.dart';

import 'card_models/planka_attachment.dart';
import 'card_models/planka_task.dart';

class PlankaFullCard {
  String id;
  String name;
  String listId;
  String? description;
  String? boardId;
  String? creatorUserId;
  String? createdAt;
  String? updatedAt;
  String? dueDate;
  bool? isSubscribed;
  List<PlankaCardMembership>? cardMemberships;
  List<CardLabel>? cardLabels;
  List<PlankaAttachment>? attachments;
  List<PlankaTask>? tasks;

  ///Stopwatch
  int? stopwatchTotal;
  DateTime? stopwatchStartedAt;

  PlankaFullCard({
    required this.id,
    required this.name,
    required this.listId,
    this.description,
    this.boardId,
    this.creatorUserId,
    this.createdAt,
    this.updatedAt,
    this.dueDate,
    this.isSubscribed,
    this.cardMemberships,
    this.cardLabels,
    this.attachments,
    this.tasks,
    this.stopwatchTotal,
    this.stopwatchStartedAt,
  });

  factory PlankaFullCard.fromJson(Map<String, dynamic> json) {
    // Extract item data
    final itemData = json['item'];

    // Extract included data if available
    final included = json['included'];

    List<PlankaAttachment>? attachments;
    List<PlankaTask>? tasks;
    List<CardLabel>? cardLabels;
    List<PlankaCardMembership>? cardMemberships;

    // Check if included exists and contains tasks
    if (included != null) {

      ///Attachments
      if (included.containsKey('attachments') && included['attachments'] is List) {
        attachments = (included['attachments'] as List).map((attachmentJson) {
          return PlankaAttachment.fromJson(attachmentJson as Map<String, dynamic>);
        }).toList();
      }

      ///Tasks
      if (included.containsKey('tasks') && included['tasks'] is List) {
        tasks = (included['tasks'] as List).map((taskJson) {
          return PlankaTask.fromJson(taskJson as Map<String, dynamic>);
        }).toList();
      }

      ///Labels
      if (included.containsKey('cardLabels') && included['cardLabels'] is List) {
        cardLabels = (included['cardLabels'] as List).map((labelJson) {
          return CardLabel.fromJson(labelJson as Map<String, dynamic>);
        }).toList();
      }

      ///Card Memberships
      if (included.containsKey('cardMemberships') && included['cardMemberships'] is List) {
        cardMemberships = (included['cardMemberships'] as List).map((membershipJson) {
          return PlankaCardMembership.fromJson(membershipJson as Map<String, dynamic>);
        }).toList();
      }
    }

    return PlankaFullCard(
      id: itemData['id'] as String,
      name: itemData['name'] as String,
      listId: itemData['listId'] as String,
      description: itemData['description'] as String?,
      boardId: itemData['boardId'] as String?,
      creatorUserId: itemData['creatorUserId'] as String?,
      createdAt: itemData['createdAt'] as String?,
      updatedAt: itemData['updatedAt'] as String?,
      dueDate: itemData['dueDate'] as String?,
      isSubscribed: itemData['isSubscribed'] as bool?,
      attachments: attachments,
      tasks: tasks,
      cardLabels: cardLabels,
      stopwatchTotal: itemData['stopwatch']?['total'],
      stopwatchStartedAt: itemData['stopwatch']?['startedAt'] != null
          ? DateTime.parse(itemData['stopwatch']['startedAt'])
          : null,
      cardMemberships: cardMemberships
    );
  }
}

// class CardMembership {
//   String id;
//   String? createdAt;
//   String? updatedAt;
//   String cardId;
//   String userId;
//
//   CardMembership({
//     required this.id,
//     this.createdAt,
//     this.updatedAt,
//     required this.cardId,
//     required this.userId,
//   });
//
//   factory CardMembership.fromJson(Map<String, dynamic> json) {
//     return CardMembership(
//       id: json['id'] as String,
//       createdAt: json['createdAt'] as String?,
//       updatedAt: json['updatedAt'] as String?,
//       cardId: json['cardId'] as String,
//       userId: json['userId'] as String,
//     );
//   }
// }

class CardLabel {
  String? id;
  String? createdAt;
  String? updatedAt;
  String? cardId;
  String? labelId;

  CardLabel({
    this.id,
    this.createdAt,
    this.updatedAt,
    this.cardId,
    this.labelId,
  });

  factory CardLabel.fromJson(Map<String, dynamic> json) {
    return CardLabel(
      id: json['id'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      cardId: json['cardId'] as String?,
      labelId: json['labelId'] as String?,
    );
  }
}