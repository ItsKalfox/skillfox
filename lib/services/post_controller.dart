import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. EXPLORE FEED 
  Stream<List<PostModel>> getPostsStream({String? categoryFilter}) {
    if (categoryFilter != null) {
      return _firestore.collection('posts').where('category', isEqualTo: categoryFilter).snapshots().map((snapshot) {
        List<PostModel> posts = snapshot.docs.map((doc) => PostModel.fromMap(doc.data(), doc.id)).toList();
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return posts;
      });
    } else {
      return _firestore.collection('posts').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => PostModel.fromMap(doc.data(), doc.id)).toList();
      });
    }
  }

  // 2. FOR YOU FEED 
  Stream<List<PostModel>> getForYouPostsStream() {
    return _firestore.collection('posts').snapshots().map((snapshot) {
      List<PostModel> posts = snapshot.docs.map((doc) => PostModel.fromMap(doc.data(), doc.id)).toList();
      posts.sort((a, b) => _calculateForYouScore(b).compareTo(_calculateForYouScore(a)));
      return posts;
    });
  }

  double _calculateForYouScore(PostModel post) {
    final hoursElapsed = DateTime.now().difference(post.createdAt).inHours.toDouble();
   
    final engagement = (post.likedBy.length * 1.0) + (post.commentCount * 2.0) + (post.savedBy.length * 3.0);
    
    
    final logEngagement = engagement > 0 ? log(engagement + 1) : 0.0;
    
   
    return logEngagement - (hoursElapsed * 0.05); 
  }

  // 3. MY CATEGORY FEED 
  Stream<List<PostModel>> getSuggestedCategoryPostsStream(String category) {
    return _firestore.collection('posts').where('category', isEqualTo: category).snapshots().map((snapshot) {
      List<PostModel> posts = snapshot.docs.map((doc) => PostModel.fromMap(doc.data(), doc.id)).toList();
      posts.sort((a, b) => _calculateAdvancedScore(b).compareTo(_calculateAdvancedScore(a)));
      return posts;
    });
  }

  double _calculateAdvancedScore(PostModel post) {
    final hoursElapsed = DateTime.now().difference(post.createdAt).inHours;
    final points = (post.likedBy.length * 2) + (post.commentCount * 3) + (post.savedBy.length * 4);
    return points / pow((hoursElapsed + 2), 1.5);
  }

  // 4. MY UPLOADS FEED 
  Stream<List<PostModel>> getMyUploadsStream(String workerId) {
    return _firestore.collection('posts').where('workerId', isEqualTo: workerId).snapshots().map((snapshot) {
      List<PostModel> posts = snapshot.docs.map((doc) => PostModel.fromMap(doc.data(), doc.id)).toList();
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    });
  }

  // 5. SAVED FEED 
  Stream<List<PostModel>> getSavedPostsStream(String currentUserId) {
    return _firestore.collection('posts').where('savedBy', arrayContains: currentUserId).snapshots().map((snapshot) {
      List<PostModel> posts = snapshot.docs.map((doc) => PostModel.fromMap(doc.data(), doc.id)).toList();
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    });
  }

  // UPLOAD, EDIT, & REPORT
  Future<List<String>> getCategories() async {
    return ['Mechanic', 'Teacher', 'Plumber', 'Electrician', 'Cleaner', 'Caregiver', 'Mason', 'Handyman'];
  }

  Future<void> createPost({required String workerId, required String username, required String category, required String description, required String mediaUrl, required String mediaType}) async {
    final docRef = _firestore.collection('posts').doc();
    final post = PostModel(id: docRef.id, workerId: workerId, username: username, category: category, description: description, mediaUrl: mediaUrl, mediaType: mediaType, likedBy: [], savedBy: [], reportedBy: [], commentCount: 0, createdAt: DateTime.now());
    await docRef.set(post.toMap());
  }

  Future<void> updatePostDescription(String postId, String newDescription) async {
    await _firestore.collection('posts').doc(postId).update({'description': newDescription});
  }

  Future<void> reportPost(String postId, String userId, String reason) async {
    await _firestore.collection('posts').doc(postId).update({'reportedBy': FieldValue.arrayUnion([userId])});
    await _firestore.collection('reports').add({'postId': postId, 'userId': userId, 'reason': reason, 'timestamp': FieldValue.serverTimestamp()});
  }

  // INTERACTIONS
  Future<void> toggleLike(String postId, String currentUserId, List<dynamic> currentLikes) async {
    if (currentLikes.contains(currentUserId)) {
      await _firestore.collection('posts').doc(postId).update({'likedBy': FieldValue.arrayRemove([currentUserId])});
    } else {
      await _firestore.collection('posts').doc(postId).update({'likedBy': FieldValue.arrayUnion([currentUserId])});
    }
  }

  Future<void> toggleSave(String postId, String currentUserId, List<dynamic> currentSaves) async {
    if (currentSaves.contains(currentUserId)) {
      await _firestore.collection('posts').doc(postId).update({'savedBy': FieldValue.arrayRemove([currentUserId])});
    } else {
      await _firestore.collection('posts').doc(postId).update({'savedBy': FieldValue.arrayUnion([currentUserId])});
    }
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }
}