import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'location_service.dart';
import 'location_screen.dart';
import 'map_screen.dart';

class CustomerSearchScreen extends StatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {

  String query = "";
  String selectedCategory = "All";
  String sortOption = "Rating";

  double? userLat;
  double? userLon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Workers"),
        actions: [

          // 📍 LOCATION BUTTON
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LocationScreen()),
              );

              if (result != null) {
                setState(() {
                  userLat = result["lat"];
                  userLon = result["lon"];
                });
              }
            },
          ),

          // 🗺 MAP BUTTON
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              if (userLat == null || userLon == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Select location first 📍")),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapScreen()),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [

          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Search workers...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
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
                buildCategory("All", Icons.apps),
                buildCategory("Mechanic", Icons.build),
                buildCategory("Teacher", Icons.school),
                buildCategory("Plumber", Icons.plumbing),
                buildCategory("Electrician", Icons.electrical_services),
                buildCategory("Cleaner", Icons.cleaning_services),
                buildCategory("Caregiver", Icons.health_and_safety),
                buildCategory("Mason", Icons.construction),
                buildCategory("Handyman", Icons.handyman),
                buildCategory("Painter", Icons.format_paint),
                buildCategory("Gardener", Icons.local_florist),
                buildCategory("Driver", Icons.directions_car),
                buildCategory("IT Support", Icons.computer),
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
                buildSortChip("Rating"),
                buildSortChip("Nearest"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 🔥 FIREBASE DATA
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                // 📍 REQUIRE LOCATION
                if (userLat == null || userLon == null) {
                  return const Center(
                    child: Text("Please select your location 📍"),
                  );
                }

                // 📍 CALCULATE DISTANCE
                List<Map<String, dynamic>> workers = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final GeoPoint? loc = data["location"];

                  if (loc != null) {
                    data["distance"] = LocationService.calculateDistance(
                      userLat!,
                      userLon!,
                      loc.latitude,
                      loc.longitude,
                    );
                  } else {
                    data["distance"] = 999.0;
                  }

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
                          backgroundImage:
                              w["profilePhotoUrl"] != null &&
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
                          mainAxisAlignment:
                              MainAxisAlignment.center,
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
                              w["distance"] != null
                                  ? '${(w["distance"] as double).toStringAsFixed(1)} km'
                                  : "N/A",
                              style:
                                  const TextStyle(fontSize: 10),
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

  // 🔵 CATEGORY BUTTON
  Widget buildCategory(String label, IconData icon) {
    final isSelected = selectedCategory == label;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedCategory = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color:
                  isSelected ? Colors.blue : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected
                      ? Colors.blue
                      : Colors.black54),
              const SizedBox(width: 6),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  // 🔽 SORT BUTTON
  Widget buildSortChip(String label) {
    final isSelected = sortOption == label;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          setState(() {
            sortOption = label;
          });
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue.shade50
                : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color:
                  isSelected ? Colors.blue : Colors.grey.shade300,
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}