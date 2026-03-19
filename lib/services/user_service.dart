import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final uid = currentUid;
    if (uid == null) return null;

    final doc = await _userRef(uid).get();
    return doc.data();
  }

  Future<void> updatePersonalInfo({
    required String name,
    required String phone,
  }) async {
    final uid = currentUid;
    if (uid == null) return;

    await _userRef(uid).update({
      'name': name.trim(),
      'phone': phone.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProfilePhoto(String photoUrl) async {
    final uid = currentUid;
    if (uid == null) return;

    await _userRef(uid).update({
      'profilePhotoUrl': photoUrl,
      'profileImageUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
