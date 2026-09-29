import 'package:flutter/material.dart';

/// Phase-1 placeholder. Phase 2 replaces the body (keep the class name and constructor).
class BoardingPassScreen extends StatelessWidget {
  const BoardingPassScreen({super.key, required this.pnr, required this.segIndex, required this.passengerId});

  final String pnr;
  final int segIndex;
  final String passengerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boarding pass'),
      ),
      body: const Center(child: Text('Coming in phase 2')),
    );
  }
}
