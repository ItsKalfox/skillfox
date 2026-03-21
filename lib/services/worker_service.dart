import 'package:cloud_firestore/cloud_firestore.dart';
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
        .where('role', isEqualTo: 'worker')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          final workers = <Worker>[];

          for (final doc in snapshot.docs) {
            final data = doc.data();

            final geoPoint = data['location'];
            if (geoPoint is! GeoPoint) continue;

            final distanceKm = _locationService.calculateDistanceKm(
              startLat: customerLat,
              startLng: customerLng,
              endLat: geoPoint.latitude,
              endLng: geoPoint.longitude,
            );

            final bool hasOffer = _toBool(data['hasOffer'], fallback: false);
            final String offerType = (data['offerType'] ?? 'none').toString();

            double travelFee = _locationService.calculateTravelFee(distanceKm);

            if (hasOffer && offerType == 'free_travel') {
              travelFee = 0;
            }

            final travelMinutes = _locationService.estimateTravelMinutes(
              distanceKm,
            );

            workers.add(
              Worker(
                id: doc.id,
                name: (data['name'] ?? 'Unknown Worker').toString(),
                category: (data['jobType'] ?? 'Unknown').toString(),
                rating: _toDouble(data['ratingAverage'], fallback: 4.5),
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
                isFeatured: _toBool(data['isFeatured'], fallback: false),
                featuredWeekKey: (data['featuredWeekKey'] ?? '').toString(),
                isFavorite: false,
                profilePhotoUrl: (data['profilePhotoUrl'] ?? '').toString(),
                address: (data['address'] ?? '').toString(),
              ),
            );
          }

          workers.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
          return workers;
        });
  }
}
