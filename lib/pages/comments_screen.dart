import 'package:flutter/material.dart';
import '../services/comment_controller.dart';
import '../models/comment_model.dart';
import '../widgets/comment_tile.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  final String currentUserId; 
  final String postOwnerId; 
  final String currentUsername; 
  
  const CommentsScreen({
    super.key, 
    required this.postId, 
    required this.currentUserId,
    required this.postOwnerId,
    required this.currentUsername, 
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final CommentController _controller = CommentController();
  final TextEditingController _textController = TextEditingController();
  bool _isPosting = false;
  CommentModel? _replyingTo;

  Future<void> _postComment() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPosting = true);
    FocusScope.of(context).unfocus();

    try {
      
      await _controller.addComment(
        widget.postId, 
        text, 
        widget.currentUserId, 
        widget.currentUsername, 
        parentId: _replyingTo?.id 
      );
      
      _textController.clear();
      setState(() => _replyingTo = null); 
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      backgroundColor: Theme.of(context).colorScheme.surface, 
      appBar: AppBar(
        
        title: const Text('Comments'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: _controller.getCommentsStream(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF4A90E2)));
                }
                
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('No comments yet.', style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }

                final allComments = snapshot.data!;
                final mainComments = allComments.where((c) => c.parentId == null).toList();

                return ListView.builder(
                  reverse: true, 
                  itemCount: mainComments.length,
                  itemBuilder: (context, index) {
                    final comment = mainComments[index];
                    final replies = allComments.where((c) => c.parentId == comment.id).toList();

                    
                    return CommentTile(
                      comment: comment,
                      currentUserId: widget.currentUserId,
                      postOwnerId: widget.postOwnerId,
                      replies: replies,
                      onReplyClicked: (selectedComment) {
                        setState(() => _replyingTo = selectedComment);
                      },
                      onDeleteClicked: (commentId) {
                        _controller.deleteComment(widget.postId, commentId);
                      },
                    );
                  },
                );
              },
            ),
          ),
          
          // REPLY BANNER
          if (_replyingTo != null)
            Container(
              color: const Color(0xFFE8F1FA), 
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 18, color: Color(0xFF4A90E2)),
                  const SizedBox(width: 8),
                  Text('Replying to ${_replyingTo!.username}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A90E2))),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _replyingTo = null),
                    child: const Icon(Icons.close, size: 20, color: Colors.black54),
                  )
                ],
              ),
            ),

          // BOTTOM INPUT BAR
          Container(
            padding: EdgeInsets.only(
              left: 16, 
              right: 16, 
              top: 12, 
              bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.shade200, offset: const Offset(0, -3), blurRadius: 10)]
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: _replyingTo != null ? 'Write a reply...' : 'Add a comment...',
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _isPosting 
                    ? const Padding(padding: EdgeInsets.all(12.0), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4A90E2))))
                    : GestureDetector(
                        onTap: _postComment,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: Color(0xFF4A90E2), shape: BoxShape.circle),
                          child: const Icon(Icons.send, color: Colors.white, size: 20)
                        ),
                      )
              ],
            ),
          )
        ],
      ),
    );
  }
}