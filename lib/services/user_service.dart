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
    String? about,
    String? certification,
    String? experience,
    bool? isAvailable,
    List<Map<String, dynamic>>? services,
  }) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'name': name,
      'phone': phone,
      'about': about,
      'certification': certification,
      'experience': experience,
      'isAvailable': isAvailable,
      'services': services,
    });
  }

  Future<void> updateWorkerInfo({
    required String name,
    required String phone,
    required String about,
    required String certification,
    required String experience,
    required bool isAvailable,
    required List<Map<String, dynamic>> services,
  }) async {
    return updatePersonalInfo(
      name: name,
      phone: phone,
      about: about,
      certification: certification,
      experience: experience,
      isAvailable: isAvailable,
      services: services,
    );
  }
}
