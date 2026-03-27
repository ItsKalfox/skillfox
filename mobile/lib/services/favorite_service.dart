import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<Set<String>> getFavoriteWorkerIds() {
    final uid = currentUserId;
    if (uid == null) return Stream.value(<String>{});

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  Future<void> toggleFavorite(String workerId, bool isCurrentlyFavorite) async {
    final uid = currentUserId;
    if (uid == null) return;

    final favRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(workerId);

    if (isCurrentlyFavorite) {
      await favRef.delete();
    } else {
      await favRef.set({
        'workerId': workerId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
