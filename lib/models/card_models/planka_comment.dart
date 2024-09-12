class PlankaComment {
  String id;
  String createdAt;
  String? updatedAt;
  num position;
  String name;
  bool isCompleted;
  String cardId;

  PlankaComment({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.position,
    required this.name,
    required this.isCompleted,
    required this.cardId,
  });

  factory PlankaComment.fromJson(Map<String, dynamic> json) {
    return PlankaComment(
      id: json['id'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String?,
      position: json['position'] as num,
      name: json['name'] as String,
      isCompleted: json['isCompleted'] as bool,
      cardId: json['cardId'] as String,
    );
  }
}