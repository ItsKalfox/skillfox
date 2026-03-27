import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CustomerFavoritesScreen extends StatelessWidget {
  const CustomerFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'You need to sign in first.',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    final favoritesStream = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('favorites')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Favorites'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F8FC),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: favoritesStream,
        builder: (context, favoriteSnapshot) {
          if (favoriteSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (favoriteSnapshot.hasError) {
            return Center(child: Text('Error: ${favoriteSnapshot.error}'));
          }

          final favoriteDocs = favoriteSnapshot.data?.docs ?? [];

          if (favoriteDocs.isEmpty) {
            return const Center(
              child: Text(
                'No favorite workers yet.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favoriteDocs.length,
            itemBuilder: (context, index) {
              final workerId = favoriteDocs[index].id;

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(workerId)
                    .get(),
                builder: (context, workerSnapshot) {
                  if (workerSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFEAECEF)),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Color(0xFFE6EAF7),
                            child: Icon(Icons.person),
                          ),
                          SizedBox(width: 12),
                          Expanded(child: Text('Loading worker...')),
                        ],
                      ),
                    );
                  }

                  if (!workerSnapshot.hasData || !workerSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final data = workerSnapshot.data!.data()!;
                  final name = (data['name'] ?? 'Unknown Worker').toString();
                  final category = (data['jobType'] ?? 'Unknown').toString();
                  final profilePhotoUrl = (data['profilePhotoUrl'] ?? '')
                      .toString();
                  final address = (data['address'] ?? '').toString();
                  final rating = ((data['ratingAverage'] ?? 0) as num)
                      .toDouble();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFEAECEF)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFE6EAF7),
                          backgroundImage: profilePhotoUrl.isNotEmpty
                              ? NetworkImage(profilePhotoUrl)
                              : null,
                          child: profilePhotoUrl.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  color: Color(0xFF5B6475),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF222222),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF8A8A8A),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF8A8A8A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUser.uid)
                                .collection('favorites')
                                .doc(workerId)
                                .delete();
                          },
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
