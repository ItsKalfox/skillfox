import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class _C {
  static const gradA   = Color(0xFF469FEF);
  static const gradB   = Color(0xFF6C56F0);
  static const accent  = Color(0xFF6C56F0);
  static const bg      = Color(0xFFF4F6FA);
  static const cardBdr = Color(0xFFE2E6F0);
  static const txt1    = Color(0xFF111111);
  static const txt2    = Color(0xFF888888);
  static const muted   = Color(0xFFA0A4B0);
  static const green   = Color(0xFF16A34A);
  static const greenDk = Color(0xFF1E8449);
  static const red     = Color(0xFFEF4444);
  static const star    = Color(0xFFF59E0B);
}

class ReviewScreen extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> requestData;
  final bool isWorker;

  const ReviewScreen({
    super.key,
    required this.requestId,
    required this.requestData,
    required this.isWorker,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int    _rating     = 0;
  final  _reviewCtrl = TextEditingController();
  bool   _loading    = false;

  @override
  void dispose() { _reviewCtrl.dispose(); super.dispose(); }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a rating.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      final workerId     = widget.requestData['workerId']     as String? ?? '';
      final customerId   = widget.requestData['customerId']   as String? ?? '';
      final workerName   = widget.requestData['workerName']   as String? ?? '';
      final customerName = widget.requestData['customerName'] as String? ?? '';
      final category     = widget.requestData['category']     as String? ?? '';
      final reviewText   = _reviewCtrl.text.trim();

      // ── 1. Update the request document ──────────────────────────────────
      final reviewField = widget.isWorker ? 'workerReview'  : 'customerReview';
      final ratingField = widget.isWorker ? 'workerRating'  : 'customerRating';
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
        reviewField:           reviewText,
        ratingField:           _rating,
        '${reviewField}At':    FieldValue.serverTimestamp(),
      });

      // ── 2. Write to reviews collection ───────────────────────────────────
      // Only customer reviews are written to the reviews collection
      // (so worker profile can show them)
      if (!widget.isWorker && workerId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('reviews').add({
          'requestId':    widget.requestId,
          'workerId':     workerId,
          'customerId':   customerId,
          'workerName':   workerName,
          'customerName': customerName,
          'category':     category,
          'rating':       _rating,
          'reviewText':   reviewText,
          'reviewBy':     'customer',
          'createdAt':    FieldValue.serverTimestamp(),
        });

        // ── 3. Update worker's average rating in workers collection ─────────
        final reviewsSnap = await FirebaseFirestore.instance
            .collection('reviews')
            .where('workerId', isEqualTo: workerId)
            .get();

        if (reviewsSnap.docs.isNotEmpty) {
          final totalRatings = reviewsSnap.docs
              .map((d) => (d.data()['rating'] as num?)?.toDouble() ?? 0)
              .fold(0.0, (a, b) => a + b);
          final avgRating = totalRatings / reviewsSnap.docs.length;

          await FirebaseFirestore.instance
              .collection('workers')
              .doc(workerId)
              .update({
            'averageRating': double.parse(avgRating.toStringAsFixed(1)),
            'totalReviews':  reviewsSnap.docs.length,
          });
        }
      }

      if (mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: _C.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetName = widget.isWorker
        ? (widget.requestData['customerName'] as String? ?? 'Customer')
        : (widget.requestData['workerName']   as String? ?? 'Worker');

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(children: [

        // ── Gradient Header ──────────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_C.gradA, _C.gradB])),
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 4,
              bottom: 16, left: 16, right: 16),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(width: 32, height: 32,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 14, color: Colors.white)),
            ),
            const SizedBox(width: 12),
            const Text('Leave a Review',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const SizedBox(height: 20),

            // Completion icon
            Container(width: 80, height: 80,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [_C.gradA, _C.gradB])),
                child: const Icon(Icons.verified_rounded, size: 40, color: Colors.white)),

            const SizedBox(height: 16),
            const Text('Job Completed!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _C.txt1)),
            const SizedBox(height: 6),
            Text('How was your experience with $targetName?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: _C.txt2, height: 1.5)),

            const SizedBox(height: 24),

            // Star rating card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _C.cardBdr, width: 0.5)),
              child: Column(children: [
                const Text('Tap to rate',
                    style: TextStyle(fontSize: 12, color: _C.muted)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => GestureDetector(
                    onTap: () => setState(() => _rating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 40,
                        color: i < _rating ? _C.star : Colors.grey.shade300,
                      ),
                    ),
                  )),
                ),
                const SizedBox(height: 8),
                if (_rating > 0)
                  Text(_ratingLabel,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _ratingColor)),
              ]),
            ),

            const SizedBox(height: 16),

            // Review text card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _C.cardBdr, width: 0.5)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('WRITE A REVIEW (Optional)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                        color: _C.muted, letterSpacing: 0.5)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.cardBdr)),
                  child: TextField(
                    controller: _reviewCtrl, maxLines: 4,
                    style: const TextStyle(fontSize: 13, color: _C.txt1),
                    decoration: const InputDecoration(
                      hintText: 'Share your experience...',
                      hintStyle: TextStyle(fontSize: 13, color: _C.muted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 80),
          ]),
        )),

        // ── Submit button ────────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(
              16, 14, 16, MediaQuery.of(context).padding.bottom + 20),
          child: GestureDetector(
            onTap: _loading ? null : _submitReview,
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_C.gradA, _C.gradB]),
                  borderRadius: BorderRadius.circular(14)),
              child: Center(child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.star_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Submit Review',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    ])),
            ),
          ),
        ),
      ]),
    );
  }

  String get _ratingLabel {
    switch (_rating) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Very Good';
      case 5: return 'Excellent!';
      default: return '';
    }
  }

  Color get _ratingColor {
    if (_rating <= 2) return _C.red;
    if (_rating == 3) return _C.muted;
    return _C.green;
  }
}
