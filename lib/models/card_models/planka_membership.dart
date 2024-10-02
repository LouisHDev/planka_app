class BoardMembership {
  String id;  // Board membership ID
  String userId;  // User ID
  String boardId;  // Board ID, to associate with a specific board
  String role;

  BoardMembership({
    required this.id,
    required this.userId,
    required this.boardId,  // Now it includes boardId
    required this.role,
  });

  factory BoardMembership.fromJson(Map<String, dynamic> json) {
    return BoardMembership(
      id: json['id'],
      userId: json['userId'],
      boardId: json['boardId'],  // Parse boardId to associate memberships with boards
      role: json['role'],
    );
  }
}