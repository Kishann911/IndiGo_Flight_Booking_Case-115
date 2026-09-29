import 'package:flutter/material.dart';

import '../models/flight.dart';

/// Phase-1 placeholder. Phase 2 replaces the body (keep the class name and constructor).
class FlightDetailScreen extends StatelessWidget {
  const FlightDetailScreen({super.key, required this.segIndex, required this.flight});

  final int segIndex;
  final Flight flight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flight details'),
      ),
      body: const Center(child: Text('Coming in phase 2')),
    );
  }
}
