import 'package:flutter/material.dart';

/// Phase-1 placeholder. Phase 2 replaces the body (keep the class name and constructor).
class TripSummaryScreen extends StatelessWidget {
  /// Draft mode (booking flow step 6).
  const TripSummaryScreen({super.key}) : pnr = null;

  /// Read-only mode for an existing booking (from My Trips), with Cancel.
  const TripSummaryScreen.forBooking({super.key, required String this.pnr});

  /// null = draft mode.
  final String? pnr;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pnr == null ? 'Trip summary' : 'Trip $pnr'),
      ),
      body: const Center(child: Text('Coming in phase 2')),
    );
  }
}
