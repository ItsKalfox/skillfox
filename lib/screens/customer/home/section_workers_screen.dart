import 'package:flutter/material.dart';
import '../../../models/worker.dart';
import 'package:skillfox/screens/category_a/inspection_form_screen.dart';

class SectionWorkersScreen extends StatelessWidget {
  final String title;
  final List<Worker> workers;

  const SectionWorkersScreen({
    super.key,
    required this.title,
    required this.workers,
  });

  String _travelFeeLabel(Worker worker) {
    if (worker.hasOffer && worker.offerType == 'free_travel') {
      return 'Travel fee LKR 0';
    }
    return 'Travel fee LKR ${worker.travelFee.toStringAsFixed(0)}';
  }

  bool _isCategoryAWorker(Worker worker) {
    const categoryA = {'plumber', 'electrician', 'mechanic'};
    return categoryA.contains(worker.category.toLowerCase());
  }

  void _openWorkerRequestScreen(BuildContext context, Worker worker) {
    if (!_isCategoryAWorker(worker)) return;

    // FIX: InspectionFormScreen only takes worker: — no requestId here.
    // The requestId is created INSIDE InspectionFormScreen after form submit.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InspectionFormScreen(worker: worker),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: workers.isEmpty
          ? const Center(
              child: Text(
                'No workers available',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: workers.length,
              itemBuilder: (context, index) {
                final worker = workers[index];
                final offerBadge = worker.offerType == 'free_travel'
                    ? 'FREE TRAVEL'
                    : 'OFFER';

                return GestureDetector(
                  onTap: () => _openWorkerRequestScreen(context, worker),
                  child: Container(
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
                          backgroundImage: worker.profilePhotoUrl.isNotEmpty
                              ? NetworkImage(worker.profilePhotoUrl)
                              : null,
                          child: worker.profilePhotoUrl.isEmpty
                              ? const Icon(Icons.person,
                                  color: Color(0xFF5B6475))
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(worker.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF222222),
                                  )),
                              const SizedBox(height: 3),
                              Text(worker.category,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF8A8A8A),
                                    fontWeight: FontWeight.w500,
                                  )),
                              const SizedBox(height: 5),
                              Text(
                                '${_travelFeeLabel(worker)} • ${worker.travelMinutes} min',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF8A8A8A),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(children: [
                                const Icon(Icons.star_rounded,
                                    color: Colors.amber, size: 15),
                                const SizedBox(width: 4),
                                Text(worker.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    )),
                                const SizedBox(width: 8),
                                Text('${worker.distanceKm.toStringAsFixed(1)} km',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF8A8A8A),
                                    )),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(children: [
                          if (worker.hasOffer)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE5E5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(offerBadge,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.redAccent,
                                  )),
                            ),
                          Icon(
                            worker.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border_rounded,
                            color: worker.isFavorite
                                ? Colors.redAccent
                                : Colors.black45,
                          ),
                        ]),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
