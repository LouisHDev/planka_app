class PlankaUser {
  final String id;
  final String? createdAt;
  final String? updatedAt;
  final String email;
  final bool? isAdmin;
  final String name;
  final String username;
  final String? phone;
  final String? organization;
  final String? language;
  final bool? subscribeToOwnCards;
  final String? deletedAt;
  final bool? isLocked;
  final bool? isRoleLocked;
  final bool? isUsernameLocked;
  final bool? isDeletionLocked;
  final String? avatarUrl;

  PlankaUser({
    required this.id,
    this.createdAt,
    this.updatedAt,
    required this.email,
    this.isAdmin,
    required this.name,
    required this.username,
    this.phone,
    this.organization,
    this.language,
    this.subscribeToOwnCards,
    this.deletedAt,
    this.isLocked,
    this.isRoleLocked,
    this.isUsernameLocked,
    this.isDeletionLocked,
    this.avatarUrl,
  });

  factory PlankaUser.fromJson(Map<String, dynamic> json) {
    return PlankaUser(
      id: json['id'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      email: json['email'],
      isAdmin: json['isAdmin'],
      name: json['name'],
      username: json['username'],
      phone: json['phone'],
      organization: json['organization'],
      language: json['language'],
      subscribeToOwnCards: json['subscribeToOwnCards'],
      deletedAt: json['deletedAt'],
      isLocked: json['isLocked'],
      isRoleLocked: json['isRoleLocked'],
      isUsernameLocked: json['isUsernameLocked'],
      isDeletionLocked: json['isDeletionLocked'],
      avatarUrl: json['avatarUrl'],
    );
  }
}
