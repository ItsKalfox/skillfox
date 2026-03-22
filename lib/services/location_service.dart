import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position?> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  double calculateDistanceKm({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    final meters = Geolocator.distanceBetween(
      startLat,
      startLng,
      endLat,
      endLng,
    );
    return meters / 1000;
  }

  /// Estimates travel time assuming 25 km/h average speed,
  /// which accounts for typical Sri Lankan urban/suburban traffic.
  /// Minimum 1 minute, maximum 999 minutes.
  int estimateTravelMinutes(double distanceKm) {
    return ((distanceKm / 25) * 60).round().clamp(1, 999);
  }

  /// Progressive travel fee — free within 2 km, then a base charge
  /// plus a per-km rate that increases with distance.
  /// No upper cap — longer distances cost more.
  ///
  ///   0 –  2 km  → LKR 0        (free zone)
  ///   2 –  5 km  → LKR 50  + LKR 40/km  beyond 2 km
  ///   5 – 10 km  → LKR 170 + LKR 60/km  beyond 5 km
  ///  10 – 20 km  → LKR 470 + LKR 80/km  beyond 10 km
  ///     20 km+   → LKR 1270 + LKR 100/km beyond 20 km
  ///
  /// Result is rounded to the nearest LKR 10 for cleaner display.
  double calculateTravelFee(double distanceKm) {
    double fee;
    if (distanceKm <= 2) {
      fee = 0;
    } else if (distanceKm <= 5) {
      fee = 50 + (distanceKm - 2) * 40;
    } else if (distanceKm <= 10) {
      fee = 170 + (distanceKm - 5) * 60;
    } else if (distanceKm <= 20) {
      fee = 470 + (distanceKm - 10) * 80;
    } else {
      fee = 1270 + (distanceKm - 20) * 100;
    }
    return ((fee / 10).round() * 10).toDouble();
  }
}
