import 'package:planka_app/models/card_models/planka_card_membership.dart';
import 'package:planka_app/models/card_models/planka_label.dart';
import 'package:planka_app/models/planka_user.dart';
import 'package:planka_app/models/card_models/planka_attachment.dart';

import 'card_models/planka_task.dart';

class PlankaCard {
  String id;
  String boardId;
  String name;
  String listId;
  num position;
  String? description;
  String? dueDate;
  bool isSubscribed;
  String? coverAttachmentId;
  String creatorUserId;

  ///Card Specific Labels
  final List<PlankaLabel> labels;

  /// Questionable
  final List<PlankaTask> tasks;

  ///Unspecific Values
  final List<PlankaCardMembership> cardMemberships;
  final List<PlankaAttachment> cardAttachment;
  final List<PlankaUser> cardUsers;

  ///Stopwatch
  int? stopwatchTotal;
  DateTime? stopwatchStartedAt;

  PlankaCard({
    required this.id,
    required this.boardId,
    required this.name,
    required this.listId,
    required this.position,
    this.description,
    this.dueDate,
    required this.isSubscribed,
    this.coverAttachmentId,
    required this.creatorUserId,
    required this.labels,
    required this.tasks,
    required this.cardMemberships,
    required this.cardAttachment,
    required this.cardUsers,
    this.stopwatchTotal,
    this.stopwatchStartedAt,
  });

  factory PlankaCard.fromJson(
      Map<String, dynamic> json,
      List<PlankaLabel> labels,
      List<PlankaTask> tasks,
      List<PlankaCardMembership> cardMemberships,
      List<PlankaAttachment> cardAttachments,
      List<PlankaUser> cardUsers
      ) {
    return PlankaCard(
      id: json['id'],
      boardId: json['boardId'],
      name: json['name'],
      listId: json['listId'],
      position: json['position'],
      description: json['description'],
      dueDate: json['dueDate'],
      isSubscribed: json['isSubscribed'],
      coverAttachmentId: json['coverAttachmentId'],
      creatorUserId: json['creatorUserId'],
      tasks: tasks,
      labels: labels,
      cardMemberships: cardMemberships,
      cardAttachment: cardAttachments,
      cardUsers: cardUsers,
      stopwatchTotal: json['stopwatch']?['total'],
      stopwatchStartedAt: json['stopwatch']?['startedAt'] != null
          ? DateTime.parse(json['stopwatch']['startedAt'])
          : null,
    );
  }
}
