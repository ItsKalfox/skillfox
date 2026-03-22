import 'dart:math';
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

  int estimateTravelMinutes(double distanceKm) {
    return (distanceKm * 4).round().clamp(1, 999);
  }

  double calculateTravelFee(double distanceKm) {
    if (distanceKm <= 2) return 0;
    if (distanceKm <= 5) return 300;
    if (distanceKm <= 10) return 600;
    return 1000;
  }
}