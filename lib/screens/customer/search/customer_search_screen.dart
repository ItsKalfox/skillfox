import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../services/location_service.dart';

class CustomerSearchScreen extends StatefulWidget {
  final double customerLat;
  final double customerLng;

  const CustomerSearchScreen({
    super.key,
    required this.customerLat,
    required this.customerLng,
  });

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  final LocationService _locationService = LocationService();

  String query = "";
  String selectedCategory = "All";
  String sortOption = "Rating";

  Set<Marker> _workerMarkers = {};
  bool _markersLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadWorkerMarkers();
  }

  Future<void> _loadWorkerMarkers() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('users').get();

    final Set<Marker> markers = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final loc = data["location"];
      if (loc != null) {
        markers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(loc.latitude, loc.longitude),
            infoWindow: InfoWindow(
              title: data["name"] ?? "Worker",
              snippet: data["jobType"] ?? "",
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _workerMarkers = markers;
        _markersLoaded = true;
      });
    }
  }

  void _openFullMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullMapScreen(
          customerLat: widget.customerLat,
          customerLng: widget.customerLng,
          markers: _workerMarkers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Workers"),
      ),
      body: Column(
        children: [

          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              onChanged: (value) => setState(() => query = value),
              decoration: InputDecoration(
                hintText: "Search workers...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 🔹 CATEGORY FILTER
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _buildCategory("All", Icons.apps),
                _buildCategory("Mechanic", Icons.build),
                _buildCategory("Teacher", Icons.school),
                _buildCategory("Plumber", Icons.plumbing),
                _buildCategory("Electrician", Icons.electrical_services),
                _buildCategory("Cleaner", Icons.cleaning_services),
                _buildCategory("Caregiver", Icons.health_and_safety),
                _buildCategory("Mason", Icons.construction),
                _buildCategory("Handyman", Icons.handyman),
                _buildCategory("Painter", Icons.format_paint),
                _buildCategory("Gardener", Icons.local_florist),
                _buildCategory("Driver", Icons.directions_car),
                _buildCategory("IT Support", Icons.computer),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 🔹 SORT OPTIONS
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _buildSortChip("Rating"),
                _buildSortChip("Nearest"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 🗺️ MINI MAP
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 160,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          widget.customerLat,
                          widget.customerLng,
                        ),
                        zoom: 12,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId("customer"),
                          position: LatLng(
                            widget.customerLat,
                            widget.customerLng,
                          ),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure,
                          ),
                          infoWindow: const InfoWindow(title: "You"),
                        ),
                        ..._workerMarkers,
                      },
                      onMapCreated: (controller) {},
                      zoomControlsEnabled: false,
                      scrollGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      myLocationButtonEnabled: false,
                      liteModeEnabled: true,
                    ),

                    // Maximize button
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: _openFullMap,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.fullscreen_rounded,
                            size: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),

                    // Loading badge
                    if (!_markersLoaded)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                ),
                              ),
                              SizedBox(width: 5),
                              Text(
                                "Loading workers...",
                                style: TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 🔥 WORKER LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
    .collection('users')
    .where('role', isEqualTo: 'worker') // 🔥 ONLY WORKERS
    .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                // 📍 CALCULATE DISTANCE using correct method name
                List<Map<String, dynamic>> workers = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final GeoPoint? loc = data["location"];

                  data["distance"] = loc != null
                      ? _locationService.calculateDistanceKm(
                          startLat: widget.customerLat,
                          startLng: widget.customerLng,
                          endLat: loc.latitude,
                          endLng: loc.longitude,
                        )
                      : 999.0;

                  return data;
                }).toList();

                // 🔍 FILTER
                List<Map<String, dynamic>> filteredWorkers =
                    workers.where((w) {
                  final name = (w["name"] ?? "").toLowerCase();
                  final job = (w["jobType"] ?? "").toLowerCase();
                  final search = query.toLowerCase();

                  return (name.contains(search) || job.contains(search)) &&
                      (selectedCategory == "All" ||
                          job == selectedCategory.toLowerCase());
                }).toList();

                // 🔽 SORT
                if (sortOption == "Rating") {
                  filteredWorkers.sort((a, b) =>
                      (b["rating"] ?? 0).compareTo(a["rating"] ?? 0));
                } else {
                  filteredWorkers.sort((a, b) =>
                      (a["distance"] ?? 999.0)
                          .compareTo(b["distance"] ?? 999.0));
                }

                if (filteredWorkers.isEmpty) {
                  return const Center(child: Text("No workers found 😔"));
                }

                return ListView.builder(
                  itemCount: filteredWorkers.length,
                  itemBuilder: (context, index) {
                    final w = filteredWorkers[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: w["profilePhotoUrl"] != null &&
                                  w["profilePhotoUrl"] != ""
                              ? NetworkImage(w["profilePhotoUrl"])
                              : null,
                          child: w["profilePhotoUrl"] == null ||
                                  w["profilePhotoUrl"] == ""
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(w["name"] ?? "No Name"),
                        subtitle: Text(w["jobType"] ?? ""),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text((w["rating"] ?? 0).toString()),
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 16),
                              ],
                            ),
                            Text(
                              '${(w["distance"] ?? 0).toDouble().toStringAsFixed(1)} km',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(String label, IconData icon) {
    final isSelected = selectedCategory == label;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() => selectedCategory = label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected ? Colors.blue : Colors.black54),
              const SizedBox(width: 6),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(String label) {
    final isSelected = sortOption == label;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() => sortOption = label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 🗺️ FULL SCREEN MAP
// ─────────────────────────────────────────

class _FullMapScreen extends StatelessWidget {
  final double customerLat;
  final double customerLng;
  final Set<Marker> markers;

  const _FullMapScreen({
    required this.customerLat,
    required this.customerLng,
    required this.markers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Workers Near You")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(customerLat, customerLng),
          zoom: 12,
        ),
        markers: {
          Marker(
            markerId: const MarkerId("customer"),
            position: LatLng(customerLat, customerLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            infoWindow: const InfoWindow(title: "You"),
          ),
          ...markers,
        },
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
      ),
    );
  }
}