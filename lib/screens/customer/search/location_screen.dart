import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {

  LatLng selectedLocation = const LatLng(6.9271, 79.8612); // default Colombo

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Location"),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: selectedLocation,
          zoom: 12,
        ),
        onTap: (LatLng position) {
          setState(() {
            selectedLocation = position;
          });
        },
        markers: {
          Marker(
            markerId: const MarkerId("selected"),
            position: selectedLocation,
          ),
        },
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.check),
        onPressed: () {
          Navigator.pop(context, {
            "lat": selectedLocation.latitude,
            "lon": selectedLocation.longitude,
          });
        },
      ),
    );
  }
}