import 'package:flutter/material.dart';
import 'package:skillfox/models/post_model.dart';
import 'package:skillfox/services/community/post_controller.dart';
import 'package:skillfox/widgets/community/post_card.dart';
import 'package:skillfox/screens/community/upload_post_screen.dart';
import 'package:skillfox/screens/community/worker_category_screen.dart';

class CommunityFeedScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUsername;
  final bool isWorker;
  final String? userCategory;

  const CommunityFeedScreen({
    super.key,
    required this.currentUserId,
    required this.currentUsername,
    required this.isWorker,
    this.userCategory,
  });

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final PostController _postController = PostController();

  Stream<List<PostModel>>? _activeStream;
  late String _activeTab;
  String? _exploreCategory;
  late List<String> _tabs;

  @override
  void initState() {
    super.initState();
    if (widget.isWorker) {
      _activeTab = 'Explore';
      _tabs = ['Explore', 'My Category', 'My Uploads', 'Saved'];
    } else {
      _activeTab = 'Explore';
      _tabs = ['Explore', 'For You', 'Saved'];
    }
    _activeStream = _getActiveStream();
  }

  Stream<List<PostModel>> _getActiveStream() {
    switch (_activeTab) {
      case 'For You':
        return _postController.getForYouPostsStream();
      case 'Explore':
        return _postController.getPostsStream(
            categoryFilter: _exploreCategory);
      case 'My Category':
        return _postController
            .getSuggestedCategoryPostsStream(widget.userCategory ?? 'General');
      case 'My Uploads':
        return _postController.getMyUploadsStream(widget.currentUserId);
      case 'Saved':
        return _postController.getSavedPostsStream(widget.currentUserId);
      default:
        return _postController.getPostsStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Community',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 24,
                letterSpacing: 0.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5AB2FF), Color(0xFF4365FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(65.0),
          child: Container(
            color: Colors.transparent,
            width: double.infinity,
            padding: const EdgeInsets.only(
                bottom: 16, top: 4, left: 12, right: 12),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _tabs.map((tab) {
                  bool isSelected = _activeTab == tab;
                  String tabText = tab;
                  if (tab == 'Explore' &&
                      isSelected &&
                      _exploreCategory != null) {
                    tabText = 'Explore: $_exploreCategory';
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: GestureDetector(
                      onTap: () async {
                        if (tab == 'Explore') {
                          setState(() {
                            _activeTab = 'Explore';
                            _activeStream = _getActiveStream();
                          });
                          final selectedCategory = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const WorkerCategoryScreen()),
                          );
                          if (selectedCategory != null) {
                            setState(() {
                              _exploreCategory = selectedCategory as String;
                              _activeStream = _getActiveStream();
                            });
                          }
                        } else {
                          setState(() {
                            _activeTab = tab;
                            _activeStream = _getActiveStream();
                          });
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : const Color(0x1AFFFFFF),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 1.5),
                          boxShadow: isSelected
                              ? const [
                                  BoxShadow(
                                      color: Color(0x26000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 3))
                                ]
                              : [],
                        ),
                        child: Text(
                          tabText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? const Color(0xFF4365FF)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: _activeStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF4A90E2)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.dynamic_feed_rounded,
                      size: 80, color: Color(0xFFCFD8DC)),
                  const SizedBox(height: 16),
                  Text(
                    _exploreCategory != null
                        ? 'No posts for $_exploreCategory'
                        : 'No posts in $_activeTab yet',
                    style: const TextStyle(
                        color: Color(0xFF78909C),
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Check back later for new content.',
                      style: TextStyle(color: Color(0xFF90A4AE))),
                ],
              ),
            );
          }

          final posts = snapshot.data!;
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding:
                const EdgeInsets.only(bottom: 100, top: 12),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return PostCard(
                post: posts[index],
                currentUserId: widget.currentUserId,
                currentUsername: widget.currentUsername,
              );
            },
          );
        },
      ),
      floatingActionButton: widget.isWorker
          ? FloatingActionButton(
              elevation: 4,
              backgroundColor: const Color(0xFF4365FF),
              child: const Icon(Icons.add_a_photo_rounded,
                  color: Colors.white, size: 26),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => UploadPostScreen(
                            currentUserId: widget.currentUserId,
                            username: widget.currentUsername,
                            category:
                                widget.userCategory ?? 'General')));
              },
            )
          : null,
    );
  }
}
