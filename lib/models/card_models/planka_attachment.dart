class PlankaAttachment {
  String id;
  String createdAt;
  String? updatedAt;
  String name;
  String cardId;
  String creatorUserId;
  String? url;
  String? coverUrl;

  PlankaAttachment({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.name,
    required this.cardId,
    required this.creatorUserId,
    this.url,
    this.coverUrl,
  });

  factory PlankaAttachment.fromJson(Map<String, dynamic> json) {
    return PlankaAttachment(
      id: json['id'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String?,
      name: json['name'] as String,
      cardId: json['cardId'] as String,
      creatorUserId: json['creatorUserId'] as String,
      url: json['url'] as String?,
      coverUrl: json['coverUrl'] as String?,
    );
  }
}