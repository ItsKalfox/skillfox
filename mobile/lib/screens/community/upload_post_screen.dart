import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:skillfox/services/community/post_controller.dart';
import 'package:skillfox/services/community/storage_service.dart';

class UploadPostScreen extends StatefulWidget {
  final String currentUserId;
  final String username;
  final String category;

  const UploadPostScreen({
    super.key,
    required this.currentUserId,
    required this.username,
    required this.category,
  });

  @override
  State<UploadPostScreen> createState() => _UploadPostScreenState();
}

class _UploadPostScreenState extends State<UploadPostScreen> {
  final PostController _postController = PostController();
  final CommunityStorageService _storageService = CommunityStorageService();
  final TextEditingController _descriptionController =
      TextEditingController();

  File? _mediaFile;
  File? _thumbnailFile;
  String? _mediaType;

  bool _isLoading = false;
  String? _selectedCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _postController.getCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
        if (!_categories.contains(_selectedCategory)) {
          _selectedCategory =
              _categories.isNotEmpty ? _categories.first : 'General';
        }
      });
    }
  }

  void _showMediaPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Select Media Type',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo, color: Color(0xFF4A90E2)),
              title: const Text('Upload Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(ImageSource.gallery, isVideo: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam,
                  color: Colors.redAccent),
              title:
                  const Text('Upload Video (Max 1 Min, 30MB)'),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(ImageSource.gallery, isVideo: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source,
      {required bool isVideo}) async {
    final picker = ImagePicker();

    try {
      if (isVideo) {
        final pickedVideo = await picker.pickVideo(source: source);
        if (pickedVideo != null) {
          File videoFile = File(pickedVideo.path);

          int sizeInBytes = videoFile.lengthSync();
          double sizeInMb = sizeInBytes / (1024 * 1024);
          if (sizeInMb > 30.0) {
            _showError(
                'Video is too large! Maximum size is 30MB. Yours is ${sizeInMb.toStringAsFixed(1)}MB.');
            return;
          }

          MediaInfo info =
              await VideoCompress.getMediaInfo(videoFile.path);
          if (info.duration != null && info.duration! > 60000) {
            _showError(
                'Video is too long! Maximum duration is 1 minute.');
            return;
          }

          File thumbnail = await VideoCompress.getFileThumbnail(
              videoFile.path);

          setState(() {
            _mediaFile = videoFile;
            _thumbnailFile = thumbnail;
            _mediaType = 'video';
          });
        }
      } else {
        final pickedImage = await picker.pickImage(source: source);
        if (pickedImage != null) {
          setState(() {
            _mediaFile = File(pickedImage.path);
            _thumbnailFile = null;
            _mediaType = 'image';
          });
        }
      }
    } catch (e) {
      _showError('Error picking media: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  Future<void> _uploadPost() async {
    if (_mediaFile == null || _mediaType == null) {
      _showError('Please select an image or video.');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showError('Please write a description.');
      return;
    }

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      File finalFileToUpload = _mediaFile!;

      if (_mediaType == 'image') {
        final tempDir = await getTemporaryDirectory();
        final targetPath =
            '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

        var compressedImage =
            await FlutterImageCompress.compressAndGetFile(
          _mediaFile!.absolute.path,
          targetPath,
          quality: 70,
        );
        if (compressedImage != null) {
          finalFileToUpload = File(compressedImage.path);
        }
      } else if (_mediaType == 'video') {
        MediaInfo? mediaInfo = await VideoCompress.compressVideo(
          _mediaFile!.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
        );
        if (mediaInfo != null && mediaInfo.file != null) {
          finalFileToUpload = mediaInfo.file!;
        }
      }

      String folderName =
          _mediaType == 'video' ? 'posts/videos' : 'posts/images';
      String uploadedMediaUrl =
          await _storageService.uploadMedia(finalFileToUpload, folderName);

      await _postController.createPost(
        workerId: widget.currentUserId,
        username: widget.username,
        category: _selectedCategory!,
        description: _descriptionController.text.trim(),
        mediaUrl: uploadedMediaUrl,
        mediaType: _mediaType!,
      );

      await VideoCompress.deleteAllCache();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Post published successfully!',
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Error publishing post: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    VideoCompress.cancelCompression();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Post',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _showMediaPickerOptions,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: Colors.grey.shade300,
                      style: BorderStyle.solid),
                ),
                child: _mediaFile != null
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(15),
                            child: Image.file(
                                _mediaType == 'video'
                                    ? _thumbnailFile!
                                    : _mediaFile!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity),
                          ),
                          if (_mediaType == 'video')
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.play_arrow,
                                  color: Colors.white, size: 40),
                            )
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate,
                              size: 50,
                              color: Color(0xFF4A90E2)),
                          SizedBox(height: 12),
                          Text('Tap to select Photo or Video',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 16)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Job Category',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(15),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  hint: const Text('Select a category'),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                        value: category, child: Text(category));
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() => _selectedCategory = newValue);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Description',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write a description...',
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _isLoading ? null : _uploadPost,
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2)),
                          SizedBox(width: 12),
                          Text('Compressing & Uploading...',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      )
                    : const Text('Publish Post',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
