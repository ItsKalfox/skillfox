import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {

  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    loadMarkers();
  }

  void loadMarkers() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('users').get();

    Set<Marker> tempMarkers = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final loc = data["location"];

      if (loc != null) {
        tempMarkers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(loc.latitude, loc.longitude),
            infoWindow: InfoWindow(
              title: data["name"],
              snippet: data["jobType"],
            ),
          ),
        );
      }
    }

    setState(() {
      markers = tempMarkers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Workers Map")),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(6.9271, 79.8612),
          zoom: 12,
        ),
        markers: markers,
      ),
    );
  }
}