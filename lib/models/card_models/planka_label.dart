class PlankaLabel {
  final String id;
  final String name;
  final num position;
  final String color;
  final String boardId;

  PlankaLabel({
    required this.id,
    required this.name,
    required this.position,
    required this.color,
    required this.boardId
  });

  factory PlankaLabel.fromJson(Map<String, dynamic> json,) {
    return PlankaLabel(
      id: json['id'],
      name: json['name'],
      position: json['position'],
      color: json['color'],
      boardId: json['boardId'],
    );
  }
}