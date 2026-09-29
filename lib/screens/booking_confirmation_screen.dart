import 'package:flutter/material.dart';

/// Phase-1 placeholder. Phase 2 replaces the body (keep the class name and constructor).
class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key, required this.pnr});

  final String pnr;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking confirmed'),
      ),
      body: const Center(child: Text('Coming in phase 2')),
    );
  }
}
