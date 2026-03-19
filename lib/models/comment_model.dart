class CommentModel {
  final String id;
  final String postId;
  final String userId; 
  final String username;
  final String text;
  final String date;
  final String? parentId; 

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    required this.text,
    required this.date,
    this.parentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'username': username,
      'text': text,
      'date': date,
      'parentId': parentId,
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] ?? '',
      postId: map['postId'] ?? '',
      userId: map['userId'] ?? 'unknown_user', 
      username: map['username'] ?? 'Anonymous',
      text: map['text'] ?? '',
      date: map['date'] ?? '',
      parentId: map['parentId'],
    );
  }
}