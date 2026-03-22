
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'worker_request_detail_screen.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class WorkerRequestsScreen extends StatefulWidget {
//   const WorkerRequestsScreen({super.key});

//   @override
//   State<WorkerRequestsScreen> createState() =>
//       _WorkerRequestsScreenState();
// }

// class _WorkerRequestsScreenState extends State<WorkerRequestsScreen> {

//   String _selectedFilter = "All";

//   // 🔥 UPDATED FILTERS (MATCH SYSTEM)
//   final List<String> _filters = [
//     "All",
//     "waiting",
//     "accepted",
//     "paid",
//     "in_progress",
//     "completed",
//     "cancelled"
//   ];

//   String initials(String name) {
//     var p = name.split(" ");
//     return p.length > 1 ? "${p[0][0]}${p[1][0]}" : p[0][0];
//   }

//   @override
//   Widget build(BuildContext context) {

//     final user = FirebaseAuth.instance.currentUser;

//     return Scaffold(
//       body: Stack(
//         children: [

//           // 🔵 BACKGROUND
//           Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Color(0xFF469FEF),
//                   Color(0xFF5C75F0),
//                   Color(0xFF6C56F0),
//                 ],
//               ),
//             ),
//           ),

//           // ⚪ MAIN
//           SafeArea(
//             child: Container(
//               margin: const EdgeInsets.only(top: 80),
//               decoration: const BoxDecoration(
//                 color: Color(0xFFF4F6FA),
//                 borderRadius: BorderRadius.vertical(
//                   top: Radius.circular(30),
//                 ),
//               ),

//               child: Column(
//                 children: [

//                   // 🔹 HEADER
//                   Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       children: [

//                         Row(
//                           children: [

//                             GestureDetector(
//                               onTap: () => Navigator.pop(context),
//                               child: Container(
//                                 width: 36,
//                                 height: 36,
//                                 decoration: BoxDecoration(
//                                   color: Colors.grey.shade200,
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: const Icon(Icons.arrow_back_ios_new, size: 16),
//                               ),
//                             ),

//                             const SizedBox(width: 10),

//                             Text(
//                               "Inspection Requests",
//                               style: GoogleFonts.poppins(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),

//                             const Spacer(),

//                             // 🔥 NEW COUNT (WAITING ONLY)
//                             StreamBuilder<QuerySnapshot>(
//                               stream: FirebaseFirestore.instance
//                                   .collection('requests')
//                                   .where('workerId', isEqualTo: user!.uid)
//                                   .where('status', isEqualTo: 'waiting')
//                                   .snapshots(),
//                               builder: (context, snapshot) {

//                                 int count = snapshot.data?.docs.length ?? 0;

