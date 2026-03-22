import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  const Job({
    required this.id,
    required this.userId,
    required this.service,
    required this.description,
    required this.location,
    required this.status,
    required this.scheduledAt,
    required this.createdAt,
    required this.price,
    required this.imageUrls,
    this.workerId,
    this.workerName,
    this.workerPhone,
  });

  final String id;
  final String userId;
  final String service;
  final String description;
  final String location;
  final String status;
  final DateTime scheduledAt;
  final DateTime createdAt;
  final double price;
  final List<String> imageUrls;
  final String? workerId;
  final String? workerName;
  final String? workerPhone;

  factory Job.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Job document does not exist.');
    }

    return Job(
      id: snapshot.id,
      userId: data['userId'] as String? ?? '',
      service: data['service'] as String? ?? '',
      description: data['description'] as String? ?? '',
      location: data['location'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      scheduledAt: _toDateTime(data['date']) ?? DateTime.now(),
      createdAt: _toDateTime(data['createdAt']) ?? DateTime.now(),
      price: (data['price'] as num?)?.toDouble() ?? 0,
      imageUrls: (data['imageUrls'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      workerId: data['workerId'] as String?,
      workerName: data['workerName'] as String?,
      workerPhone: data['workerPhone'] as String?,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}
