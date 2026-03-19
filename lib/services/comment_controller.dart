import '../models/comment_model.dart';
import 'comment_service.dart';

class CommentController {
  final CommentService _commentService = CommentService();

  Stream<List<CommentModel>> getCommentsStream(String postId) {
    return _commentService.getCommentsStream(postId);
  }

  Future<void> addComment(String postId, String text, String userId, String username, {String? parentId}) async {
    await _commentService.addComment(postId, text, userId, username, parentId: parentId);
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _commentService.deleteComment(postId, commentId);
  }
}