//                                 return Container(
//                                   padding: const EdgeInsets.symmetric(
//                                       horizontal: 12, vertical: 5),
//                                   decoration: BoxDecoration(
//                                     gradient: const LinearGradient(
//                                       colors: [
//                                         Color(0xFF469FEF),
//                                         Color(0xFF6C56F0),
//                                       ],
//                                     ),
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Text(
//                                     "$count New",
//                                     style: const TextStyle(color: Colors.white),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ],
//                         ),

//                         const SizedBox(height: 12),

//                         // 🔹 FILTERS
//                         SingleChildScrollView(
//                           scrollDirection: Axis.horizontal,
//                           child: Row(
//                             children: _filters.map((f) {
//                               bool active = _selectedFilter == f;

//                               return Padding(
//                                 padding: const EdgeInsets.only(right: 8),
//                                 child: GestureDetector(
//                                   onTap: () {
//                                     setState(() {
//                                       _selectedFilter = f;
//                                     });
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.symmetric(
//                                         horizontal: 16, vertical: 6),
//                                     decoration: BoxDecoration(
//                                       gradient: active
//                                           ? const LinearGradient(
//                                               colors: [
//                                                 Color(0xFF469FEF),
//                                                 Color(0xFF6C56F0),
//                                               ],
//                                             )
//                                           : null,
//                                       color: active ? null : Colors.white,
//                                       borderRadius: BorderRadius.circular(20),
//                                       border: Border.all(color: Colors.grey.shade300),
//                                     ),
//                                     child: Text(
//                                       f.toUpperCase(),
//                                       style: TextStyle(
//                                         color: active
//                                             ? Colors.white
//                                             : Colors.black54,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               );
//                             }).toList(),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   // 🔥 LIST
//                   Expanded(
//                     child: StreamBuilder<QuerySnapshot>(
//                       stream: FirebaseFirestore.instance
//                           .collection('requests')
//                           .where('workerId', isEqualTo: user!.uid)
//                           .orderBy('createdAt', descending: true)
//                           .snapshots(),
//                       builder: (context, snapshot) {

//                         if (!snapshot.hasData) {
//                           return const Center(child: CircularProgressIndicator());
//                         }

//                         final docs = snapshot.data!.docs;

//                         final filteredDocs = docs.where((doc) {

//                           final data = doc.data() as Map<String, dynamic>;

//                           if (!data.containsKey('workerId')) return false;

//                           if (_selectedFilter == "All") return true;

//                           return (data['status'] ?? '')
//                                   .toString()
//                                   .toLowerCase() ==
//                               _selectedFilter.toLowerCase();

//                         }).toList();

//                         if (filteredDocs.isEmpty) {
//                           return const Center(child: Text("No requests found"));
//                         }

//                         return ListView.builder(
//                           padding: const EdgeInsets.all(12),
//                           itemCount: filteredDocs.length,
//                           itemBuilder: (context, index) {

//                             final doc = filteredDocs[index];
//                             final data = doc.data() as Map<String, dynamic>;

//                             data['id'] = doc.id;

//                             final name = data['customerName'] ?? "Customer";
//                             final address = data['address'] ?? "";
//                             final desc = data['description'] ?? "";
//                             final status = data['status'] ?? "waiting";

//                             return Container(
//                               margin: const EdgeInsets.only(bottom: 10),
//                               padding: const EdgeInsets.all(14),
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(18),
//                               ),

//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [

//                                   Row(
//                                     children: [
//                                       CircleAvatar(
//                                         backgroundColor: const Color(0xFF469FEF),
//                                         child: Text(initials(name),
//                                             style: const TextStyle(color: Colors.white)),
//                                       ),

//                                       const SizedBox(width: 10),

//                                       Expanded(
//                                         child: Column(
//                                           crossAxisAlignment: CrossAxisAlignment.start,
//                                           children: [
//                                             Text(name),
//                                             const Text("Recent request",
//                                                 style: TextStyle(fontSize: 10)),
//                                           ],
//                                         ),
//                                       ),

//                                       buildStatusChip(status),
//                                     ],
//                                   ),

//                                   const SizedBox(height: 10),
//                                   const Divider(),

//                                   Row(
//                                     children: [
//                                       const Icon(Icons.location_on,
//                                           size: 14,
//                                           color: Color(0xFF6C56F0)),
//                                       const SizedBox(width: 6),
//                                       Expanded(child: Text(address)),
//                                     ],
//                                   ),

//                                   const SizedBox(height: 6),

//                                   Row(
//                                     children: [
//                                       const Icon(Icons.info_outline, size: 14),
//                                       const SizedBox(width: 6),
//                                       Expanded(child: Text(desc)),
//                                     ],
//                                   ),

//                                   const SizedBox(height: 12),

//                                   Align(
//                                     alignment: Alignment.centerRight,
//                                     child: GestureDetector(
//                                       onTap: () {
//                                         Navigator.push(
//                                           context,
//                                           MaterialPageRoute(
//                                             builder: (context) =>
//                                                 WorkerRequestDetailScreen(data: data),
//                                           ),
//                                         );
//                                       },
//                                       child: Container(
//                                         padding: const EdgeInsets.symmetric(
//                                             horizontal: 20, vertical: 8),
//                                         decoration: BoxDecoration(
//                                           gradient: const LinearGradient(
//                                             colors: [
//                                               Color(0xFF469FEF),
//                                               Color(0xFF6C56F0),
//                                             ],
//                                           ),
//                                           borderRadius: BorderRadius.circular(10),
//                                         ),
//                                         child: const Text(
//                                           "View",
//                                           style: TextStyle(color: Colors.white),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // 🔥 STATUS CHIP (COLOR LOGIC)
//   Widget buildStatusChip(String status) {
//     Color bg;
//     Color text;

//     switch (status) {
//       case "waiting":
//         bg = Colors.orange.shade100;
//         text = Colors.orange;
//         break;
//       case "accepted":
//         bg = Colors.blue.shade100;
//         text = Colors.blue;
//         break;
//       case "paid":
//         bg = Colors.purple.shade100;
//         text = Colors.purple;
//         break;
//       case "in_progress":
//         bg = Colors.indigo.shade100;
//         text = Colors.indigo;
//         break;
//       case "completed":
//         bg = Colors.green.shade100;
//         text = Colors.green;
//         break;
//       case "cancelled":
//         bg = Colors.red.shade100;
//         text = Colors.red;
//         break;
//       default:
//         bg = Colors.grey.shade200;
//         text = Colors.black54;
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         color: bg,
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Text(
//         status.toUpperCase(),
//         style: TextStyle(color: text, fontWeight: FontWeight.bold),
//       ),
//     );
//   }
// }