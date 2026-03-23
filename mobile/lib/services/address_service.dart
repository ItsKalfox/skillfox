import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_address.dart';

class AddressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _addressRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('addresses');
  }

  Stream<List<UserAddress>> getAddresses() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    return _addressRef(uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserAddress.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> addAddress(UserAddress address) async {
    final uid = _uid;
    if (uid == null) return;

    final existing = await _addressRef(uid).get();
    final bool shouldBeDefault = existing.docs.isEmpty || address.isDefault;

    if (shouldBeDefault) {
      await _clearDefault(uid);
    }

    final docRef = _addressRef(uid).doc();

    await docRef.set({
      ...address.copyWith(isDefault: shouldBeDefault).toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAddress(UserAddress address) async {
    final uid = _uid;
    if (uid == null) return;

    if (address.isDefault) {
      await _clearDefault(uid);
    }

    await _addressRef(uid).doc(address.id).update({
      ...address.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAddress(String addressId) async {
    final uid = _uid;
    if (uid == null) return;

    await _addressRef(uid).doc(addressId).delete();
  }

  Future<void> setDefaultAddress(String addressId) async {
    final uid = _uid;
    if (uid == null) return;

    final batch = _firestore.batch();
    final snapshot = await _addressRef(uid).get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isDefault': doc.id == addressId});
    }

    await batch.commit();
  }

  Future<UserAddress?> getDefaultAddress() async {
    final uid = _uid;
    if (uid == null) return null;

    final snapshot = await _addressRef(
      uid,
    ).where('isDefault', isEqualTo: true).limit(1).get();

    if (snapshot.docs.isEmpty) return null;
    return UserAddress.fromFirestore(snapshot.docs.first);
  }

  Future<bool> hasAnyAddress() async {
    final uid = _uid;
    if (uid == null) return false;

    final snapshot = await _addressRef(uid).limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> _clearDefault(String uid) async {
    final snapshot = await _addressRef(
      uid,
    ).where('isDefault', isEqualTo: true).get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isDefault': false});
    }
    await batch.commit();
  }

  Future<void> ensureDefaultAddressFromUserProfile() async {
    final uid = _uid;
    if (uid == null) return;

    final addressCollection = _addressRef(uid);
    final existingAddresses = await addressCollection.limit(1).get();

    if (existingAddresses.docs.isNotEmpty) {
      return;
    }

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final data = userDoc.data();

    if (data == null) return;

    final addressText = (data['address'] ?? '').toString();
    final location = data['location'] as GeoPoint?;

    if (addressText.trim().isEmpty || location == null) {
      return;
    }

    await addressCollection.add({
      'label': 'Home',
      'line1': addressText,
      'line2': '',
      'city': '',
      'postalCode': '',
      'province': '',
      'isDefault': true,
      'location': location,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
