class PlankaCardMembership {
  final String id;
  final String cardId;
  final String userId;

  PlankaCardMembership({
    required this.id,
    required this.cardId,
    required this.userId
  });

  factory PlankaCardMembership.fromJson(Map<String, dynamic> json,) {
    return PlankaCardMembership(
      id: json['id'],
      cardId: json['cardId'],
      userId: json['userId'],
    );
  }
}