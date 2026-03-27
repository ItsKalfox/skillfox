import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/worker.dart';
import 'location_service.dart';

class WorkerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  double _toDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  bool _toBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  Stream<List<Worker>> getWorkersForCustomerLocation({
    required double customerLat,
    required double customerLng,
  }) {
    return _firestore
        .collection('users')
        .where('status', isEqualTo: 'active')
        .where('role', isEqualTo: 'worker')
        .snapshots()
        .asyncMap((snapshot) async {
          final workers = <Worker>[];

          final user = FirebaseAuth.instance.currentUser;
          double searchRadius = 30.0;
          if (user != null) {
            final userDoc = await _firestore.collection('users').doc(user.uid).get();
            searchRadius = _toDouble(userDoc.data()?['searchRadius'], fallback: 30.0);
          }

          for (final doc in snapshot.docs) {
            final data = doc.data();

            final geoPoint = data['location'];
            if (geoPoint is! GeoPoint) continue;

            // Pre-filter: skip workers outside search radius range
            final distanceKm = _locationService.calculateDistanceKm(
              startLat: customerLat,
              startLng: customerLng,
              endLat: geoPoint.latitude,
              endLng: geoPoint.longitude,
            );
            if (distanceKm > searchRadius) continue;

            final bool hasOffer = _toBool(data['hasOffer'], fallback: false);
            final String offerType = (data['offerType'] ?? '').toString();
            final String offerDetails = (data['offerDetails'] ?? '').toString();

            double travelFee = _locationService.calculateTravelFee(distanceKm);
            if (hasOffer && offerType == 'Free Travel') travelFee = 0;

            final travelMinutes = _locationService.estimateTravelMinutes(
              distanceKm,
            );

            workers.add(
              Worker(
                id: doc.id,
                name: (data['name'] ?? 'Unknown Worker').toString(),
                category: (data['jobType'] ?? 'Unknown').toString(),
                // fallback 0.0 — no dummy rating for new workers
                // Firestore field is 'ratingAverage', not 'rating'
                rating: _toDouble(
                  data['ratingAverage'] ?? data['rating'],
                  fallback: 0.0,
                ),
                ratingCount: _toInt(data['ratingCount'], fallback: 0),
                completedJobsCount: _toInt(
                  data['completedJobsCount'],
                  fallback: 0,
                ),
                distanceKm: distanceKm,
                travelMinutes: travelMinutes,
                travelFee: travelFee,
                hasOffer: hasOffer,
                offerType: offerType,
                offerDetails: offerDetails,
                isFeatured: _toBool(data['isFeatured'], fallback: false),
                featuredWeekKey: (data['featuredWeekKey'] ?? '').toString(),
                isFavorite: false,
                profilePhotoUrl: (data['profilePhotoUrl'] ?? '').toString(),
                address: (data['address'] ?? '').toString(),
                lat: _toDouble(data['lat']),
                lng: _toDouble(data['lng']),
              ),
            );
          }

          workers.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
          return workers;
        });
  }
}