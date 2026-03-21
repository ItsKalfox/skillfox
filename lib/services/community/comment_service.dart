import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillfox/models/comment_model.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<CommentModel>> getCommentsStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CommentModel.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> addComment(
    String postId,
    String text,
    String userId,
    String username, {
    String? parentId,
  }) async {
    final docRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc();

    final newComment = CommentModel(
      id: docRef.id,
      postId: postId,
      userId: userId,
      username: username,
      text: text,
      date: DateTime.now().toLocal().toString().substring(0, 16),
      parentId: parentId,
    );

    await docRef.set(newComment.toMap());

    await _firestore.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();

    await _firestore.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(-1),
    });
  }
}
