import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/worker.dart';
import 'location_service.dart';

class WorkerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

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

            final travelMinutes = _locationService.estimateTravelMinutes(
              distanceKm,
            );
            final travelFee = _locationService.calculateTravelFee(distanceKm);

            workers.add(
              Worker(
                id: doc.id,
                name: (data['name'] ?? 'Unknown Worker').toString(),
                category: (data['jobType'] ?? 'Unknown').toString(),
                rating: ((data['rating'] ?? 4.5) as num).toDouble(),
                price: ((data['price'] ?? 2500) as num).toInt(),
                oldPrice: data['oldPrice'] == null
                    ? null
                    : ((data['oldPrice'] ?? 0) as num).toInt(),
                distanceKm: distanceKm,
                travelMinutes: travelMinutes,
                travelFee: travelFee,
                hasOffer: (data['hasOffer'] ?? false) as bool,
                isFeatured: (data['isFeatured'] ?? false) as bool,
                isFavorite: (data['isFavorite'] ?? false) as bool,
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
