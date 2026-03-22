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
    bool? hasOffer,
    String? offerType,
    String? offerDetails,
  }) async {
    final uid = currentUid;
    if (uid == null) return;

    await _userRef(uid).update({
      'name': name.trim(),
      'phone': phone.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (about != null) 'about': about.trim(),
      if (certification != null) 'certification': certification.trim(),
      if (experience != null) 'experience': experience.trim(),
      if (isAvailable != null) 'isAvailable': isAvailable,
      if (services != null) 'services': services,
      if (hasOffer != null) 'hasOffer': hasOffer,
      if (offerType != null) 'offerType': offerType.trim(),
      if (offerDetails != null) 'offerDetails': offerDetails.trim(),
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

  Future<void> updateCoverPhoto(String photoUrl) async {
    final uid = currentUid;
    if (uid == null) return;

    await _userRef(uid).update({
      'coverPhotoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserOffers({
    required bool hasOffer,
    String? offerType,
    String? offerDetails,
  }) async {
    final uid = currentUid;
    if (uid == null) return;

    await _userRef(uid).update({
      'hasOffer': hasOffer,
      if (offerType != null) 'offerType': offerType.trim(),
      if (offerDetails != null) 'offerDetails': offerDetails.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
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
