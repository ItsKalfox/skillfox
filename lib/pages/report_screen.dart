import 'package:flutter/material.dart';
import '../services/post_controller.dart';

class ReportScreen extends StatefulWidget {
  final String postId;
  final String currentUserId;

  const ReportScreen({super.key, required this.postId, required this.currentUserId});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int? selectedRadio;
  final PostController _controller = PostController();
  final List<String> reportOptions = [
    'Inappropriate Content', 
    'Misleading Service Information', 
    'Scam or Fraud', 
    'Harassment or Hate Speech', 
    'Spam / Irrelevant Content', 
    'Copyright Violation'
  ];

  Future<void> _submitReport() async {
    if (selectedRadio == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a reason.')));
      return;
    }
    
    // Call the controller to save the report
    await _controller.reportPost(widget.postId, widget.currentUserId, reportOptions[selectedRadio!]);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post reported successfully.'), backgroundColor: Colors.green)
      );
      Navigator.pop(context); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Report Post', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0), 
            child: Text('Why are you reporting this post?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
          ),
          Expanded(
            child: ListView.builder(
              itemCount: reportOptions.length,
              itemBuilder: (context, index) {
                
                return ListTile(
                  title: Text(reportOptions[index], style: const TextStyle(fontSize: 15)),
                  trailing: Icon(
                    selectedRadio == index ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: selectedRadio == index ? const Color(0xFF4A90E2) : Colors.grey,
                  ),
                  onTap: () => setState(() => selectedRadio = index),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: _submitReport,
                child: const Text('Submit Report', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }
}