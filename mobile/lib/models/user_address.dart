import 'package:cloud_firestore/cloud_firestore.dart';

class UserAddress {
  final String id;
  final String label;
  final String line1;
  final String line2;
  final String city;
  final String postalCode;
  final String province;
  final bool isDefault;
  final GeoPoint? location;
  final bool isCurrentLocation;

  const UserAddress({
    required this.id,
    required this.label,
    required this.line1,
    required this.line2,
    required this.city,
    required this.postalCode,
    required this.province,
    required this.isDefault,
    required this.location,
    this.isCurrentLocation = false,
  });

  String get fullAddress {
    final parts = [
      line1,
      line2,
      city,
      postalCode,
      province,
    ].where((e) => e.trim().isNotEmpty).toList();

    return parts.join(', ');
  }

  UserAddress copyWith({
    String? id,
    String? label,
    String? line1,
    String? line2,
    String? city,
    String? postalCode,
    String? province,
    bool? isDefault,
    GeoPoint? location,
    bool? isCurrentLocation,
  }) {
    return UserAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      province: province ?? this.province,
      isDefault: isDefault ?? this.isDefault,
      location: location ?? this.location,
      isCurrentLocation: isCurrentLocation ?? this.isCurrentLocation,
    );
  }

  factory UserAddress.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return UserAddress(
      id: doc.id,
      label: (data['label'] ?? '').toString(),
      line1: (data['line1'] ?? '').toString(),
      line2: (data['line2'] ?? '').toString(),
      city: (data['city'] ?? '').toString(),
      postalCode: (data['postalCode'] ?? '').toString(),
      province: (data['province'] ?? '').toString(),
      isDefault: (data['isDefault'] ?? false) as bool,
      location: data['location'] as GeoPoint?,
      isCurrentLocation: false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'line1': line1,
      'line2': line2,
      'city': city,
      'postalCode': postalCode,
      'province': province,
      'isDefault': isDefault,
      'location': location,
    };
  }
}
