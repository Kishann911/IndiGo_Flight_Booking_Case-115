import 'package:flutter/material.dart';

/// Phase-1 placeholder. Phase 2 replaces the body (keep the class name and constructor).
class FlightResultsScreen extends StatelessWidget {
  const FlightResultsScreen({super.key, required this.segIndex});

  final int segIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flights'),
      ),
      body: const Center(child: Text('Coming in phase 2')),
    );
  }
}
