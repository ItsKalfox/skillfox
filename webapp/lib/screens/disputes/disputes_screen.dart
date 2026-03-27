import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; 
import 'package:video_player/video_player.dart'; 
import '../../core/theme/app_theme.dart';

class DisputesScreen extends StatefulWidget {
  const DisputesScreen({super.key});

  @override
  State<DisputesScreen> createState() => _DisputesScreenState();
}

class _DisputesScreenState extends State<DisputesScreen> {
  String _selectedStatus = 'All Status';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Disputes',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
                SizedBox(height: 4),
                Text('Manage and investigate community reports',
                    style: TextStyle(
                        fontSize: 14, color: AppTheme.textSecondary)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStatus,
                  items: const ['All Status', 'open', 'in_progress', 'resolved']
                      .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary))))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedStatus = v!),
                  icon: const Icon(Icons.keyboard_arrow_down,
                      size: 18, color: AppTheme.textSecondary),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Stats
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('reports').snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            final total = docs.length;
            final open = docs.where((d) => (d.data() as Map)['status'] == 'open' || (d.data() as Map)['status'] == null).length;
            final inProgress = docs.where((d) => (d.data() as Map)['status'] == 'in_progress').length;
            final resolved = docs.where((d) => (d.data() as Map)['status'] == 'resolved').length;

            return Row(
              children: [
                Expanded(child: _StatBox(label: 'Total Disputes', value: '$total', color: AppTheme.textPrimary)),
                const SizedBox(width: 16),
                Expanded(child: _StatBox(label: 'Open', value: '$open', color: AppTheme.danger)),
                const SizedBox(width: 16),
                Expanded(child: _StatBox(label: 'In Progress', value: '$inProgress', color: AppTheme.warning)),
                const SizedBox(width: 16),
                Expanded(child: _StatBox(label: 'Resolved', value: '$resolved', color: AppTheme.success)),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Disputes List
        StreamBuilder<QuerySnapshot>(
          stream: _buildQuery(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Center(child: Text('No disputes found')),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                return _DisputeCard(docId: doc.id, data: data);
              },
            );
          },
        ),
      ],
    );
  }

  Stream<QuerySnapshot> _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('reports');
    if (_selectedStatus != 'All Status') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }
    return query.orderBy('timestamp', descending: true).snapshots();
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _DisputeCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _DisputeCard({required this.docId, required this.data});

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final dt = (timestamp as Timestamp).toDate();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  void _updateStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('reports').doc(docId).update({'status': newStatus});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dispute marked as $newStatus'), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update dispute'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  void _investigatePost(BuildContext context, String postId) {
    if (postId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No Post ID attached to this report.'), backgroundColor: AppTheme.danger)
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Investigate Post', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 500,
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('posts').doc(postId).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: Text('This post has already been deleted or removed.', style: TextStyle(color: AppTheme.danger))),
                );
              }

              final postData = snapshot.data!.data() as Map<String, dynamic>;
              final isVideo = postData['mediaType'] == 'video';

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Author: ${postData['username'] ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                          child: Text(postData['category'] ?? 'General', style: const TextStyle(color: AppTheme.primary, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Description / Content:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(postData['description'] ?? 'No text provided.', style: const TextStyle(fontSize: 15, height: 1.5)),
                    
                    if (postData['mediaUrl'] != null && postData['mediaUrl'].toString().trim().isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 24),
                        height: 350, 
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black, // Dark background looks best for media
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          // FIX: Replaced the static placeholder with the real Video Player
                          child: isVideo 
                              ? AdminVideoPlayer(videoUrl: postData['mediaUrl'])
                              : Image.network(
                                  postData['mediaUrl'], 
                                  fit: BoxFit.contain, 
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        color: AppTheme.primary,
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.broken_image, color: Colors.red, size: 50),
                                          const SizedBox(height: 8),
                                          const Text('Network / CORS Error', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text('URL: ${postData['mediaUrl'].toString().substring(0, min(30, postData['mediaUrl'].toString().length))}...', style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center,)
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textHint)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white, elevation: 0),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('reports').doc(docId).update({'status': 'resolved'});
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Dismiss Report (Keep Post)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white, elevation: 0),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
              await FirebaseFirestore.instance.collection('reports').doc(docId).update({'status': 'resolved'});
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete Post & Resolve'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status']?.toString() ?? 'open';
    final isResolved = status == 'resolved';
    final String postId = data['postId'] ?? ''; 

    Color statusColor = status == 'resolved' ? AppTheme.success : (status == 'in_progress' ? AppTheme.warning : AppTheme.danger);
    Color statusBg = status == 'resolved' ? const Color(0xFFECFDF5) : (status == 'in_progress' ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2));
    String statusLabel = status == 'resolved' ? 'Resolved' : (status == 'in_progress' ? 'In Progress' : 'Open');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Report #${docId.substring(0, 6).toUpperCase()}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                    child: Text(statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: statusColor)),
                  ),
                ],
              ),
              Text(_formatDate(data['timestamp']), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          
          Text(data['reason'] ?? data['description'] ?? 'No reason provided for this report.',
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              const Text('Reported by User ID: ', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              Text(data['userId']?.toString().substring(0, 8) ?? 'Unknown',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),

          if (!isResolved)
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: postId.isNotEmpty ? () => _investigatePost(context, postId) : null,
                  icon: const Icon(Icons.manage_search, size: 18),
                  label: const Text('Investigate Post', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => _updateStatus(context, 'in_progress'),
                  icon: const Icon(Icons.pending_outlined, size: 16),
                  label: const Text('Mark In Progress', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.warning,
                    side: const BorderSide(color: AppTheme.warning),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16, color: AppTheme.success),
                  SizedBox(width: 6),
                  Text('Dispute Resolved', style: TextStyle(fontSize: 13, color: AppTheme.success, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ==============================================================
// NEW FEATURE: Custom Admin Video Player for the Web Dashboard
// ==============================================================
class AdminVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const AdminVideoPlayer({super.key, required this.videoUrl});

  @override
  State<AdminVideoPlayer> createState() => _AdminVideoPlayerState();
}

class _AdminVideoPlayerState extends State<AdminVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _isError = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 8),
            Text('Failed to load video (Network/CORS)', style: TextStyle(color: Colors.red)),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _controller.value.isPlaying ? _controller.pause() : _controller.play();
            });
          },
          child: Container(
            color: Colors.transparent, // Captures taps across the whole video
            child: Center(
              child: AnimatedOpacity(
                opacity: _controller.value.isPlaying ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}