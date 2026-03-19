import 'package:flutter/material.dart';
import '../models/comment_model.dart';

class CommentTile extends StatelessWidget {
  final CommentModel comment;
  final String currentUserId;
  final String postOwnerId; 
  final List<CommentModel> replies;
  final Function(CommentModel) onReplyClicked;
  final Function(String) onDeleteClicked;

  const CommentTile({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.postOwnerId, 
    required this.replies,
    required this.onReplyClicked,
    required this.onDeleteClicked,
  });

  @override
  Widget build(BuildContext context) {
    bool isMyComment = comment.userId == currentUserId;
    bool isPostOwner = currentUserId == postOwnerId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16, 
                backgroundColor: const Color(0xFF4A90E2), 
                child: Text(comment.username[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14))
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(comment.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 8),
                        Text(comment.date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        const Spacer(),
                        
                        if (isMyComment)
                          GestureDetector(
                            onTap: () => onDeleteClicked(comment.id),
                            child: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                          )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(comment.text, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    
                    
                    if (isPostOwner)
                      GestureDetector(
                        onTap: () => onReplyClicked(comment),
                        child: const Text('Reply', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              )
            ],
          ),
          
          
          if (replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40.0, top: 8.0),
              child: Column(
                children: replies.map((reply) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(radius: 12, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 14, color: Colors.white)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(reply.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(width: 4),
                                  
                                  const Icon(Icons.verified, size: 12, color: Color(0xFF4A90E2)),
                                  const Spacer(),
                                  if (reply.userId == currentUserId)
                                    GestureDetector(
                                      onTap: () => onDeleteClicked(reply.id),
                                      child: const Icon(Icons.delete_outline, size: 14, color: Colors.red),
                                    )
                                ],
                              ),
                              Text(reply.text, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
            )
        ],
      ),
    );
  }
}