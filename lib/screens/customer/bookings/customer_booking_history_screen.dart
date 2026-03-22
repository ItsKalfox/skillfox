import 'package:flutter/material.dart';

class CustomerBookingHistoryScreen extends StatelessWidget {
  const CustomerBookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Booking History'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F8FC),
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Booking history will appear here.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}
