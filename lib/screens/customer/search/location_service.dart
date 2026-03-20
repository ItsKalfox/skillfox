import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {

  double? latitude;
  double? longitude;
  bool isLoading = false;

  Future<void> getLocation() async {
    setState(() {
      isLoading = true;
    });

    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition();

    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Location")),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : latitude == null
                ? ElevatedButton(
                    onPressed: getLocation,
                    child: const Text("Get Location"),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Latitude: $latitude"),
                      Text("Longitude: $longitude"),
                      const SizedBox(height: 20),

                      // 🔥 Send location back
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, {
                            "lat": latitude,
                            "lon": longitude,
                          });
                        },
                        child: const Text("Use This Location"),
                      ),
                    ],
                  ),
      ),
    );
  }
}