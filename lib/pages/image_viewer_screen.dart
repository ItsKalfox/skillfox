import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String heroTag; 

  const ImageViewerScreen({
    super.key, 
    required this.imageUrl, 
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true, 
          minScale: 1.0,
          maxScale: 4.0, 
          child: Hero(
            tag: heroTag,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain, 
              width: double.infinity,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Color(0xFF4A90E2))),
              errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
            ),
          ),
        ),
      ),
    );
  }
}