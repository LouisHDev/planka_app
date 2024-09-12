import 'package:planka_app/models/planka_card.dart';

class PlankaList {
  final String id;
  final String name;
  final num position;
  final List<PlankaCard> cards;
  // final List<PlankaLabel> labels;

  PlankaList({
    required this.id,
    required this.name,
    required this.position,
    required this.cards,
    // required this.labels,
  });

  factory PlankaList.fromJson(Map<String, dynamic> json, List<PlankaCard> cards) {
    return PlankaList(
      id: json['id'],
      name: json['name'],
      position: json['position'],
      cards: cards,
      // labels: labels,
    );
  }
}