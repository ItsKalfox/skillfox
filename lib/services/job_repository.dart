import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class JobRepository {
  JobRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _jobs =>
      _firestore.collection('jobs');

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection('reviews');

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamJob(String jobId) {
    return _jobs.doc(jobId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamJobs() {
    return _jobs.snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getJob(String jobId) {
    return _jobs.doc(jobId).get();
  }

  Future<String> createJob({
    required String userId,
    required String service,
    required String description,
    required DateTime scheduledAt,
    required String location,
    required double price,
    List<XFile> images = const [],
  }) async {
    final imageUrls = await _uploadImages(
      userId: userId,
      images: images,
    );

    final docRef = await _jobs.add({
      'userId': userId,
      'service': service,
      'description': description,
      'date': Timestamp.fromDate(scheduledAt),
      'status': 'pending',
      'price': price,
      'location': location,
      'imageUrls': imageUrls,
      'workerId': null,
      'workerName': 'Pending assignment',
      'workerPhone': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  Future<void> updateStatus(
    String jobId,
    String status, {
    Map<String, dynamic>? extra,
  }) {
    return _jobs.doc(jobId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      ...?extra,
    });
  }

  Future<void> submitReview({
    required String jobId,
    required String userId,
    required String workerId,
    required double rating,
    required String feedback,
  }) {
    return _reviews.add({
      'jobId': jobId,
      'userId': userId,
      'workerId': workerId,
      'rating': rating,
      'feedback': feedback,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<String>> _uploadImages({
    required String userId,
    required List<XFile> images,
  }) async {
    if (images.isEmpty) {
      return const [];
    }

    final uploadedUrls = <String>[];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < images.length; i++) {
      final image = images[i];
      final Uint8List bytes = await image.readAsBytes();
      final extension = _extensionFromName(image.name);
      final ref = _storage
          .ref()
          .child('job_images/$userId/$timestamp-$i$extension');

      await ref.putData(
        bytes,
        SettableMetadata(contentType: _contentType(extension)),
      );

      uploadedUrls.add(await ref.getDownloadURL());
    }

    return uploadedUrls;
  }

  String _extensionFromName(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return '.jpg';
    }
    return fileName.substring(dotIndex).toLowerCase();
  }

  String _contentType(String extension) {
    switch (extension) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
