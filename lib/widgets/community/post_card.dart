import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:skillfox/models/post_model.dart';
import 'package:skillfox/services/community/post_controller.dart';
import 'package:skillfox/screens/community/comments_screen.dart';
import 'package:skillfox/screens/community/report_screen.dart';
import 'package:skillfox/screens/community/image_viewer_screen.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final String currentUserId;
  final String currentUsername;

  final PostController _controller = PostController();

  PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.currentUsername,
  });

  String _getTimeAgo(DateTime date) {
    final Duration diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  void _showEditDialog(BuildContext context) {
    final TextEditingController editController =
        TextEditingController(text: post.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Description',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: editController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Update your description...',
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () {
              if (editController.text.trim().isNotEmpty) {
                _controller.updatePostDescription(
                    post.id, editController.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Description updated!'),
                    backgroundColor: Colors.green));
              }
            },
            child: const Text('Save Changes',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isLiked = post.likedBy.contains(currentUserId);
    bool isSaved = post.savedBy.contains(currentUserId);
    bool hasReported = post.reportedBy.contains(currentUserId);
    bool isMyPost = post.workerId == currentUserId;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER
            Padding(
              padding:
                  const EdgeInsets.only(left: 16, right: 8, top: 16, bottom: 12),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0x334A90E2), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFF4A90E2),
                      child: Text(
                          post.username.isNotEmpty
                              ? post.username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.username,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF2D3A54))),
                        const SizedBox(height: 2),
                        Text(
                            '${post.category} • ${_getTimeAgo(post.createdAt)}',
                            style: const TextStyle(
                                color: Color(0xFF9E9E9E),
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon:
                        const Icon(Icons.more_horiz, color: Color(0xFF757575)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditDialog(context);
                      } else if (value == 'delete') {
                        _controller.deletePost(post.id);
                      } else if (value == 'report') {
                        if (hasReported) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'You have already reported this post.')));
                        } else {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ReportScreen(
                                      postId: post.id,
                                      currentUserId: currentUserId)));
                        }
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      if (isMyPost) {
                        return [
                          const PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(children: [
                                Icon(Icons.edit_outlined, size: 20),
                                SizedBox(width: 10),
                                Text('Edit')
                              ])),
                          const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(children: [
                                Icon(Icons.delete_outline,
                                    color: Colors.red, size: 20),
                                SizedBox(width: 10),
                                Text('Delete',
                                    style: TextStyle(color: Colors.red))
                              ])),
                        ];
                      } else {
                        return [
                          const PopupMenuItem<String>(
                              value: 'report',
                              child: Row(children: [
                                Icon(Icons.flag_outlined,
                                    color: Colors.red, size: 20),
                                SizedBox(width: 10),
                                Text('Report',
                                    style: TextStyle(color: Colors.red))
                              ])),
                        ];
                      }
                    },
                  ),
                ],
              ),
            ),

            // 2. EDGE-TO-EDGE MEDIA
            if (post.mediaUrl.isNotEmpty)
              post.mediaType == 'video'
                  ? FeedVideoPlayer(videoUrl: post.mediaUrl)
                  : GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ImageViewerScreen(
                                  imageUrl: post.mediaUrl,
                                  heroTag: post.id))),
                      child: Hero(
                        tag: post.id,
                        child: CachedNetworkImage(
                            imageUrl: post.mediaUrl,
                            height: 260,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const SizedBox(
                                height: 260,
                                child: Center(
                                    child: CircularProgressIndicator(
                                        color: Color(0xFF4A90E2)))),
                            errorWidget: (context, url, error) =>
                                const SizedBox(
                                    height: 260,
                                    child: Center(
                                        child: Icon(Icons.broken_image,
                                            size: 50,
                                            color: Color(0xFFE0E0E0))))),
                      ),
                    ),

            // 3. ACTION BAR
            Padding(
              padding: const EdgeInsets.only(
                  left: 6.0, right: 12.0, top: 8.0, bottom: 4.0),
              child: Row(
                children: [
                  IconButton(
                      icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.redAccent : Colors.black87,
                          size: 26),
                      onPressed: () => _controller.toggleLike(
                          post.id, currentUserId, post.likedBy)),
                  Text('${post.likedBy.length}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  IconButton(
                      icon: const Icon(Icons.chat_bubble_outline,
                          size: 24, color: Colors.black87),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CommentsScreen(
                                  postId: post.id,
                                  currentUserId: currentUserId,
                                  postOwnerId: post.workerId,
                                  currentUsername: currentUsername)))),
                  Text('${post.commentCount}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                      icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          size: 26,
                          color: isSaved
                              ? const Color(0xFF4A90E2)
                              : Colors.black87),
                      onPressed: () => _controller.toggleSave(
                          post.id, currentUserId, post.savedBy)),
                ],
              ),
            ),

            // 4. DESCRIPTION
            Padding(
              padding: const EdgeInsets.only(
                  left: 18.0, right: 18.0, bottom: 24.0),
              child: Text(
                post.description,
                style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF2D3A54),
                    height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// CUSTOM VIDEO PLAYER WIDGET
// ==========================================
class FeedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const FeedVideoPlayer({super.key, required this.videoUrl});
  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  late VideoPlayerController _videoController;
  bool _isPlaying = false;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
          ..initialize().then((_) {
            if (mounted) setState(() {});
          }).catchError((error) {
            if (mounted) setState(() => _isError = true);
          });
    _videoController.setLooping(true);
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return const SizedBox(
          height: 260,
          child: Center(
              child: Icon(Icons.error_outline, color: Colors.red, size: 50)));
    }
    return _videoController.value.isInitialized
        ? GestureDetector(
            onTap: () {
              setState(() {
                _isPlaying
                    ? _videoController.pause()
                    : _videoController.play();
                _isPlaying = !_isPlaying;
              });
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                    aspectRatio: _videoController.value.aspectRatio,
                    child: VideoPlayer(_videoController)),
                if (!_isPlaying)
                  Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                          color: Color(0x99000000), shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow,
                          color: Colors.white, size: 40)),
              ],
            ),
          )
        : const SizedBox(
            height: 260,
            child: Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF4A90E2)
                )
            )
          );
  }
}
