import 'package:flutter/material.dart';

/// Phase-1 placeholder. Phase 2 replaces the body (keep the class name and constructor).
/// Pops with the chosen `DateTime` (`Navigator.pop(context, date)`).
class FareCalendarScreen extends StatelessWidget {
  const FareCalendarScreen({super.key, required this.from, required this.to, required this.initialDate});

  final String from;
  final String to;
  final DateTime initialDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fare calendar'),
      ),
      body: const Center(child: Text('Coming in phase 2')),
    );
  }
}
